import 'dart:async';
import 'package:book_store/features/auth/presentation/providers/auth_provider.dart';
import 'package:book_store/features/auth/presentation/widgets/auth_header.dart';
import 'package:book_store/features/auth/presentation/widgets/custom_button.dart';
import 'package:book_store/core/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _timer;
  bool _resendCooldown = false;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final success = await auth.checkEmailVerified();
      if (success && mounted) {
        _timer?.cancel();
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown) return;
    await context.read<AuthProvider>().resendVerificationEmail();

    setState(() {
      _resendCooldown = true;
      _countdown = 60;
    });
    Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        t.cancel();
        setState(() => _resendCooldown = false);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email verifikasi sudah dikirim ulang', style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface)),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().firebaseUser;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AuthHeader(
                icon: Icons.mark_email_unread_outlined,
                title: 'Verifikasi Email Kamu',
                subtitle: 'Kami sudah mengirim link verifikasi ke email di bawah ini.',
                iconColor: Colors.orange,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Text(
                  user?.email ?? '-',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Menunggu konfirmasi...',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: _resendCooldown
                    ? 'Kirim Ulang ($_countdown detik)'
                    : 'Kirim Ulang Email',
                variant: ButtonVariant.outlined,
                onPressed: _resendCooldown ? null : _resendEmail,
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Ganti Akun / Logout',
                variant: ButtonVariant.text,
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.pushReplacementNamed(context, AppRouter.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}