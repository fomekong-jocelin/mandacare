import 'package:flutter/material.dart';

import '../features/auth/data/auth_gateway.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/patients/data/patient_gateway.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MandaCareApp extends StatelessWidget {
  const MandaCareApp({
    this.initialSession,
    this.authGateway,
    this.patientGateway,
    super.key,
  });

  final AuthSession? initialSession;
  final AuthGateway? authGateway;
  final PatientGateway? patientGateway;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MandaCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.12,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AppRouter(
        initialSession: initialSession,
        authGateway: authGateway,
        patientGateway: patientGateway,
      ),
    );
  }
}
