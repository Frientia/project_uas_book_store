import 'package:book_store/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Monitor status login user
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.authenticated => child, // Jika login, boleh masuk
      AuthStatus.emailNotVerified => const Scaffold(body: Center(child: Text("Verifikasi Email Dulu"))), 
      _ => const Scaffold(body: Center(child: Text("Silakan Login"))) // Jika logout, lempar ke Login
    };
  }
}