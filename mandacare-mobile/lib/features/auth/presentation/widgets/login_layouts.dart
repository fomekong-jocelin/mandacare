import 'package:flutter/material.dart';

class CompactLoginLayout extends StatelessWidget {
  const CompactLoginLayout({
    required this.constraints,
    required this.form,
    super.key,
  });

  final BoxConstraints constraints;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    final topSpace = constraints.maxHeight < 720 ? 292.0 : 372.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topSpace),
            form,
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class WideLoginLayout extends StatelessWidget {
  const WideLoginLayout({required this.form, super.key});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Spacer(),
          const SizedBox(width: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: form,
          ),
        ],
      ),
    );
  }
}
