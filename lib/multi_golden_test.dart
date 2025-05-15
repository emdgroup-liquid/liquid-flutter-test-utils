import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liquid_flutter/liquid_flutter.dart';
import 'package:liquid_flutter_test_utils/ld_frame_options.dart';
import 'package:liquid_flutter_test_utils/ld_frame.dart';
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

  /// The [ThemeSize] scenarios to test.
  List<LdThemeSize> themeSizeScenarios = LdThemeSize.values,

  /// The [Brightness] scenarios to test.
  List<Brightness> brightnessScenarios = Brightness.values,

  /// The [Orientation] scenarios to test.
  List<Orientation> orientationScenarios = const [Orientation.portrait],

  /// Whether to clip the screen to the screen radius.
  bool clipScreenToRadius = false,
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

          // Apply device pixel ratio from ldFrameOptions
          tester.view.devicePixelRatio = ldFrameOptions.devicePixelRatio;

          // If we dont have a specified height, we start as a square
          Size size = Size(
            ldFrameOptions.width,
            ldFrameOptions.height ?? ldFrameOptions.width,
          );

          if (orientation == Orientation.landscape) {
            size = Size(size.height, size.width);
          }

          final key = ValueKey(slug);

          // Place the widget
          await entry.value(tester, (widget) async {
            final frame = ClipRRect(
              borderRadius: BorderRadius.circular(
                clipScreenToRadius ? ldFrameOptions.screenRadius ?? 0 : 0,
              ),
              child: ldFrame(
                key: key,
                child: widget,
                dark: brightness == Brightness.dark,
                size: themeSize,
                ldFrameOptions: ldFrameOptions,
                orientation: orientation,
              ),
            );

            // If we dont have a specified height, we need to wrap the frame in a
            // SingleChildScrollView to allow the frame to grow. We will
            // automatically detect the size of the widget later.
            if (ldFrameOptions.height == null) {
              await tester.pumpWidget(
                SingleChildScrollView(
                  child: IntrinsicWidth(
                    child: frame,
                  ),
                ),
                duration: Duration(milliseconds: 100),
              );
            } else {
              await tester.pumpWidget(
                frame,
                duration: Duration(milliseconds: 100),
              );
            }

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

          await tester.pumpAndSettle();

          if (ldFrameOptions.height == null) {
            size = find.byKey(key).evaluate().first.size!;
          }

          await tester.binding.setSurfaceSize(
            Size(size.width, size.height),
          );

          tester.view.physicalSize = Size(
            size.width,
            (size.height),
          );

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
