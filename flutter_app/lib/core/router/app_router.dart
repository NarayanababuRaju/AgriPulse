import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/farmer_login_screen.dart';
import '../../features/dashboard/presentation/farmer_dashboard_screen.dart';
import '../../features/crop_diagnosis/presentation/crop_doctor_screen.dart';
import '../../features/yield_prediction/presentation/screens/yield_prediction_screen.dart';
import '../../features/crop_diagnosis/models/diagnosis_record.dart';
import '../../features/crop_diagnosis/presentation/screens/diagnosis_details_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/yield_prediction/models/yield_record.dart';
import '../../features/yield_prediction/presentation/screens/yield_details_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRouter.loginPath,
    redirect: (context, state) {
      // If authState is loading, don't redirect yet
      if (authState.isLoading) return null;

      final bool loggedIn = authState.value != null;
      final bool loggingIn = state.matchedLocation == AppRouter.loginPath;

      // If user is not logged in and not on login page, send to login
      if (!loggedIn && !loggingIn) {
        return AppRouter.loginPath;
      }

      // If user is logged in and on login page, send to dashboard
      if (loggedIn && loggingIn) {
        return AppRouter.dashboardPath;
      }

      // No redirection needed
      return null;
    },
    routes: [
      GoRoute(
        path: AppRouter.loginPath,
        builder: (context, state) => const FarmerLoginScreen(),
      ),
      GoRoute(
        path: AppRouter.dashboardPath,
        builder: (context, state) => const FarmerDashboardScreen(),
      ),
      GoRoute(
        path: AppRouter.cropDoctorPath,
        builder: (context, state) => const CropDoctorScreen(),
      ),
      GoRoute(
        path: AppRouter.yieldPredictionPath,
        builder: (context, state) => const YieldPredictionScreen(),
      ),
      GoRoute(
        path: '/diagnosis-details',
        builder: (context, state) {
          final record = state.extra as DiagnosisRecord;
          return DiagnosisDetailsScreen(record: record);
        },
      ),
      GoRoute(
        path: AppRouter.yieldDetailsPath,
        builder: (context, state) {
          final record = state.extra as YieldRecord;
          return YieldDetailsScreen(record: record);
        },
      ),
    ],
  );
});

class AppRouter {
  // Route Paths
  static const String loginPath = '/login';
  static const String dashboardPath = '/';
  static const String cropDoctorPath = '/crop-doctor';
  static const String yieldPredictionPath = '/yield-prediction';
  static const String yieldDetailsPath = '/yield-details';
}
