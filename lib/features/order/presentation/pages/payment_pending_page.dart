import 'dart:async';
import 'package:book_store/core/services/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:book_store/core/routes/app_router.dart';
import 'package:book_store/core/services/book_store_pay_service.dart';
import 'package:book_store/features/order/data/model/order_model.dart';
import 'package:book_store/features/order/presentation/providers/order_provider.dart';

class PaymentPendingPage extends StatefulWidget {
  final OrderModel order;

  const PaymentPendingPage({super.key, required this.order});

  @override
  State<PaymentPendingPage> createState() => _PaymentPendingPageState();
}

class _PaymentPendingPageState extends State<PaymentPendingPage> with WidgetsBindingObserver {
  bool _payLaunched = false;
  bool _isNavigatingToSuccess = false;
  StreamSubscription<PaymentCallbackData>? _callbackSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final expectedReference = 'INV-${widget.order.id}';

    // Auto-launch untuk BookPay
    if (widget.order.paymentMethod == 'bookpay') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _launchBookPay());
    }

    // Mulai polling status pembayaran
    context.read<OrderProvider>().startPaymentPolling(widget.order.id);

    // Cek apakah ada callback yang tertunda
    final pending = BookStorePayService().consumePendingCallback();
    if (pending != null && pending.isSuccess && pending.reference == expectedReference) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onPaymentSuccess());
    }

    // Dengarkan stream callback dari deeplink
    _callbackSub = BookStorePayService().onCallback.listen((data) {
      if (!mounted) return;
      if (data.reference != expectedReference) return;

      if (data.isSuccess) {
        _onPaymentSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembayaran gagal (status: ${data.status})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _callbackSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    context.read<OrderProvider>().stopPaymentPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _payLaunched) {
      context.read<OrderProvider>().checkPaymentStatus(widget.order.id);
      
      // Hit endpoint untuk update status ke backend
      final endpoint = '/orders/${widget.order.id}/pay';
      DioClient.instance.post(endpoint).then((response) {
        debugPrint('Status sukses di-update ke Backend BookStore! URL=${response.requestOptions.baseUrl}${response.requestOptions.path}');
      });
    }
  }

  Future<void> _launchBookPay() async {
    final notes = widget.order.notes.isNotEmpty ? widget.order.notes : null;

    final basedeeplinkUrl = BookStorePayService.buildDeeplinkUrl(
      orderId: widget.order.id,
      amount: widget.order.totalAmount,
      description: notes,
    );

    final String finaldeeplinkUrl = '$basedeeplinkUrl&return_url:book_store://payment-callback';
    final uri = Uri.parse(finaldeeplinkUrl);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _payLaunched = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka BookPay. Pastikan aplikasi e-money sudah terinstall.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatPrice(double price) {
    final str = price.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return 'Rp. ${buffer.toString().split('').reversed.join()}';
  }

  Future<void> _onPaymentSuccess() async {
    if (_isNavigatingToSuccess) return;
    _isNavigatingToSuccess = true;
    debugPrint('_onPaymentSuccess dipanggil — verifikasi backend & navigasi jika sudah paid');

    await context.read<OrderProvider>().checkPaymentStatus(widget.order.id);
    
    if (!mounted) {
      _isNavigatingToSuccess = false;
      return;
    }

    context.read<OrderProvider>().stopPaymentPolling();

    if (!mounted) {
      _isNavigatingToSuccess = false;
      return;
    }

    final orderProv = context.read<OrderProvider>();
    final isOrderPaid = orderProv.paymentCheckStatus == PaymentCheckStatus.paid;

    if (!isOrderPaid) {
      debugPrint('Pembayaran sukses di wallet, tetapi status order backend masih pending. Menunggu polling.');
      _isNavigatingToSuccess = false;
      return;
    }

    final currentOrder = orderProv.lastOrder ?? widget.order;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.orderSuccess,
      (route) => route.settings.name == AppRouter.dashboard,
      arguments: currentOrder,
    );
  }

  void _showCancelConfirmation() {
    // VARIABEL DIPINDAHKAN KE SINI: Ambil data order terbaru untuk dibawa navigasi
    final orderProv = context.read<OrderProvider>();
    final updatedOrder = orderProv.lastOrder ?? widget.order;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pembayaran?'),
        content: const Text(
          'Pesanan tetap tersimpan. Kamu bisa bayar nanti di halaman "Pesanan Saya".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Lanjutkan Bayar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.myOrders, // Biasanya batal bayar diarahkan ke pesanan saya, bukan orderSuccess
                (route) => route.settings.name == AppRouter.dashboard,
                arguments: updatedOrder,
              );
            },
            child: Text(
              'Bayar Nanti',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    final payStatus = orderProv.paymentCheckStatus;
    final order = orderProv.lastOrder ?? widget.order;

    if (payStatus == PaymentCheckStatus.paid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onPaymentSuccess());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showCancelConfirmation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Selesaikan Pembayaran'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showCancelConfirmation,
          ),
        ),
        body: order.paymentMethod == 'virtual_account'
            ? _VirtualAccountBody(
                order: order,
                payStatus: payStatus,
                formatPrice: _formatPrice,
                onCheckStatus: () => context.read<OrderProvider>().checkPaymentStatus(order.id),
              )
            : _BookPayBody(
                order: order,
                payStatus: payStatus,
                formatPrice: _formatPrice,
                payLaunched: _payLaunched,
                onOpenApp: _launchBookPay,
                onCheckStatus: () => context.read<OrderProvider>().checkPaymentStatus(order.id),
              ),
      ),
    );
  }
}

