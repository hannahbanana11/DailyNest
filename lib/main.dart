import 'package:dailynest/login.dart';
import 'package:dailynest/register.dart';
import 'package:dailynest/forgotpassword.dart';
import 'package:dailynest/dashboard.dart';
import 'package:dailynest/weather.dart';
import 'package:dailynest/journal.dart';
import 'package:dailynest/savings.dart';
import 'package:dailynest/addjournal.dart';
import 'package:dailynest/addsavings.dart';
import 'package:dailynest/app_shell.dart';
import 'package:dailynest/profile_setting.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "DailyNest",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      initialRoute: Login.id,
      routes: {
        Login.id: (context) => const Login(),
        Register.id: (context) => const Register(),
        Forgotpassword.id: (context) => const Forgotpassword(),
        AppShell.id: (context) => const AppShell(),
        Dashboard.id: (context) => const Dashboard(),
        Weather.id: (context) => const Weather(),
        Journal.id: (context) => const Journal(),
        Savings.id: (context) => const Savings(),
        AddJournal.id: (context) => const AddJournal(),
        AddSavings.id: (context) => const AddSavings(),
        ProfileSettings.id: (context) => const ProfileSettings(),
      },
    );
  }
}
