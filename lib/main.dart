import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:webserial_slcan/screens/connect_screen.dart';
import 'package:webserial_slcan/screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSerial SLCAN',
      theme: ThemeData.dark(),
      scrollBehavior: AppCustomScrollBehavior(),
      initialRoute: ConnectScreen.id,
      routes: {
        ConnectScreen.id: (context) => const ConnectScreen(),
        MainScreen.id: (context) => const MainScreen(),
      },
    );
  }
}

class AppCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
