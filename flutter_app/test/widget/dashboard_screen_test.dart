import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/dashboard/presentation/farmer_dashboard_screen.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/weather_card.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/action_card.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/recent_activity_list.dart';

/// Widget Tests for Farmer Dashboard Screen
/// 
/// Tests the dashboard UI rendering and navigation.
void main() {
  group('FarmerDashboardScreen Widget Tests', () {
    testWidgets('should display weather card', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: FarmerDashboardScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Weather card content
      expect(find.text('Namakkal, Tamil Nadu'), findsOneWidget);
      expect(find.text('28°'), findsOneWidget);
      expect(find.text('Sunny'), findsOneWidget);
    });

    testWidgets('should display AI Agri Tools section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: FarmerDashboardScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      expect(find.text('AI Agri Tools'), findsOneWidget);
      expect(find.text('Crop Doctor'), findsOneWidget);
      expect(find.text('Yield Predictor'), findsOneWidget);
      expect(find.text('Market Prices'), findsOneWidget);
      expect(find.text('Expert Help'), findsOneWidget);
    });

    testWidgets('should display recent activity section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: FarmerDashboardScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('No recent scans'), findsOneWidget);
    });

    testWidgets('should have profile icon button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: FarmerDashboardScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  // group('WeatherCard Widget Tests', () {
  //   testWidgets('should render weather information', (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Scaffold(
  //           body: WeatherCard(location: 'Namakkal, Tamil Nadu'),
  //         ),
  //       ),
  //     );
  //
  //     expect(find.text('Namakkal, Tamil Nadu'), findsOneWidget);
  //     expect(find.text('28°'), findsOneWidget);
  //     expect(find.text('Sunny'), findsOneWidget);
  //     expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
  //   });
  // });

  group('ActionCard Widget Tests', () {
    testWidgets('should render action card with title and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionCard(
              title: 'Test Action',
              icon: Icons.check,
              color: Colors.blue,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Action'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('should be tappable', (tester) async {
      var tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionCard(
              title: 'Test Action',
              icon: Icons.check,
              color: Colors.blue,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ActionCard));
      expect(tapped, isTrue);
    });
  });

  group('RecentActivityList Widget Tests', () {
    testWidgets('should show empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RecentActivityList(),
          ),
        ),
      );

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('No recent scans'), findsOneWidget);
      expect(find.byIcon(Icons.history_edu), findsOneWidget);
    });
  });
}
