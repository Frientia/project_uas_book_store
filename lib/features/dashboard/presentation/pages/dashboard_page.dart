import 'package:book_store/features/auth/presentation/providers/auth_provider.dart';
import 'package:book_store/features/dashboard/presentation/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Ambil data produk saat halaman pertama kali dibuka [cite: 2018, 2019]
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final product = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${auth.firebaseUser?.displayName ?? 'User'}!'), // [cite: 2031]
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(), // [cite: 2039, 2040]
          ),
        ],
      ),
      // Step 8.4: Gunakan switch untuk merespons status produk [cite: 1828, 2049]
      body: switch (product.status) {
        ProductStatus.loading || ProductStatus.initial => const Center(
          child: CircularProgressIndicator(), // [cite: 1830, 2054]
        ),
        ProductStatus.error => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(product.error ?? 'Error'), // [cite: 2066]
              ElevatedButton(
                onPressed: () => product.fetchProducts(),
                child: const Text('Coba Lagi'), // [cite: 2071, 2072]
              ),
            ],
          ),
        ),
        ProductStatus.loaded => RefreshIndicator(
          onRefresh: () => product.fetchProducts(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: product.products.length,
            itemBuilder: (context, i) {
              final p = product.products[i];
              return Card(
                child: Column(
                  children: [
                    Expanded(child: Image.network(p.imageUrl, fit: BoxFit.cover)), // [cite: 2093]
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text('Rp ${p.price.toStringAsFixed(0)}'), // [cite: 2119]
                  ],
                ),
              );
            },
          ),
        ),
      },
    );
  }
}