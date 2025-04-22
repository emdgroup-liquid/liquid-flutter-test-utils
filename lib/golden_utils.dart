import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liquid_flutter/liquid_flutter.dart';
import 'package:liquid_flutter_test_utils/gen/fonts.gen.dart';
import 'package:liquid_flutter_test_utils/local_file_comparator_with_threshold.dart';

/// The localizations delegates to be used in golden tests.
List<LocalizationsDelegate> ldGoldenLocalizationsDelegates = [];

enum GoldenUiMode {
  collapsed,
  screen,
  screenWithSystemUi,
}

/// Options for the [ldFrame] widget.
class LdFrameOptions {
  final int width;
  final int? height;
  final GoldenUiMode uiMode;
  final bool showBackButton;

  const LdFrameOptions({
    /// The width of the frame.
    this.width = 600,

    /// The height of the frame. If null, the height will be adjusted to fit the
    /// widget or the screen size.
    this.height,

    /// Whether the frame should only be in size of the widget or in size of the
    /// screen (with or without system UI).
    this.uiMode = GoldenUiMode.screenWithSystemUi,

    /// Whether the app bar should show a back button. This is helpful for
    /// generating screenshots for screens that are usually on a sub-route.
    this.showBackButton = false,
  }) : assert(!(uiMode == GoldenUiMode.collapsed && height != null));
}

/// Wraps the [child] with a [LdThemeProvider] and [Localizations] widget as
/// required by the Liquid Design System.
Widget ldThemeWrapper({
  LdThemeBrightnessMode brightnessMode = LdThemeBrightnessMode.auto,
  LdThemeSize? size,
  List<LocalizationsDelegate> localizationsDelegates = const [],
  required Widget child,
}) {
  final theme = LdTheme();
  if (size != null) {
    theme.setThemeSize(size);
  }
  return Localizations(
    delegates: [
      ...localizationsDelegates,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      LiquidLocalizations.delegate,
    ],
    locale: const Locale('en'),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: LdThemeProvider(
        theme: theme,
        autoSize: size == null,
        brightnessMode: brightnessMode,
        child: child,
      ),
    ),
  );
}

/// Setup the golden test environment.
Future<void> setupGoldenTest({
  /// The localizations delegates to be used in golden tests.
  List<LocalizationsDelegate> localizationsDelegates = const [],

  /// The threshold for the golden file comparator.
  /// Must be between 0 and 1.
  double fileComparatorThreshold = 0.05, // gracefully accept 5% difference
}) async {
  assert(fileComparatorThreshold >= 0 && fileComparatorThreshold <= 1);

  ldGoldenLocalizationsDelegates = [
    ...localizationsDelegates,
  ];

  // Ensure the binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Setup the golden file comparator
  const directory = 'test/goldens';
  goldenFileComparator = LocalFileComparatorWithThreshold(
      Uri.directory(directory), fileComparatorThreshold);

  // Load the fonts
  await loadAppFonts();
  final fonts = <String, String>{
    FontFamily.lato: 'packages/liquid_flutter/fonts/Lato-Regular.ttf',
  };
  for (final entry in fonts.entries) {
    final fontLoader = FontLoader(entry.key)
      ..addFont(rootBundle.load(entry.value));
    await fontLoader.load();
  }
}

/// Create a frame for a widget to be used in golden tests.
Widget ldFrame({
  required Key key,
  required Widget child,
  required bool dark,
  required LdThemeSize size,
  required LdFrameOptions ldFrameOptions,
}) {
  GoRouter router(Function(BuildContext, GoRouterState) app) {
    return GoRouter(
      initialLocation: ldFrameOptions.showBackButton ? '/child' : '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => app(context, state),
          routes: [
            GoRoute(
              path: 'child',
              builder: (context, state) => app(context, state),
            ),
          ],
        ),
      ],
    );
  }

  return KeyedSubtree(
    // force a new subtree each time a new frame is created in order to avoid
    // state issues
    key: UniqueKey(),
    child: ldThemeWrapper(
      size: size,
      brightnessMode:
          dark ? LdThemeBrightnessMode.dark : LdThemeBrightnessMode.light,
      child: LdPortal(
        child: LdThemedAppBuilder(
          appBuilder: (context, theme) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: theme,
            locale: LiquidLocalizations.supportedLocales.first,
            supportedLocales: LiquidLocalizations.supportedLocales,
            localizationsDelegates: [
              ...ldGoldenLocalizationsDelegates,
              ...LiquidLocalizations.localizationsDelegates,
            ],
            routerConfig: router((context, state) {
              // ignore: invalid_use_of_visible_for_testing_member
              final SystemUiOverlayStyle uiStyle = SystemChrome.latestStyle ??
                  (dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark);
              // debugPrintStack();
              return Scaffold(
                body: Column(
                  key: key,
                  mainAxisSize: ldFrameOptions.uiMode != GoldenUiMode.collapsed
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  children: [
                    if (ldFrameOptions.uiMode ==
                        GoldenUiMode.screenWithSystemUi)
                      StatusBar(style: uiStyle),
                    Flexible(
                      flex: ldFrameOptions.uiMode == GoldenUiMode.collapsed
                          ? 0
                          : 1,
                      child: child,
                    ),
                    if (ldFrameOptions.uiMode ==
                        GoldenUiMode.screenWithSystemUi)
                      HomeIndicator(style: uiStyle),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    ),
  );
}

class HomeIndicator extends StatelessWidget {
  const HomeIndicator({required this.style, super.key});
  final SystemUiOverlayStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 16),
      color: style.systemNavigationBarColor,
      width: double.infinity,
      child: SvgPicture.asset(
        fit: BoxFit.fitWidth,
        style.systemNavigationBarIconBrightness == Brightness.light
            ? 'assets/home_indicator_light.svg'
            : 'assets/home_indicator_dark.svg',
      ),
    );
  }
}

class StatusBar extends StatelessWidget {
  const StatusBar({required this.style, super.key});
  final SystemUiOverlayStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 16),
      color: style.statusBarColor,
      width: double.infinity,
      child: SvgPicture.asset(
        fit: BoxFit.fitWidth,
        style.statusBarIconBrightness == Brightness.light
            ? 'assets/status_bar_light.svg'
            : 'assets/status_bar_dark.svg',
      ),
    );
  }
}
