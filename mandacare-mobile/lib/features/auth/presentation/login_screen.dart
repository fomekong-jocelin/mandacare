import 'package:flutter/material.dart';

import '../../../app/api/api_exception.dart';
import '../domain/auth_session.dart';
import 'widgets/login_background_image.dart';
import 'widgets/login_layouts.dart';
import 'widgets/login_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.onLogin, super.key});

  final Future<AuthSession> Function(String username, String password) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin123');
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: LoginBackgroundImage()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final form = LoginPanel(
                  formKey: _formKey,
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  loading: _loading,
                  error: _error,
                  onTogglePassword: _togglePassword,
                  onSubmit: _submit,
                );

                if (constraints.maxWidth >= 720) {
                  return WideLoginLayout(form: form);
                }

                return CompactLoginLayout(constraints: constraints, form: form);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _togglePassword() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onLogin(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() => _error = exception.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Connexion impossible au serveur.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
