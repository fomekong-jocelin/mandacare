import 'package:flutter/material.dart';

import '../features/auth/data/auth_gateway.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/patients/data/patient_gateway.dart';
import '../features/tariff/data/tariff_gateway.dart';
import '../features/more/data/clinic_gateway.dart';
import '../features/users/data/user_gateway.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MandaCareApp extends StatelessWidget {
  const MandaCareApp({
    this.initialSession,
    this.authGateway,
    this.patientGateway,
    this.userGateway,
    this.tariffGateway,
    this.clinicGateway,
    super.key,
  });

  final AuthSession? initialSession;
  final AuthGateway? authGateway;
  final PatientGateway? patientGateway;
  final UserGateway? userGateway;
  final TariffGateway? tariffGateway;
  final ClinicGateway? clinicGateway;

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
        userGateway: userGateway,
        tariffGateway: tariffGateway,
        clinicGateway: clinicGateway,
      ),
    );
  }
}
