import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LdFrameOptions {
  final EdgeInsets viewPaddig;
  final Widget Function(
    BuildContext context,
    Orientation orientation,
    Widget child,
    bool dark,
    SystemUiOverlayStyle navigationBarStyle,
  )? build;

  final double width;
  final double? height;
  final double? screenRadius;
  final double devicePixelRatio;
  final bool showBackButton;
  const LdFrameOptions({
    this.viewPaddig = EdgeInsets.zero,
    this.build,
    this.width = 500,
    this.height,
    this.devicePixelRatio = 1.0,
    this.showBackButton = false,
    this.screenRadius,
  });
}
