import 'package:book_store/features/auth/presentation/pages/Register_page.dart';
import 'package:book_store/features/auth/presentation/pages/login_page.dart';
import 'package:book_store/features/auth/presentation/pages/verify_email_page.dart';
import 'package:book_store/features/auth/presentation/providers/auth_provider.dart';
import 'package:book_store/features/cart/presentation/pages/cart_page.dart';
import 'package:book_store/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:book_store/features/order/data/model/order_model.dart';
import 'package:book_store/features/order/presentation/pages/checkout_page.dart';
import 'package:book_store/features/order/presentation/pages/order_success_page.dart';

import 'package:book_store/features/order/presentation/pages/payment_pending_page.dart'; 

import 'package:book_store/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppRouter { 
  static const String splash      = '/'; 
  static const String login       = '/login'; 
  static const String register    = '/register'; 
  static const String verifyEmail = '/verify-email'; 
  static const String dashboard   = '/dashboard';
  static const String cart        = '/cart'; 
  static const String myOrders    = '/my-orders'; 
  static const String checkout     = '/checkout';

  static const String orderSuccess = '/order-success';
  static const String paymentPending = '/payment-pending';
 
  static Map<String, WidgetBuilder> get routes => { 
    splash:      (_) => const SplashPage(), 
    login:       (_) => const LoginPage(), 
    register:    (_) => const RegisterPage(), 
    verifyEmail: (_) => const VerifyEmailPage(), 
    dashboard:   (_) => const AuthGuard(child: DashboardPage()),
    cart:         (_) => const AuthGuard(child: CartPage()),
    checkout:     (_) => const AuthGuard(child: CheckoutPage()),
    
    paymentPending: (context) {
      final order = ModalRoute.of(context)!.settings.arguments as OrderModel;
      return PaymentPendingPage(order: order);
    },

    orderSuccess: (context) {
      final order = ModalRoute.of(context)!.settings.arguments as OrderModel;
      return OrderSuccessPage(order: order);
    },
  };
}

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.authenticated => child,
      AuthStatus.emailNotVerified => const Scaffold(body: Center(child: Text("Verifikasi Email Dulu"))), 
      _ => const Scaffold(body: Center(child: Text("Silakan Login")))
    };
  }
}