import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:collabsme/core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'core/constants/app_constants.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/auth/accept_invitation_screen.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';

void main() {
  usePathUrlStrategy();
  runZonedGuarded(() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}\n${details.stack}');
    };
    runApp(const ProviderScope(child: CollabSMEApp()));
  }, (error, stack) {
    debugPrint('Unhandled Error: $error\n$stack');
  });
}

class CollabSMEApp extends ConsumerStatefulWidget {
  const CollabSMEApp({super.key});

  @override
  ConsumerState<CollabSMEApp> createState() => _CollabSMEAppState();
}

class _CollabSMEAppState extends ConsumerState<CollabSMEApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      debugPrint('DeepLink: initial=$initialUri');
      if (initialUri != null) {
        _navigateDeepLink(initialUri, replace: true);
      }
    } catch (e) {
      debugPrint('DeepLink: init error=$e');
    }

    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('DeepLink: stream=$uri');
      _navigateDeepLink(uri, replace: false);
    }, onError: (e) {
      debugPrint('DeepLink: stream error=$e');
    });
  }

  void _navigateDeepLink(Uri uri, {bool replace = false}) {
    final route = _buildDeepLinkRoute(uri);
    if (route == null) {
      debugPrint('DeepLink: no match for $uri');
      return;
    }
    _pushWithRetry(route, retries: 20, replace: replace);
  }

  void _pushWithRetry(Route<dynamic> route, {int retries = 20, bool replace = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = _navigatorKey.currentState;
      if (nav != null) {
        debugPrint('DeepLink: pushing route (replace=$replace)');
        if (replace) {
          nav.pushAndRemoveUntil(route, (r) => false);
        } else {
          nav.push(route);
        }
      } else if (retries > 0) {
        debugPrint('DeepLink: navigator not ready, retrying ($retries left)');
        Future.delayed(const Duration(milliseconds: 500), () {
          _pushWithRetry(route, retries: retries - 1, replace: replace);
        });
      } else {
        debugPrint('DeepLink: navigator never became available');
      }
    });
  }

  Route<dynamic>? _buildDeepLinkRoute(Uri uri) {
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.isEmpty) return null;
    if (segs[0] == 'reset-password') {
      final email = segs.length >= 3 ? Uri.decodeComponent(segs[1]) : '';
      final token = segs.length >= 2 ? segs.last : '';
      debugPrint('DeepLink: reset-password email=$email token=$token');
      return MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email, token: token));
    }
    if (segs[0] == 'accept-invitation' && segs.length >= 2) {
      return MaterialPageRoute(builder: (_) => AcceptInvitationScreen(token: segs[1]));
    }
    debugPrint('DeepLink: unknown path=${segs.join("/")}');
    return null;
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'CollabSME',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      home: authAsync.when(
        data: (user) => user == null ? const LoginScreen() : const HomeScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.wifiOff, size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                const Text("Erreur de connexion au serveur", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => ref.read(authStateProvider.notifier).checkSession(), child: const Text("Réessayer")),
                TextButton(onPressed: () async { await ApiClient.removeToken(); ref.invalidate(authStateProvider); }, child: const Text("Retour à la connexion", style: TextStyle(color: AppColors.textSecondary))),
              ],
            ),
          ),
        ),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == null) return null;
        final uri = Uri.parse(settings.name!);
        final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segs.isEmpty) return null;
        if (segs[0] == 'reset-password') {
          final email = segs.length >= 3 ? Uri.decodeComponent(segs[1]) : '';
          final token = segs.length >= 2 ? segs.last : '';
          return MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email, token: token));
        }
        if (segs[0] == 'accept-invitation' && segs.length >= 2) {
          return MaterialPageRoute(builder: (_) => AcceptInvitationScreen(token: segs[1]));
        }
        return null;
      },
    );
  }
}