import 'dart:ui';

import 'package:finder/pages/aboutus.dart';
import 'package:finder/pages/admin/admindash.dart';
import 'package:finder/pages/dashboard.dart';
import 'package:finder/pages/help.dart';
import 'package:finder/pages/login_page.dart';
import 'package:finder/pages/rateus.dart';
import 'package:finder/pages/register_page.dart';
import 'package:finder/pages/user/matching_description_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'constants.dart';
import 'data/providers.dart';
import 'firebase_options.dart';

//final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  //SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
  ProviderScope(child:   _MyHomePageState())


  );

}

  class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.trackpad
  };
  }


class _MyHomePageState extends ConsumerStatefulWidget {
  const _MyHomePageState({super.key});

  @override
  ConsumerState<_MyHomePageState> createState() => _LoadingAppState();
}

class _LoadingAppState extends ConsumerState<_MyHomePageState> {
  ThemeMode themeMode = ThemeMode.light;
  ColorSelection colorSelected = ColorSelection.blue;
  bool IsAdmin() {
    final userRoleAsync = ref.watch(userRoleProvider);

    if (userRoleAsync.isLoading || userRoleAsync.value == null) {
      return false; // Default non-admin while loading
    }

    return userRoleAsync.value!.toLowerCase() == "admin"; // Case-insensitive check
  }



  // bool IsAdmin(){
  //
  //   return ref.watch(userRoleProvider).value=="Admin"? true:false;
  // }

  late final _router = GoRouter(
    initialLocation: '/login',
    redirect: _appRedirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          isAdmin:  IsAdmin(),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterPage(

        ),
      ),
      GoRoute(
        path: '/admindashboard',
        builder: (context, state) => AdminDashboardScreen( ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          return DashboardScreen(
            changeTheme: changeThemeMode,
            changeColor: changeColor,
            colorSelected: colorSelected,
          );
        },
      ),

      // GoRoute(
      //   path: '/matching_description',
      //   builder: (context, state) {
      //     final foundItems = state.extra as List<Map<String, dynamic>>;
      //     return MatchingDescriptionScreen(foundItems: foundItems);
      //   },
      // ),


      GoRoute(
        path: '/help',
        builder: (context, state) => HelpPage(
          isAdmin:  IsAdmin(),
          changeTheme: changeThemeMode,
          changeColor: changeColor,
          colorSelected: colorSelected,

        )
        ,

      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => AboutUsPage(
          changeTheme: changeThemeMode,
          changeColor: changeColor,
          colorSelected: colorSelected,

        )
        ,

      ),  GoRoute(
        path: '/rate',
        builder: (context, state) =>  RateUsPage(
          changeTheme: changeThemeMode,
          changeColor: changeColor,
          colorSelected: colorSelected,

        )
        ,

      ),



    ],
    errorPageBuilder: (context, state) {
      return MaterialPage(
        key: state.pageKey,
        child: Scaffold(
          body: Center(
            child: Text(state.error.toString()),
          ),
        ),
      );
    },
  );


  Future<String?> _appRedirect(BuildContext context, GoRouterState state) async {
    final userDao = ref.watch(userDaoProvider);
    final loggedIn = userDao.isLoggedIn();
    final userRoleAsync = ref.watch(userRoleProvider);

    if (!loggedIn) {
      return '/login';
    }

    if (userRoleAsync.isLoading || userRoleAsync.value == null) {
      print("Waiting for user role to load...");
      return null;
    }

    final role = userRoleAsync.value!.toLowerCase();
    print("Final Role Determined: $role"); // Debugging

    return role == "admin" ? '/admindashboard' : '/dashboard';
  }


  void changeThemeMode(bool useLightMode) {
    setState(() {
      themeMode = useLightMode
          ? ThemeMode.light //
          : ThemeMode.dark;
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
      scrollBehavior: CustomScrollBehavior(),
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