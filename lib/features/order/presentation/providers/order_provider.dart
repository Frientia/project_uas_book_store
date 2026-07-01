import 'dart:async';
import 'package:book_store/core/services/dio_client.dart'; // <-- 1. Tambahkan import ini
import 'package:book_store/features/order/data/model/order_model.dart';
import 'package:book_store/features/order/domain/repositories/order_repository.dart';
import 'package:book_store/features/order/domain/repositories/order_repository_impl.dart';
import 'package:flutter/material.dart';

enum OrderStatus { initial, loading, success, error }
enum PaymentCheckStatus { idle, checking, paid }

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository = OrderRepositoryImpl();

  OrderStatus _checkoutStatus = OrderStatus.initial;
  OrderModel? _lastOrder;
  List<OrderModel> _orders = [];
  String? _error;

  PaymentCheckStatus _paymentCheckStatus = PaymentCheckStatus.idle;
  Timer? _pollingTimer;

  OrderStatus get checkoutStatus => _checkoutStatus;
  OrderModel? get lastOrder => _lastOrder;
  List<OrderModel> get orders => _orders;
  String? get error => _error;
  PaymentCheckStatus get paymentCheckStatus => _paymentCheckStatus;

  Future<bool> checkout({
    required String shippingAddress,
    String? notes,
    required String paymentMethod,
  }) async {
    _checkoutStatus = OrderStatus.loading;
    notifyListeners();
    try {
      _lastOrder = await _repository.checkout(
        shippingAddress: shippingAddress,
        notes: notes,
        paymentMethod: paymentMethod,
      );
      _checkoutStatus = OrderStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _checkoutStatus = OrderStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyOrders({int page = 1, int limit = 10}) async {
    _checkoutStatus = OrderStatus.loading;
    notifyListeners();
    try {
      _orders = await _repository.getMyOrders(page: page, limit: limit);
      _checkoutStatus = OrderStatus.success;
    } catch (e) {
      _error = e.toString();
      _checkoutStatus = OrderStatus.error;
    }
    notifyListeners();
  }

Future<void> checkPaymentStatus(int orderId) async {
    _paymentCheckStatus = PaymentCheckStatus.checking;
    notifyListeners();
    
    try {
      final updatedOrder = await _repository.getOrderDetail(orderId);
      _lastOrder = updatedOrder;
      
      if (updatedOrder.status.toLowerCase() == 'paid') {
        _paymentCheckStatus = PaymentCheckStatus.paid;
      } else {
        _paymentCheckStatus = PaymentCheckStatus.idle;
      }
    } catch (e) {
      _paymentCheckStatus = PaymentCheckStatus.idle;
    }
    notifyListeners();
  }
  void startPaymentPolling(int orderId) {
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {

      await checkPaymentStatus(orderId);
      if (_paymentCheckStatus == PaymentCheckStatus.paid) {
        timer.cancel();
      }
    });
  }

  void stopPaymentPolling() {
    _pollingTimer?.cancel();
    _paymentCheckStatus = PaymentCheckStatus.idle;
  }

  Future<bool> updateOrderStatusToPaid(int orderId) async {
    try {
      final response = await DioClient.instance.put('/v1/orders/$orderId/pay');
      
      if (response.statusCode == 200) {
        // <-- 2. Ubah lastOrder menjadi _lastOrder di sini
        if (_lastOrder != null && _lastOrder!.id == orderId) {
          _lastOrder = _lastOrder!.copyWith(status: 'paid');
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}