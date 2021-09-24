import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:online_planner_app/main/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _preferences;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  _preferences = await SharedPreferences.getInstance();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _preferences!.getBool('isAuth') ?? false ? MainPage.init(_preferences!.getString('tier') ?? "") : StartPage(),
    );
  }
}

