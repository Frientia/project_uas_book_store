import 'package:flutter/material.dart';
import 'package:book_store/core/routes/app_router.dart';
import 'package:book_store/features/cart/presentation/providers/cart_provider.dart';
import 'package:book_store/features/order/presentation/providers/order_provider.dart';
import 'package:provider/provider.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  String? _selectedPaymentMethod;

  final List<Map<String, String>> _paymentOptions = [
    {'label': 'GoPay', 'value': 'gopay'},
    {'label': 'Transfer Bank', 'value': 'bank_transfer'},
    {'label': 'Virtual Account', 'value': 'virtual_account'},
  ];

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate() || _selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi data terlebih dahulu')));
      return;
    }

    final orderProv = context.read<OrderProvider>();
    final cartProv = context.read<CartProvider>();

    final success = await orderProv.checkout(
      shippingAddress: _addressCtrl.text.trim(),
      paymentMethod: _selectedPaymentMethod!,
    );

    if (success && mounted) {
      await cartProv.clearCart();
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.orderSuccess, (route) => false, arguments: orderProv.lastOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>().cart;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Alamat Pengiriman', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Masukkan alamat...'),
              validator: (v) => (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            Text('Metode Pembayaran', style: theme.textTheme.titleMedium),
            ..._paymentOptions.map((option) => RadioListTile(
                  title: Text(option['label']!),
                  value: option['value'],
                  groupValue: _selectedPaymentMethod,
                  onChanged: (v) => setState(() => _selectedPaymentMethod = v),
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _placeOrder,
              child: Text('Bayar Rp ${cart?.total.toInt() ?? 0}'),
            ),
          ],
        ),
      ),
    );
  }
}