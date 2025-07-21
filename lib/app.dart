import 'package:flutter/material.dart';
import 'package:flutter_gcs/screens/welcome_screen/welcome_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return ProviderScope(
      child: MaterialApp(
        title:'Flutter GCS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true,),
        home: WelcomeScreen(),
      )
    );
  }
}