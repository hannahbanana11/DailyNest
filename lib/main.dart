import 'package:dailynest/AuthPage/login.dart';
import 'package:dailynest/AuthPage/register.dart';
import 'package:dailynest/AuthPage/forgotpassword.dart';
import 'package:dailynest/dashboard.dart';
import 'package:dailynest/Weather/weather.dart';
import 'package:dailynest/Journal/journal.dart';
import 'package:dailynest/Savings/savings.dart';
import 'package:dailynest/Journal/addjournal.dart';
import 'package:dailynest/Savings/addsavings.dart';
import 'package:dailynest/Weather/app_shell.dart';
import 'package:dailynest/AuthPage/profile_setting.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dailynest/Auth/AuthService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      // Use the auth state to drive which screen is shown as the home.
      home: StreamBuilder<User?>(
        stream: authService.value.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const AppShell();
          }

          return const Login();
        },
      ),
      routes: {
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
      debugShowCheckedModeBanner: false,
    );
  }
}
