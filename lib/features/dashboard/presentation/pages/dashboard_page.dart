import 'package:book_store/core/routes/app_router.dart';
import 'package:book_store/features/auth/presentation/providers/auth_provider.dart';
import 'package:book_store/features/cart/presentation/providers/cart_provider.dart';
import 'package:book_store/features/dashboard/presentation/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:book_store/core/providers/theme_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // State lokal untuk filter UI (bisa disambungkan ke provider nanti)
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['Semua', 'Fiksi', 'Edukasi', 'Komik', 'Biografi', 'Teknologi'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProv = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    
    final isDark = themeProvider.isDark;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: surface,
      appBar: _buildAppBar(context, auth, cart.itemCount, isDark),
      body: Column(
        children: [
          // Bagian Header: Search & Categories
          _buildSearchAndCategories(onSurface),
          
          // Bagian Konten Utama: Grid Buku
          Expanded(
            child: _buildMainContent(productProv),
          ),
        ],
      ),
    );
  }

  // --- KOMPONEN APPBAR ---
  PreferredSizeWidget _buildAppBar(BuildContext context, AuthProvider auth, int cartCount, bool isDark) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0, // Mencegah warna berubah saat discroll di Material 3
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, ${auth.firebaseUser?.displayName?.split(' ').first ?? 'User'} 👋',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Mau baca buku apa hari ini?',
            style: TextStyle(
              fontSize: 13, 
              fontWeight: FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: isDark ? Colors.amber : Colors.grey.shade700,
          ),
          onPressed: () => context.read<ThemeProvider>().toggle(),
        ),
        // Ikon Keranjang dengan Badge
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => Navigator.pushNamed(context, AppRouter.cart),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6, 
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                    ),
                    child: Text(
                      cartCount > 9 ? '9+' : '$cartCount',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --- KOMPONEN HEADER (SEARCH & FILTER) ---
  Widget _buildSearchAndCategories(Color onSurface) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari judul, penulis, atau ISBN...',
              hintStyle: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.4)),
              filled: true,
              fillColor: onSurface.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        
        // Category Chips Horizontal
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = _selectedCategoryIndex == index;
              final primary = Theme.of(context).colorScheme.primary;
              
              return ActionChip(
                label: Text(_categories[index]),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : onSurface.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                backgroundColor: isSelected ? primary : onSurface.withOpacity(0.05),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () {
                  setState(() => _selectedCategoryIndex = index);
                  // TODO: Panggil fungsi filter produk di sini berdasarkan _categories[index]
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- KOMPONEN MAIN CONTENT ---
  Widget _buildMainContent(ProductProvider productProv) {
    return switch (productProv.status) {
      ProductStatus.loading || ProductStatus.initial => const Center(
          child: CircularProgressIndicator(),
        ),
      ProductStatus.error => _buildErrorState(productProv),
      ProductStatus.loaded => RefreshIndicator(
          onRefresh: () => productProv.fetchProducts(),
          child: productProv.products.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58, // Rasio dipertajam untuk buku (lebih tinggi)
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: productProv.products.length,
                  itemBuilder: (context, i) => _ProductCard(
                    product: productProv.products[i],
                  ),
                ),
        ),
    };
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 80, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            'Belum ada sinopsis untuk buku ini.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ProductProvider productProv) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 80, color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            productProv.error ?? 'Gagal terhubung ke server', 
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
            onPressed: () => productProv.fetchProducts(),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// KARTU PRODUK (BOOK CARD)
// ==========================================
class _ProductCard extends StatelessWidget {
  final dynamic product;
  
  const _ProductCard({required this.product});

  void _showProductDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Transparan agar rounded corner sheet terlihat rapi
      builder: (_) => _ProductDetailSheet(
        product: product, 
        formatPrice: (price) => 'Rp ${price.toInt().toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => _showProductDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Buku dengan Hero Animation
            Expanded(
              child: Hero(
                tag: 'book_cover_${product.id}',
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.menu_book_rounded, color: Theme.of(context).disabledColor, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Info Buku
            Text(
              product.category ?? 'Buku',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: onSurface.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14,
                color: onSurface,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              'Rp ${product.price.toInt().toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// BOTTOM SHEET (DETAIL BUKU)
// ==========================================
class _ProductDetailSheet extends StatefulWidget {
  final dynamic product;
  final String Function(double) formatPrice;

  const _ProductDetailSheet({required this.product, required this.formatPrice});

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  int quantity = 1;
  bool isAdding = false;

  Future<void> _addToCart() async {
    setState(() => isAdding = true);
    
    final cartProv = context.read<CartProvider>();
    final success = await cartProv.addToCart(widget.product.id, quantity);
    
    if (!mounted) return;
    setState(() => isAdding = false);
    
    if (success) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buku berhasil ditambahkan ke keranjang!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartProv.error ?? 'Gagal menambahkan buku'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'book_cover_${widget.product.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(4, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.product.imageUrl,
                              width: 110,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 110,
                                height: 160,
                                color: Theme.of(context).highlightColor,
                                child: Icon(Icons.book, color: Theme.of(context).disabledColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.product.category ?? 'Buku', 
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.formatPrice(widget.product.price),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  
                  const Text(
                    'Sinopsis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.description ?? 'Belum ada sinopsis untuk buku ini.',
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurface.withOpacity(0.8),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          Container(
            padding: EdgeInsets.only(
              left: 20, 
              right: 20, 
              top: 16, 
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: onSurface.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: quantity > 1 
                            ? () => setState(() => quantity--) 
                            : null,
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () => setState(() => quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton.icon(
                    icon: isAdding 
                      ? const SizedBox.shrink() 
                      : const Icon(Icons.shopping_cart_checkout_rounded, size: 20),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isAdding ? null : _addToCart,
                    label: isAdding
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text(
                            'Keranjang',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}