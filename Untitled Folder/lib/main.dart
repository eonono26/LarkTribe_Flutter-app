import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/cart_provider.dart';
import 'services/wishlist_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.init();
  await ApiService.instance.me(); // warms avatar / name if a session exists
  runApp(const LarktribeApp());
}

class LarktribeApp extends StatelessWidget {
  const LarktribeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()..refresh()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()..refresh()),
      ],
      child: MaterialApp(
        title: 'LarkTribe',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // Flutter web can lay out its very first frame in a ~1px-wide
        // viewport while the tab is still sizing, which throws a burst of
        // RenderFlex overflow errors. Give the app a sane minimum layout
        // width (clipped, state preserved) so that frame is harmless.
        builder: (context, child) {
          final w = MediaQuery.of(context).size.width;
          if (w >= 280 || child == null) return child ?? const SizedBox.shrink();
          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: 320,
              maxWidth: 320,
              child: child,
            ),
          );
        },
        home: const MainShell(),
      ),
    );
  }
}
