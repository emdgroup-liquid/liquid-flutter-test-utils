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
    uiMode: GoldenUiMode.collapsed, // Only show the widget (no screenshot-like frame)
    width: 800, // Set custom width
  ),
);
```

## Generated Golden Files

When running the tests, the package generates golden images for all combinations of theme sizes and brightness modes. The files follow this structure:

```
test/goldens/
└── SampleLiquidWidget/
    ├── Default/
    │   ├── l-dark.png   # Large theme size, dark mode
    │   ├── l-light.png  # Large theme size, light mode
    │   ├── m-dark.png   # Medium theme size, dark mode
    │   ├── m-light.png  # Medium theme size, light mode
    │   ├── s-dark.png   # Small theme size, dark mode
    │   └── s-light.png  # Small theme size, light mode
    └── Error/
        ├── l-dark.png
        ├── l-light.png
        ├── m-dark.png
        ├── m-light.png
        ├── s-dark.png
        └── s-light.png
```
Each state of your widget (e.g., "Default", "Error") gets its own directory containing all theme variations.

Here are some example generated golden images that were generated for `SampleLiquidWidget`:

| Theme       | Dark Mode                                                 | Light Mode                                                 |
|-------------|-----------------------------------------------------------|------------------------------------------------------------|
| **Large**   | ![](./test/goldens/SampleLiquidWidget/Default/l-dark.png) | ![](./test/goldens/SampleLiquidWidget/Default/l-light.png) |
| **Medium**  | ![](./test/goldens/SampleLiquidWidget/Default/m-dark.png) | ![](./test/goldens/SampleLiquidWidget/Default/m-light.png) |
| **Small**   | ![](./test/goldens/SampleLiquidWidget/Default/s-dark.png) | ![](./test/goldens/SampleLiquidWidget/Default/s-light.png) |

## Advanced Features

### Frame Options

The `LdFrameOptions` class is used to configure options for the [ldFrame] widget. It provides flexibility in defining the size, UI mode, and other settings for generating screenshots or UI frames. Below are the details of the class and its parameters.

#### UI Mode

The `GoldenUiMode` enum defines the available modes for how the frame should be sized. It has three possible values:

- `collapsed`: The frame will be sized to match the widget's size.
- `screen`: The frame will match the screen's size (including system UI).
- `screenWithSystemUi`: Similar to `screen`, but includes the system UI as well.

#### `LdFrameOptions` Constructor

The `LdFrameOptions` constructor allows you to configure the widget frame with the following parameters:

| Parameter           | Type               | Default Value                     | Description                                                                                                 |
|---------------------|--------------------|-----------------------------------|-------------------------------------------------------------------------------------------------------------|
| `width`             | `int`              | `600`                             | The width of the frame.                                                                                     |
| `height`            | `int?`             | `null`                            | The height of the frame. If `null`, the height will adjust to fit the widget or screen size.                |
| `uiMode`            | `GoldenUiMode`     | `GoldenUiMode.screenWithSystemUi` | Defines how the frame should be sized (collapsed, screen, or screenWithSystemUi).                   |
| `showBackButton`    | `bool`             | `false`                           | Whether the app bar should show a back button. Useful for generating screenshots for screens on sub-routes. |
  

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
    // You can use types or strings:
    'NotificationListener', // Ignore all NotificationListener widgets, no matter the generic type
    // For generic types, you could also specify the generic type arguments:
    NotificationListener<ScrollNotification>,
    // Add other widgets to ignore
  },
);
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.