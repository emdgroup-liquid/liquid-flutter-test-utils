import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liquid_flutter/liquid_flutter.dart';
import 'package:liquid_flutter_test_utils/golden_utils.dart';
import 'package:liquid_flutter_test_utils/widget_tree_test.dart';

enum Orientation {
  portrait,
  landscape,
}

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

  /// The [ThemeSize] scenarios to test.
  List<LdThemeSize> themeSizeScenarios = LdThemeSize.values,

  /// The [Brightness] scenarios to test.
  List<Brightness> brightnessScenarios = Brightness.values,

  /// The [Orientation] scenarios to test.
  List<Orientation> orientationScenarios = const [Orientation.portrait],
}) async {
  debugDisableShadows = false;
  ldDisableAnimations = true;

  // Track if any test fails
  List<String> failureMessages = [];

  // For each scenario, theme size, and brightness ...
  for (final entry in widgets.entries) {
    for (final themeSize in themeSizeScenarios) {
      for (final brightness in brightnessScenarios) {
        for (final orientation in orientationScenarios) {
          final slug = "${entry.key}/${[
            if (themeSizeScenarios.length > 1)
              themeSize.toString().split(".").last,
            if (brightnessScenarios.length > 1)
              brightness.toString().split(".").last,
            if (orientationScenarios.length > 1)
              orientation.toString().split(".").last,
          ].join("-")}";

          var width = ldFrameOptions.width.toDouble();
          var height = ldFrameOptions.height?.toDouble() ??
              // if height is null, use a 16:9 aspect ratio
              ldFrameOptions.width.toDouble() / 9 * 16;
          if (orientation == Orientation.landscape) {
            width = height;
            height = ldFrameOptions.width.toDouble();
          }
          await tester.binding.setSurfaceSize(Size(width, height));

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
              try {
                await widgetTreeMatchesGolden(
                  tester,
                  widget: widget,
                  options: WidgetTreeOptions(goldenName: '$name/$slug'),
                );
              } catch (e) {
                failureMessages.add(
                    'Widget tree test failed for $name/$slug: ${e.toString()}');
              }
            }
          });

          // Generate golden image
          final size =
              find.byKey(ValueKey(slug)).evaluate().single.size ?? Size.zero;
          await tester.pumpAndSettle();
          final heightOffset =
              ldFrameOptions.uiMode == GoldenUiMode.collapsed ? 0 : 64;
          await tester.binding.setSurfaceSize(
            Size(
              width,
              size.height + heightOffset,
            ),
          );
          tester.view.physicalSize = Size(width, size.height + heightOffset);
          await tester.pumpAndSettle();

          try {
            await screenMatchesGolden(tester, '$name/$slug');
          } catch (e) {
            failureMessages.add(
                'Screen matching golden failed for $name/$slug: ${e.toString()}');
          }
        }
      }
    }
  }

  // After all tests have been executed, fail if any test failed
  if (failureMessages.isNotEmpty) {
    throw Exception(
      'One or more golden tests failed:\n${failureMessages.join('\n')}',
    );
  }
}
