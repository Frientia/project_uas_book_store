import 'package:flutter/material.dart';
import 'package:book_store/features/order/presentation/providers/order_provider.dart';
import 'package:provider/provider.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().fetchMyOrders());
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: orderProv.checkoutStatus == OrderStatus.loading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: orderProv.orders.length,
              itemBuilder: (ctx, i) {
                final order = orderProv.orders[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Order #${order.id}'),
                    subtitle: Text('Total: Rp ${order.totalAmount.toInt()}'),
                    trailing: Chip(label: Text(order.status)),
                  ),
                );
              },
            ),
    );
  }
}