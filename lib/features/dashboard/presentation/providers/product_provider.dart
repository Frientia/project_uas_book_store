import 'package:book_store/core/constants/api_constants.dart';
import 'package:book_store/core/services/dio_client.dart';
import 'package:book_store/features/dashboard/data/models/product_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

enum ProductStatus { initial, loading, loaded, error }

class ProductProvider extends ChangeNotifier {
  ProductStatus _status = ProductStatus.initial;
  List<ProductModel> _products = [];
  String? _error;

  // Getters agar bisa dibaca oleh UI [cite: 1107]
  ProductStatus get status => _status;
  List<ProductModel> get products => _products;
  String? get error => _error;
  bool get isLoading => _status == ProductStatus.loading;

  Future<void> fetchProducts() async {
    _status = ProductStatus.loading;
    notifyListeners(); // UI tampilkan spinner [cite: 1781]

    try {
      // Hit API - Token otomatis masuk via Interceptor DioClient [cite: 1783, 1785]
      final response = await DioClient.instance.get(ApiConstants.products);

      // Parse data dari { "data": [...] } [cite: 1792, 1999]
      final List<dynamic> data = response.data['data'];
      _products = data.map((e) => ProductModel.fromJson(e)).toList();
      
      _status = ProductStatus.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal memuat produk';
      _status = ProductStatus.error;
    }

    notifyListeners(); // Beritahu UI untuk rebuild [cite: 1799]
  }
}