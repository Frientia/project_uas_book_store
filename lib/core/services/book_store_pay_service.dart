import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

void _log(String tag, String message) {
  debugPrint('[PasarMalam/$tag] $message');
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
      _log(_tag, ' Mengonsumsi pending cold-start callback: $data');
    }
    return data;
  }

  Future<void> init() async {
    _log(_tag, ' Inisialisasi GlobalInstitutePayService...');
    final appLinks = AppLinks();

    try {
      _log(_tag, ' Mengambil initial link (cold start)...');
      final uri = await appLinks.getInitialLink();
      if (uri != null) {
        _log(_tag, ' Initial link ditemukan: $uri');
        _handleUri(uri, isColdStart: true);
      } else {
        _log(_tag, ' Tidak ada initial link (app dibuka normal)');
      }
    } catch (e) {
      _log(_tag, 'Error saat getInitialLink: $e');
    }

    _log(_tag, ' Memulai listener uriLinkStream...');
    appLinks.uriLinkStream.listen(
      (uri) {
        _log(_tag, ' URI masuk via stream: $uri');
        _handleUri(uri);
      },
      onError: (Object e) {
        _log(_tag, 'Error pada uriLinkStream: $e');
      },
    );
    _log(_tag, ' Inisialisasi selesai.');
  }

  void _handleUri(Uri uri, {bool isColdStart = false}) {
    _log(
      _tag,
      ' Handle URI | scheme=${uri.scheme} host=${uri.host} '
      'path=${uri.path} params=${uri.queryParameters} | coldStart=$isColdStart',
    );

    if (uri.scheme != 'bookstore') {
      _log(_tag, ' Diabaikan — bukan skema bookstore (scheme=${uri.scheme})');
      return;
    }
    if (uri.host != 'payment-callback') {
      _log(_tag, ' Diabaikan — bukan host payment-callback (host=${uri.host})');
      return;
    }

    final data = PaymentCallbackData(
      status: uri.queryParameters['status'] ?? 'unknown',
      reference: uri.queryParameters['reference'],
      transactionId: uri.queryParameters['transaction_id'],
    );

    _log(_tag, ' Callback diterima: $data');

    if (isColdStart) {
      _pendingCallback = data;
      _log(_tag, ' Disimpan sebagai pending cold-start callback');
    }

    _callbackController.add(data);
    _log(_tag, ' Event dikirim ke stream (subscriber aktif)');
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
    _log(_tag, 'merchant_id : MCH_PASAR_MALAM');
    _log(_tag, 'merchant_name: Book Store');
    _log(_tag, 'amount : ${amount.toInt()}');
    _log(_tag, 'description : $desc');
    _log(_tag, 'reference : INV-$orderId');
    _log(_tag, 'callback : $callbackUrl');

    final uri = Uri(
      scheme: scheme,
      host: host,
      queryParameters: {
        'merchant_id': 'MCH_PASAR_MALAM',
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