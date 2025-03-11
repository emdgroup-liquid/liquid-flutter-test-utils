# liquid-flutter-test-utils

A Flutter package providing utilities for testing Liquid Flutter widgets, including golden image testing and widget tree verification.

It is intertwined with the [Liquid Flutter](https://pub.dev/packages/liquid_flutter) component library and the [Golden Toolkit](https://pub.dev/packages/golden_toolkit)
package for golden image testing.

## Features

- **Golden Image Testing**: Generate screenshot-like golden images for UI verification.
- **Widget Tree Testing**: Capture and verify the widget tree structure.
- **Multi-Theme Testing**: Test widgets across different Liquid theme sizes and brightness modes.
- **Flexible Frame Options**: Control how widgets are framed for testing.

## Installation

Add this package to your development dependencies running:

```bash
flutter pub add liquid_flutter_test_utils
```

## Getting Started

### Setup

Initialize the golden test environment in your test file:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liquid_flutter_test_utils/golden_utils.dart';

void main() {
  setUpAll(() async {
    await setupGoldenTest();
  });
  
  // Your tests go here
}
```

### Basic Golden Image Testing

Test a widget and generate golden images across all Liquid theme variations:

```dart
import 'package:liquid_flutter_test_utils/multi_golden_test.dart';

testGoldens("Widget renders correctly", (tester) async {
  final widget = YourWidget();
  
  await multiGolden(
    tester,
    "YourWidget",
    {
      "Default": (tester, placeWidget) async {
        await placeWidget(widget);
      },
    },
  );
});
```

### Testing Multiple States

Test a widget in different states:

```dart
testGoldens("Widget renders correctly in multiple states", (tester) async {
  await multiGolden(
    tester,
    "YourWidget",
    {
      "Loading": (tester, placeWidget) async {
        await placeWidget(YourWidget(isLoading: true));
      },
      "Loaded": (tester, placeWidget) async {
        await placeWidget(YourWidget(isLoading: false, data: sampleData));
      },
      "Error": (tester, placeWidget) async {
        await placeWidget(YourWidget(hasError: true));
      },
    },
  );
});
```

### Widget Tree Testing

Verify the widget tree structure of your widget:

```dart
import 'package:liquid_flutter_test_utils/widget_tree_test.dart';

testGoldens("Widget tree matches expected structure", (tester) async {
  const key = ValueKey("MyWidget");
  final widget = ldThemeWrapper(
    child: YourWidget(key: key),
  );
  
  await tester.pumpWidget(widget);
  
  await widgetTreeMatchesGolden(
    tester,
    widget: widget,
    findWidget: (tester, widget) => find.byKey(key),
    goldenName: "YourWidgetTree",
  );
});
```

### Configuring Golden Tests

Customize how widgets are framed for testing:

```dart
await multiGolden(
  tester,
  "YourWidget",
  {
    "Default": (tester, placeWidget) async {
      await placeWidget(YourWidget());
    },
  },
  performWidgetTreeTests: true, // Generate widget tree goldens
  ldFrameOptions: LiquidFrameOptions(
    expandToScreenSize: false, // Only use the space needed by the widget
    width: 800, // Set custom width
  ),
);
```

## Advanced Features

### Custom Threshold for Image Comparison

Specify a threshold for image comparison to tolerate minor pixel differences:

```dart
await setupGoldenTest(
  fileComparatorThreshold: 0.02, // Accept up to 2% difference
);
```

### Custom Localizations

Provide custom localization delegates:

```dart
await setupGoldenTest(
  localizationsDelegates: [
    YourCustomLocalizationsDelegate(),
  ],
);
```

### Testing with Specific LdTheme Settings

Wrap your widget with a custom theme wrapper:

```dart
final themedWidget = ldThemeWrapper(
  brightnessMode: LdThemeBrightnessMode.dark,
  size: LdThemeSize.large,
  child: YourWidget(),
);
```

## Widget Tree Testing Details

The widget tree testing functionality captures the structure of your widget tree in an XML format, ignoring implementation details like hash codes and internal widgets. This helps you catch unexpected structural changes in your widgets.

### Customizing Ignored Widgets

You can customize which widgets are ignored during widget tree capture:

```dart
await widgetTreeMatchesGolden(
  tester,
  widget: widget,
  ignoredWidgets: {
    MediaQuery,
    Material,
    // Add other widgets to ignore
  }.map((w) => w.toString().split('<').first).toSet(), // Strip generic types
);
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.