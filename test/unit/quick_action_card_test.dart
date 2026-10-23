import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_sos/widgets/quick_action_card.dart';
import 'package:emergency_sos/utils/app_theme.dart';

void main() {
  testWidgets('QuickActionCard renders title, subtitle, icon and triggers onTap',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              height: 120,
              child: QuickActionCard(
                icon: Icons.phone_forwarded_rounded,
                title: 'Call Contact',
                subtitle: 'Primary ICE',
                color: AppTheme.sosRed,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Call Contact'), findsOneWidget);
    expect(find.text('Primary ICE'), findsOneWidget);
    expect(find.byIcon(Icons.phone_forwarded_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await tester.tap(find.byType(QuickActionCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('QuickActionCard 2x2 grid fits in standard mobile screen width (360px)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.phone_forwarded_rounded,
                          title: 'Call Contact',
                          subtitle: 'Primary ICE',
                          color: AppTheme.sosRed,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.notification_important_rounded,
                          title: 'Send SOS',
                          subtitle: 'Alert Contacts',
                          color: AppTheme.sosRedDark,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.share_location_rounded,
                          title: 'Share Location',
                          subtitle: 'Live Tracking',
                          color: AppTheme.medicalBlue,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.medical_information_rounded,
                          title: 'Medical Card',
                          subtitle: 'Offline View',
                          color: AppTheme.successGreen,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Call Contact'), findsOneWidget);
    expect(find.text('Send SOS'), findsOneWidget);
    expect(find.text('Share Location'), findsOneWidget);
    expect(find.text('Medical Card'), findsOneWidget);
  });

  testWidgets('QuickActionCard handles narrow screen (320px) and dark mode without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.phone_forwarded_rounded,
                          title: 'Call Contact',
                          subtitle: 'Alexander Hamilton',
                          color: AppTheme.sosRed,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.notification_important_rounded,
                          title: 'Send SOS',
                          subtitle: 'Alert Contacts',
                          color: AppTheme.sosRedDark,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Call Contact'), findsOneWidget);
  });
}
