import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

void _log(String tag, String message) {
  debugPrint('[BookStore/$tag] $message');
}

class PaymentCallbackData {
  final String status;
  final String? reference;
  final String? transactionId;

  const PaymentCallbackData({required this.status, this.reference, this.transactionId});

  bool get isSuccess => status == 'success';

  @override
  String toString() =>
      'PaymentCallbackData(status=$status, reference=$reference, transactionId=$transactionId)';
}

class BookStorePayService {
  static final BookStorePayService _instance = BookStorePayService._();
  factory BookStorePayService() => _instance;
  BookStorePayService._();

  static const _tag = 'BookPay';

  final _callbackController = StreamController<PaymentCallbackData>.broadcast();
  Stream<PaymentCallbackData> get onCallback => _callbackController.stream;

  PaymentCallbackData? _pendingCallback;

  PaymentCallbackData? consumePendingCallback() {
    final data = _pendingCallback;
    _pendingCallback = null;
    if (data != null) {
      debugPrint('[BookStore/BookPay] Mengonsumsi pending cold-start callback: $data');
    }
    return data;
  }

  Future<void> init() async {
    debugPrint('[BookStore/BookPay] Inisialisasi BookStorePayService...');
    final appLinks = AppLinks();

    try {
      debugPrint('[BookStore/BookPay] Mengambil initial link (cold start)...');
      final uri = await appLinks.getInitialLink();
      if (uri != null) {
        debugPrint('[BookStore/BookPay] Initial link ditemukan: $uri');
        _handleUri(uri, isColdStart: true);
      } else {
        debugPrint('[BookStore/BookPay] Tidak ada initial link (app dibuka normal)');
      }
    } catch (e) {
      debugPrint('[BookStore/BookPay] Error saat getInitialLink: $e');
    }

    debugPrint('[BookStore/BookPay] Memulai listener uriLinkStream...');
    appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('[BookStore/BookPay] URI masuk via stream: $uri');
        _handleUri(uri);
      },
      onError: (Object e) {
        debugPrint('[BookStore/BookPay] Error pada uriLinkStream: $e');
      },
    );
    debugPrint('[BookStore/BookPay] Inisialisasi selesai.');
  }

  void _handleUri(Uri uri, {bool isColdStart = false}) {
    debugPrint(
      '[BookStore/BookPay] Handle URI | scheme=${uri.scheme} host=${uri.host} '
      'path=${uri.path} params=${uri.queryParameters} | coldStart=$isColdStart',
    );

    if (uri.scheme != 'bookstore') {
      debugPrint('[BookStore/BookPay] Diabaikan — bukan skema bookstore (scheme=${uri.scheme})');
      return;
    }

    final isCallbackHost = uri.host == 'payment-callback';
    final isCallbackPath = uri.path == '/payment-callback';
    final isReturnUrl = uri.host.isEmpty && uri.path.isEmpty && uri.queryParameters.containsKey('status');

    if (!isCallbackHost && !isCallbackPath && !isReturnUrl) {
      debugPrint('[BookStore/BookPay] Diabaikan — bukan callback yang dikenali');
    return;
    }

    if (uri.host != 'payment-callback') {
      debugPrint('[BookStore/BookPay] Diabaikan — bukan host payment-callback (host=${uri.host})');
      return;
    }

    final data = PaymentCallbackData(
      status: uri.queryParameters['status'] ?? 'unknown',
      reference: uri.queryParameters['reference'],
      transactionId: uri.queryParameters['transaction_id'],
    );

    debugPrint('[BookStore/BookPay] Callback diterima: $data');

    if (isColdStart) {
      _pendingCallback = data;
      debugPrint('[BookStore/BookPay] Disimpan sebagai pending cold-start callback');
    }

    _callbackController.add(data);
    debugPrint('[BookStore/BookPay] Event dikirim ke stream (subscriber aktif)');
  }

  static String buildDeeplinkUrl({
    required int orderId,
    required double amount,
    String? description,
  }) {
    const scheme = 'bookpay';
    const host = 'pay';
    final desc = (description != null && description.isNotEmpty) ? description : 'Order #$orderId';
    const callbackUrl = 'bookstore://payment-callback';

    _log(_tag, ' Membangun deeplink URL:');
    _log(_tag, 'merchant_id : MCH_BOOK_STORE');
    _log(_tag, 'merchant_name: Book Store');
    _log(_tag, 'amount : ${amount.toInt()}');
    _log(_tag, 'description : $desc');
    _log(_tag, 'reference : INV-$orderId');
    _log(_tag, 'callback : $callbackUrl');

    final uri = Uri(
      scheme: scheme,
      host: host,
      queryParameters: {
        'merchant_id': 'MCH_BOOK_STORE',
        'merchant_name': 'Book Store',
        'amount': amount.toInt().toString(),
        'description': desc,
        'reference': 'INV-$orderId',
        'callback': callbackUrl,
      },
    );

    final result = uri.toString();
    _log(_tag, ' URL lengkap (sebelum launch): $result');
    return result;
  }
}