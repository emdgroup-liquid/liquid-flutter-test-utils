import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liquid_flutter_test_utils/golden_utils.dart';
import 'package:liquid_flutter_test_utils/multi_golden_test.dart';
import 'package:liquid_flutter_test_utils/widget_tree_test.dart';

import '../example/sample_liquid_widget.dart';

void main() {
  setUpAll(() async {
    await setupGoldenTest();
  });

  /// Test the [SampleLiquidWidget] in multiple scenarios and generate golden
  /// images for each scenario, multiple themes, and sizes.
  /// It will also generate the widget tree for each scenario.
  testGoldens("Sample Widget renders correctly in multiple scenarios",
      (tester) async {
    await multiGolden(
      tester,
      "SampleLiquidWidget",
      {
        "Default": (tester, placeWidget) async {
          await placeWidget(SampleLiquidWidget(
            isError: false,
          ));
        },
        "Error": (tester, placeWidget) async {
          await placeWidget(SampleLiquidWidget(
            isError: true,
          ));
        },
      },
      performWidgetTreeTests: true,
      ldFrameOptions: LdFrameOptions(
        expandToScreenSize: false,
      ),
    );
  });

  /// Generate a widget tree for a simple "hello world" widget.
  testGoldens("Arbitrary single widget tree renders correctly", (tester) async {
    const key = ValueKey("HelloWorld");
    final widget = ldThemeWrapper(
      child: Column(
        children: [
          Text(key: key, "Hello World"),
        ],
      ),
    );
    await tester.pumpWidget(widget);
    await widgetTreeMatchesGolden(
      tester,
      widget: widget,
      findWidget: (tester, widget) => find.byKey(key),
      goldenName: "HelloWorldWidgetTree",
    );
  });
}