// ============================================================================
// WIDGET COMPONENTS
// ============================================================================

class _VirtualAccountBody extends StatelessWidget {
  final OrderModel order;
  final PaymentCheckStatus payStatus;
  final String Function(double) formatPrice;
  final VoidCallback onCheckStatus;

  const _VirtualAccountBody({
    required this.order,
    required this.payStatus,
    required this.formatPrice,
    required this.onCheckStatus,
  });

  static const List<_BankInfo> _banks = [
    _BankInfo('BCA', '888', Color(0xFF003087)),
    _BankInfo('Mandiri', '888', Color(0xFF003087)),
    _BankInfo('BNI', '8808', Color(0xFF004B87)),
    _BankInfo('BRI', '889', Color(0xFF00529B)),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final vaNumber = order.vaNumber ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.credit_card, size: 40, color: Color(0xFFE65100)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Selesaikan Pembayaran via Virtual Account',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Order #${order.id} · ${formatPrice(order.totalAmount)}',
              style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nomor Virtual Account', style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vaNumber,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2, color: onSurface),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: vaNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nomor VA disalin'), duration: Duration(seconds: 2)),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      color: primary,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Pembayaran', style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.7))),
                    Text(formatPrice(order.totalAmount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Cara Pembayaran', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < _banks.length; i++) ...[
                  _BankStepTile(bank: _banks[i]),
                  if (i < _banks.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          _CheckStatusButton(payStatus: payStatus, onPressed: onCheckStatus),
          const SizedBox(height: 16),
          if (payStatus == PaymentCheckStatus.idle)
            Center(
              child: Text(
                'Belum ada pembayaran terdeteksi',
                style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.5)),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _BankInfo {
  final String name;
  final String prefix;
  final Color color;
  const _BankInfo(this.name, this.prefix, this.color);
}

class _BankStepTile extends StatelessWidget {
  final _BankInfo bank;
  const _BankStepTile({required this.bank});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: bank.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Text(bank.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: bank.color)),
        ),
      ),
      title: Text(bank.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text('Pilih Transfer → Virtual Account → masukkan nomor VA', style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5))),
      ),
    );
  }
}

class _BookPayBody extends StatelessWidget {
  final OrderModel order;
  final PaymentCheckStatus payStatus;
  final String Function(double) formatPrice;
  final bool payLaunched;
  final VoidCallback onOpenApp;
  final VoidCallback onCheckStatus;

  const _BookPayBody({
    required this.order,
    required this.payStatus,
    required this.formatPrice,
    required this.payLaunched,
    required this.onOpenApp,
    required this.onCheckStatus,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_rounded, size: 46, color: primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Bayar dengan BookPay',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            'Order #${order.id} · ${formatPrice(order.totalAmount)}',
            style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepItem(
                  number: '1',
                  text: payLaunched ? 'Aplikasi BookPay sudah dibuka' : 'Kamu akan diarahkan ke aplikasi BookPay',
                  done: payLaunched,
                ),
                const SizedBox(height: 16),
                _StepItem(
                  number: '2',
                  text: 'Konfirmasi pembayaran ${formatPrice(order.totalAmount)} di BookPay',
                  done: false,
                ),
                const SizedBox(height: 16),
                _StepItem(
                  number: '3',
                  text: 'Kembali ke aplikasi — status otomatis diperbarui',
                  done: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text(
                payLaunched ? 'Buka Kembali BookPay' : 'Buka BookPay',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: onOpenApp,
            ),
          ),
          const SizedBox(height: 16),
          _CheckStatusButton(payStatus: payStatus, onPressed: onCheckStatus),
          const SizedBox(height: 16),
          if (payStatus == PaymentCheckStatus.idle && payLaunched)
            Text(
              'Sedang menunggu konfirmasi pembayaran dari BookPay...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.5)),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;
  final bool done;

  const _StepItem({required this.number, required this.text, required this.done});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? Colors.green : primary.withValues(alpha: 0.12),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(number, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: TextStyle(fontSize: 14, color: onSurface, height: 1.4)),
          ),
        ),
      ],
    );
  }
}

class _CheckStatusButton extends StatelessWidget {
  final PaymentCheckStatus payStatus;
  final VoidCallback onPressed;

  const _CheckStatusButton({required this.payStatus, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isChecking = payStatus == PaymentCheckStatus.checking;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        icon: isChecking
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
              )
            : const Icon(Icons.refresh_rounded),
        label: Text(
          isChecking ? 'Memeriksa Status...' : 'Cek Status Pembayaran',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        onPressed: isChecking ? null : onPressed,
      ),
    );
  }
}