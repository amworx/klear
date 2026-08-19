// Regression: wide English labels in the bottom nav must render on one line,
// without RenderFlex overflow, and without ellipsis truncation.
//
// Bug: the selected pill's label used to wrap into stacked lines ("vertical
// text") because the pill was width-constrained by its slot. Fixed by letting
// the pill grow beyond its slot (OverflowBox) + a Flexible single-line label.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:klear/app/widgets/klear_bottom_nav_bar.dart';
import 'package:klear/core/theme/app_theme.dart';

void main() {
  for (final width in [320.0, 360.0, 411.0]) {
    testWidgets('long English labels: one line, no overflow, no truncation '
        '($width)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Scaffold(
                body: KlearBottomNavBar(
                  currentIndex: 2, // "My Orders" selected = longest label
                  onDestinationSelected: (_) {},
                  destinations: const [
                    KlearNavDestination(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'Home',
                    ),
                    KlearNavDestination(
                      icon: Icons.local_car_wash_outlined,
                      selectedIcon: Icons.local_car_wash,
                      label: 'Services',
                    ),
                    KlearNavDestination(
                      icon: Icons.receipt_long_outlined,
                      selectedIcon: Icons.receipt_long,
                      label: 'My Orders',
                    ),
                    KlearNavDestination(
                      icon: Icons.person_outline,
                      selectedIcon: Icons.person,
                      label: 'Account',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No RenderFlex overflow exceptions.
      expect(tester.takeException(), isNull);

      // The selected label renders on exactly one line (a wrapped label
      // would be ~2x the single labelLarge line height of ~20px).
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('My Orders'),
      );
      expect(paragraph.size.height, lessThan(30));

      // "My Orders" must be fully visible — never ellipsized.
      final intrinsic = TextPainter(
        text: const TextSpan(
          text: 'My Orders',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      debugPrint(
        'width=$width paragraph=${paragraph.size} '
        'intrinsic=${intrinsic.width} exceed=${paragraph.didExceedMaxLines}',
      );
      expect(paragraph.didExceedMaxLines, isFalse);
    });
  }
}