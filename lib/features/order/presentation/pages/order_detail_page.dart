import 'package:book_store/features/order/data/model/order_model.dart';
import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final OrderModel order;

  const OrderDetailPage({super.key, required this.order});

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

  String _formatDate(String createdAt) {
    if (createdAt.isEmpty) return '-';
    try {
      final dt = DateTime.parse(createdAt);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Menunggu Pembayaran';
      case 'processing': return 'Sedang Diproses';
      case 'shipped': return 'Dikirim';
      case 'delivered': return 'Diterima';
      case 'cancelled': return 'Dibatalkan';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final statusColor = _statusColor(order.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. KARTU STATUS & INFO UTAMA ──
            _buildCard(
              surface: surface,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
                      ),
                      Text(
                        _formatDate(order.createdAt),
                        style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status Pesanan', style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.7))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(order.status),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 2. INSTRUKSI PEMBAYARAN (JIKA PENDING) ──
            if (order.status == 'pending')
              _buildCard(
                surface: surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Selesaikan Pembayaran',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Metode: ${order.paymentMethod.toUpperCase()}', style: TextStyle(color: onSurface)),
                    
                    if (order.vaNumber != null && order.vaNumber!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('No. Virtual Account:', style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(order.vaNumber!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {

                            },
                          ),
                        ],
                      ),
                    ],
                    
                    if (order.gopayDeeplink != null && order.gopayDeeplink!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AED6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                          },
                          child: const Text('Buka Aplikasi GoPay', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (order.status == 'pending') const SizedBox(height: 16),

            // ── 3. INFO PENGIRIMAN ──
            _buildCard(
              surface: surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: primary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(order.shippingAddress, style: TextStyle(height: 1.5, color: onSurface)),
                  if (order.notes.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text('Catatan:', style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 4),
                    Text(order.notes, style: TextStyle(fontStyle: FontStyle.italic, color: onSurface)),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 4. DAFTAR PRODUK YANG DIBELI ──
            Text('  Detail Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface)),
            const SizedBox(height: 8),
            _buildCard(
              surface: surface,
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.book_rounded, color: primary.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                '${item.quantity} x ${_formatPrice(item.price)}',
                                style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatPrice(item.subtotal),
                          style: TextStyle(fontWeight: FontWeight.bold, color: onSurface),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── 5. TOTAL PEMBAYARAN ──
            _buildCard(
              surface: surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurface)),
                  Text(
                    _formatPrice(order.totalAmount),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk membuat kartu yang konsisten dengan MyOrdersPage
  Widget _buildCard({required Color surface, required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(20)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}