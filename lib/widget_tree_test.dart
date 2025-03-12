import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

final Set<dynamic> defaultIgnoredWidgets = {
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

class WidgetTreeNode {
  WidgetTreeNode(this.widget, this.children);
  Widget widget;
  List<WidgetTreeNode> children;

  String toXmlString([int indent = 0]) {
    final indentStr = '  ' * indent;
    final tag =
        widget.runtimeType.toString().replaceAll('<', '-').replaceAll('>', '');
    final attrs = widget.toDiagnosticsNode().getProperties().map(
      (property) {
        final name = property.name;
        final value = property.value;
        if (value == null) return '';
        return ' $name="$value"';
      },
    ).join();

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
  Finder Function(WidgetTester, Widget)? findWidget,
  String? goldenName,
  bool? update,
  Set<dynamic>? ignoredWidgets,
}) async {
  update ??= autoUpdateGoldenFiles;
  goldenName ??= widget.runtimeType.toString();

  final testTree = createWidgetTree(
    tester.element(findWidget?.call(tester, widget) ?? find.byWidget(widget)),
    ignoredWidgets: ignoredWidgets ?? defaultIgnoredWidgets,
    ignoredWidgets: (ignoredWidgets ?? defaultIgnoredWidgets)
        .map((e) => e.toString())
        .toSet(),
    ignorePrivateWidgets: true,
  );

  // strip all information from the tree that is not relevant for the comparison
  // e.g. hash codes, keys, etc. that change between test runs
  final testTreeStripped = testTree?.toXmlString() ?? '';

  final goldenFile = File(
    path.join(Directory('test/golden_widget_trees').path, '$goldenName.xml'),
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

WidgetTreeNode? createWidgetTree(
  Element e, {
  required Set<dynamic> ignoredWidgets,
  required Set<String> ignoredWidgets,
  required bool ignorePrivateWidgets,
}) {
  final widget = e.widget;
  final children = <WidgetTreeNode>[];

  e.visitChildren((element) {
    final child = createWidgetTree(
      element,
      ignoredWidgets: ignoredWidgets,
      ignorePrivateWidgets: ignorePrivateWidgets,
    );
    if (child != null) children.add(child);
  });

  final type = widget.runtimeType.toString().split('<').first;
  final type = widget.runtimeType.toString();
  final typeWithoutGeneric = type.split('<').first;
  if (ignoredWidgets.contains(type) ||
      ignoredWidgets.contains(typeWithoutGeneric) ||
      ignorePrivateWidgets && type.startsWith('_')) {
    if (children.isNotEmpty) {
      return children.length == 1
          ? children.first
          : WidgetTreeNode(widget, children);
    } else {
      return null;
    }
  }

  return WidgetTreeNode(widget, children);
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
