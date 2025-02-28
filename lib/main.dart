import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'homepage.dart';
import 'new2/additem.dart';
import 'new2/chart_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/admin/admindash.dart';
import 'pages/dashboard.dart';
import 'pages/help.dart';
import 'pages/login_page.dart';
import 'pages/rateus.dart';
import 'pages/register_page.dart';
import 'pages/aboutus.dart';
import 'data/providers.dart';
import 'constants.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  ThemeMode themeMode = ThemeMode.light;
  ColorSelection colorSelected = ColorSelection.blue;

  bool isAdmin() {
    final userRoleAsync = ref.watch(userRoleProvider);
    return userRoleAsync.value?.toLowerCase() == "admin";
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => HomePage()),

      GoRoute(path: '/add_item', builder: (context, state) => AddItemPage(
        changeTheme: changeThemeMode,
        changeColor: changeColor,
        colorSelected: colorSelected,
      )),
      GoRoute(path: '/talk_to_us', builder: (context, state) => ChatScreen()),
      GoRoute(path: '/login', builder: (context, state) => LoginPage(isAdmin: isAdmin())),
      GoRoute(path: '/register', builder: (context, state) => RegisterPage()),
      GoRoute(path: '/admindashboard', builder: (context, state) => AdminDashboardScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => DashboardScreen(
        changeTheme: changeThemeMode,
        changeColor: changeColor,
        colorSelected: colorSelected,
      )),
      GoRoute(path: '/help', builder: (context, state) => HelpPage(
        isAdmin: isAdmin(),
        changeTheme: changeThemeMode,
        changeColor: changeColor,
        colorSelected: colorSelected,
      )),
      GoRoute(path: '/about', builder: (context, state) => AboutUsPage(
        changeTheme: changeThemeMode,
        changeColor: changeColor,
        colorSelected: colorSelected,
      )),
      GoRoute(path: '/rate', builder: (context, state) => RateUsPage(
        changeTheme: changeThemeMode,
        changeColor: changeColor,
        colorSelected: colorSelected,
      )),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(child: Text(state.error.toString())),
      ),
    ),
  );

  void changeThemeMode(bool useLightMode) {
    setState(() {
      themeMode = useLightMode ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void changeColor(int value) {
    setState(() {
      colorSelected = ColorSelection.values[value];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      themeMode: themeMode,
      theme: ThemeData(
        colorSchemeSeed: colorSelected.color,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: colorSelected.color,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
    );
  }
}
