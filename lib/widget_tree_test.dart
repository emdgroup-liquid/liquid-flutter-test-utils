import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

const Set<dynamic> defaultIgnoredWidgets = {
  MediaQuery,
  Material,
  AnimatedDefaultTextStyle,
  DefaultTextStyle,
  PhysicalModel,
  AnimatedPhysicalModel,
  Semantics,
  Actions,
  'NotificationListener',
  Focus,
  'Provider',
  KeyedSubtree,
  MouseRegion,
  Builder,
};

enum IncludeWidgetBounds {
  none,
  relative,
  absolute,
}

class WidgetTreeOptions {
  const WidgetTreeOptions({
    /// A function to find the widget to create the tree for. If not provided,
    /// the widget passed to [widgetTreeMatchesGolden] will be used.
    this.findWidget,

    /// The path to the golden directory. If not provided,
    /// 'test/golden_widget_trees' will be used.
    this.goldenPath = 'test/golden_widget_trees',

    /// The name of the golden file to compare with. If not provided, the name
    /// of the widget will be used.
    this.goldenName,

    /// A set of widgets to strip from the tree (in order to produce a less
    /// verbose tree). If not provided, a default set of widgets will be
    /// used, cf. [defaultIgnoredWidgets].
    this.strippedWidgets = defaultIgnoredWidgets,

    /// Whether to strip away private widgets (i.e. widgets starting with '_').
    /// Defaults to true.
    this.stripPrivateWidgets = true,

    /// Whether to include the bounds of the widgets in the tree. If set to
    /// [IncludeWidgetBounds.relative], the bounds will be relative to the
    /// parent widget. If set to [IncludeWidgetBounds.absolute], the bounds
    /// will be absolute on the screen. If set to [IncludeWidgetBounds.none],
    /// the bounds will not be included.
    this.includeWidgetBounds = IncludeWidgetBounds.relative,
  });

  final Finder Function(WidgetTester, Widget)? findWidget;
  final String goldenPath;
  final String? goldenName;
  final Set<dynamic> strippedWidgets;
  final bool stripPrivateWidgets;
  final IncludeWidgetBounds includeWidgetBounds;
}

/// A node in the widget tree.
class WidgetTreeNode {
  WidgetTreeNode(this.widget, this.children, {this.bounds});
  Widget widget;
  Rect? bounds;
  List<WidgetTreeNode> children;

  String toXmlString([int indent = 0]) {
    final indentStr = '  ' * indent;
    final tag =
        widget.runtimeType.toString().replaceAll('<', '-').replaceAll('>', '');
    // associate properties with their values
    Map<String, dynamic> props = {
      for (var p in widget.toDiagnosticsNode().getProperties())
        if (p.name != null && p.value != null)
          p.name!: p.value
              .toString()
              .replaceAll('"', "'")
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim(),
    };
    final attrs = [
      ...props.entries.map((e) => ' ${e.key}="${e.value}"'),
      if (bounds != null) ...[
        if (!props.containsKey("left")) ' left="${bounds!.left}"',
        if (!props.containsKey("top")) ' top="${bounds!.top}"',
        if (!props.containsKey("width")) ' width="${bounds!.width}"',
        if (!props.containsKey("height")) ' height="${bounds!.height}"',
      ]
    ].join('');

    final content = children.isEmpty
        ? ''
        : [
              '',
              ...children.map((child) => child.toXmlString(indent + 1)),
              '',
            ].join('\n') +
            indentStr;
    final slash = children.isEmpty ? ' /' : '';
    final closingTag = children.isEmpty ? '' : '</$tag>';
    final result = '$indentStr<$tag$attrs$slash>$content$closingTag'
        // replace UID hash codes with a generic placeholder
        .replaceAllMapped(RegExp(r'([a-zA-Z_]+)#[0-9a-fA-F]+'),
            (match) => '${match.group(1)}#HASH');
    return result;
  }
}

/// Wrapper for widget tree testing
Future<void> widgetTreeMatchesGolden(
  WidgetTester tester, {
  required Widget widget,
  WidgetTreeOptions options = const WidgetTreeOptions(),
  bool? update,
}) async {
  update ??= autoUpdateGoldenFiles;
  final goldenName = options.goldenName ?? widget.runtimeType.toString();

  final testTree = createWidgetTree(
    tester.element(
        options.findWidget?.call(tester, widget) ?? find.byWidget(widget)),
    tester: tester,
    options: options,
  );

  // strip all information from the tree that is not relevant for the comparison
  // e.g. hash codes, keys, etc. that change between test runs
  final testTreeStripped = testTree?.toXmlString() ?? '';

  final goldenFile = File(
    path.join(Directory(options.goldenPath).path, '$goldenName.xml'),
  );

  // Create the golden directory if it does not exist
  final goldenSubDir = goldenFile.parent;
  if (!goldenSubDir.existsSync()) {
    goldenSubDir.createSync(recursive: true);
  }

  if (update || !goldenFile.existsSync()) {
    // Update or create the golden file
    goldenFile.writeAsStringSync(testTreeStripped);
  } else {
    // Compare with existing golden
    final goldenTree = goldenFile.readAsStringSync();

    expectWidgetTrees(
      testTreeStripped,
      goldenTree,
      reason: 'Golden widget tree file mismatch: ${goldenFile.path}',
    );
  }
}

