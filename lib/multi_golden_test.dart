import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liquid_flutter/liquid_flutter.dart';
import 'package:liquid_flutter_test_utils/golden_utils.dart';
import 'package:liquid_flutter_test_utils/widget_tree_test.dart';

typedef GoldenWidgetBuilder = Future<void> Function(
  WidgetTester tester,
  Future<void> Function(Widget widget) placeWidget,
);

/// Helper function to generate golden tests for multiple themes and sizes
/// for multiple widgets of the same scope (e.g. one screen with different
/// states).
Future<void> multiGolden(
  /// The [tester] instance to use for the tests.
  WidgetTester tester,

  /// The name of the golden test.
  String name,

  /// A map of widget builders for various scenarios (e.g. "Default", "Error").
  Map<String, GoldenWidgetBuilder> widgets, {
  /// The [LdFrameOptions] to use for the tests.
  LdFrameOptions ldFrameOptions = const LdFrameOptions(),

  /// Whether to perform widget tree tests as well.
  bool performWidgetTreeTests = true,
}) async {
  debugDisableShadows = false;
  ldDisableAnimations = true;

  // For each scenario, theme size, and brightness ...
  for (final entry in widgets.entries) {
    for (final themeSize in LdThemeSize.values) {
      for (final brightness in Brightness.values) {
        final slug = '${entry.key}/'
            "${themeSize.toString().split(".").last}"
            "-${brightness.toString().split(".").last}";

        await tester.binding.setSurfaceSize(
          Size(
              ldFrameOptions.width.toDouble(),
              ldFrameOptions.height?.toDouble() ??
                  // if height is null, use a 16:9 aspect ratio
                  ldFrameOptions.width.toDouble() / 9 * 16),
        );

        // Place the widget
        await entry.value(tester, (widget) async {
          await tester.pumpWidget(
            ldFrame(
              key: ValueKey(slug),
              child: widget,
              dark: brightness == Brightness.dark,
              size: themeSize,
              ldFrameOptions: ldFrameOptions,
            ),
            duration: Duration(milliseconds: 100),
          );

          if (performWidgetTreeTests) {
            await widgetTreeMatchesGolden(
              tester,
              widget: widget,
              goldenName: '$name/$slug',
            );
          }
        });

        // Generate golden image
        final size =
            find.byKey(ValueKey(slug)).evaluate().single.size ?? Size.zero;
        await tester.pumpAndSettle();
        final heightOffset =
            ldFrameOptions.uiMode == GoldenUiMode.collapsed ? 0 : 64;
        await tester.binding.setSurfaceSize(
          Size(ldFrameOptions.width.toDouble(), size.height + heightOffset),
        );
        tester.view.physicalSize =
            Size(ldFrameOptions.width.toDouble(), size.height + heightOffset);
        await tester.pumpAndSettle();
        await screenMatchesGolden(tester, '$name/$slug');
      }
    }
  }
}
