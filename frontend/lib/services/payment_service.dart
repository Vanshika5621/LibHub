import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../constants.dart';
import '../services/supabase_service.dart';

class PaymentService {
  late Razorpay _razorpay;
  final SupabaseService _supabaseService;

  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  PaymentService(this._supabaseService) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(response);
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onExternalWallet?.call(response);
  }

  // Create order via backend
  Future<Map<String, dynamic>> createOrder({
    required double amount,
    required String paymentType,
    String? membershipTier,
    String? fineId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/api/razorpay/create-order'),
        headers: {
          'Content-Type': 'application/json',
          if (_supabaseService.accessToken != null)
            'Authorization': 'Bearer ${_supabaseService.accessToken}',
        },
        body: json.encode({
          'amount': amount,
          'paymentType': paymentType,
          'membershipTier': membershipTier,
          'fineId': fineId,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Open Razorpay checkout
  Future<Map<String, dynamic>> openCheckout({
    required double amount,
    required String paymentType,
    String? membershipTier,
    String? fineId,
    required String userName,
    required String userEmail,
    required String userPhone,
  }) async {
    final orderResult = await createOrder(
      amount: amount,
      paymentType: paymentType,
      membershipTier: membershipTier,
      fineId: fineId,
    );

    if (orderResult.containsKey('error')) {
      return orderResult;
    }

    final options = {
      'key': AppConstants.razorpayKeyId,
      'amount': orderResult['amount'],
      'name': 'LibHub',
      'description': paymentType == 'membership'
          ? '${membershipTier?.toUpperCase()} Membership'
          : 'Fine Payment',
      'order_id': orderResult['orderId'],
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
        'name': userName,
      },
      'theme': {
        'color': '#4F46E5',
      },
    };

    try {
      _razorpay.open(options);
      return {'success': true, 'paymentId': orderResult['paymentId']};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Verify payment via backend
  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String internalPaymentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/api/razorpay/verify'),
        headers: {
          'Content-Type': 'application/json',
          if (_supabaseService.accessToken != null)
            'Authorization': 'Bearer ${_supabaseService.accessToken}',
        },
        body: json.encode({
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
          'paymentId': internalPaymentId,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
