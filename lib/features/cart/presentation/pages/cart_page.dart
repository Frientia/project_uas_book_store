import 'package:flutter/material.dart';
import 'package:book_store/core/routes/app_router.dart';
import 'package:book_store/features/cart/presentation/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang Belanja')),
      body: Consumer<CartProvider>(
        builder: (context, cartProv, _) {
          if (cartProv.status == CartStatus.loading || cartProv.status == CartStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProv.cart == null || cartProv.cart!.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text('Keranjang kosong', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            );
          }

          final cart = cartProv.cart!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) {
                    final item = cart.items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Image.network(item.product.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                        title: Text(item.product.name),
                        subtitle: Text('Rp ${item.subtotal.toInt()}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => cartProv.updateItem(item.id, item.quantity - 1),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => cartProv.updateItem(item.id, item.quantity + 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  onPressed: () => Navigator.pushNamed(context, AppRouter.checkout),
                  child: Text('Checkout (Rp ${cart.total.toInt()})'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}