/// Recursively creates a widget tree from the given element.
WidgetTreeNode? createWidgetTree(
  Element e, {
  required WidgetTester tester,
  required WidgetTreeOptions options,
}) {
  final widget = e.widget;
  final children = <WidgetTreeNode>[];

  e.visitChildren((element) {
    final child = createWidgetTree(
      element,
      tester: tester,
      options: options,
    );
    if (child != null) children.add(child);
  });

  final type = widget.runtimeType.toString();
  final typeWithoutGeneric = type.split('<').first;
  final bounds = switch (options.includeWidgetBounds) {
    IncludeWidgetBounds.none => null,
    IncludeWidgetBounds.relative => () {
        final renderObject = e.renderObject;
        if (renderObject is RenderBox) {
          final pos = renderObject.localToGlobal(Offset.zero,
              ancestor: e.renderObject?.parent);
          return Rect.fromLTWH(
            pos.dx,
            pos.dy,
            renderObject.size.width,
            renderObject.size.height,
          );
        }

        if (renderObject is RenderSliverList) {
          // We cannot just get the bounds of the RenderSliverList
          final constraints = renderObject.constraints;

          // Get the SliverGeometry which contains positioning info
          final geometry = renderObject.geometry;

          if (geometry != null && !geometry.visible) {
            // If the sliver is not visible, return null or an empty rect
            return null;
          }

          // Calculate the bounds based on paintOrigin and paintExtent
          return Rect.fromLTWH(
            constraints.axis == Axis.vertical ? 0 : geometry!.paintOrigin,
            constraints.axis == Axis.vertical ? geometry!.paintOrigin : 0,
            constraints.axis == Axis.vertical
                ? constraints.crossAxisExtent
                : geometry!.paintExtent,
            constraints.axis == Axis.vertical
                ? geometry!.paintExtent
                : constraints.crossAxisExtent,
          );
        }

        return null;
      }(),
    IncludeWidgetBounds.absolute =>
      tester.getRect(find.byElementPredicate((el) => el == e)),
  };
  if (options.strippedWidgets.contains(type) ||
      options.strippedWidgets.contains(typeWithoutGeneric) ||
      (options.stripPrivateWidgets && type.startsWith('_'))) {
    if (children.isNotEmpty) {
      return children.length == 1
          ? children.first
          : WidgetTreeNode(widget, children, bounds: bounds);
    } else {
      return null;
    }
  }

  return WidgetTreeNode(widget, children, bounds: bounds);
}

/// ANSI escape codes for color highlighting
const String red = '\u001b[31m'; // Red color
const String reset = '\u001b[0m'; // Reset color

/// Finds the first difference between two strings and highlights it in red.
void expectWidgetTrees(String actual, String expected, {String? reason}) {
  final expectedLines = expected.split('\n');
  final actualLines = actual.split('\n');

  for (var i = 0; i < expectedLines.length && i < actualLines.length; i++) {
    if (expectedLines[i] != actualLines[i]) {
      final highlightedExpected =
          _highlightDifference(expectedLines[i], actualLines[i]);
      final highlightedActual =
          _highlightDifference(actualLines[i], expectedLines[i]);

      throw TestFailure('''
Widget tree does not match:
${reason ?? ''}
Difference at line ${i + 1}:

Expected: $highlightedExpected

Actual  : $highlightedActual
''');
    }
  }

  if (expectedLines.length != actualLines.length) {
    throw TestFailure('''
Widget tree does not match:
${reason ?? ''}
Difference in number of lines:
Expected ${expectedLines.length} lines, but got ${actualLines.length}
''');
  }
}

/// Highlights the first character difference in red.
String _highlightDifference(String line1, String line2) {
  final diffIndex = _findFirstDifference(line1, line2);
  if (diffIndex == -1) return line1; // No difference found

  return line1.substring(0, diffIndex) +
      red +
      line1.substring(diffIndex, diffIndex + 1) +
      reset +
      line1.substring(diffIndex + 1);
}

/// Finds the first index where two strings differ.
int _findFirstDifference(String a, String b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    if (a[i] != b[i]) return i;
  }
  return (a.length != b.length) ? a.length : -1;
}
