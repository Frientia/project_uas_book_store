import 'package:book_store/core/constants/api_constants.dart';
import 'package:book_store/core/services/dio_client.dart';
import 'package:book_store/features/order/data/model/order_model.dart';
import 'package:book_store/features/order/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  @override
  Future<OrderModel> checkout({
    required String shippingAddress,
    String? notes,
    required String paymentMethod,
  }) async {
    final response = await DioClient.instance.post(
      ApiConstants.checkout,
      data: {
        'shipping_address': shippingAddress,
        'notes': notes ?? '',
        'payment_method': paymentMethod,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }

  @override
  Future<List<OrderModel>> getMyOrders({int page = 1, int limit = 10}) async {
    final response = await DioClient.instance.get(
      ApiConstants.orders,
      queryParameters: {'page': page, 'limit': limit},
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((e) => OrderModel.fromJson(e)).toList();
  }

  @override
  Future<OrderModel> getOrderDetail(int orderId) async {
    final response = await DioClient.instance.get('${ApiConstants.orders}/$orderId');
    final data = response.data['data'] as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }
}