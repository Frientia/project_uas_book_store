import 'package:flutter/material.dart';
import 'package:book_store/features/order/data/model/order_model.dart';
import 'package:book_store/core/routes/app_router.dart';

class OrderSuccessPage extends StatelessWidget {
  final OrderModel order;
  const OrderSuccessPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            Text('Pesanan Berhasil!', style: theme.textTheme.headlineSmall),
            Text('Order #${order.id}', style: TextStyle(color: theme.colorScheme.primary)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRouter.dashboard, (route) => false),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }
}