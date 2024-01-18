import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_by/screen/signup.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'login.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final fireStore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () async {
      var prefs = await SharedPreferences.getInstance();
      String? checkLogin = prefs.getString(MyRegister.LOGIN_PREFS_KEY);
      Widget navigateTo = MyLogin();
      if (!mounted) {
        return;
      }

      print(checkLogin);
      if (checkLogin != null && checkLogin != "") {
        navigateTo = HomeScreen();
      }

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (ctx) => navigateTo));
    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/images/img.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Text(
              'Notes App',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.normal,
                fontSize: 40,
              ),
            ),
          )
        ],
      ),
    );
  }
}
