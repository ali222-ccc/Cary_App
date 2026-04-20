// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:fluterr/Cary/subscribion_screen.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz_data; 
import 'package:purchases_flutter/purchases_flutter.dart';

import 'firebase_options.dart'; 

import 'package:fluterr/Cary/Startup_screan.dart';
import 'package:fluterr/Cary/homepage.dart';
import 'package:fluterr/Cary/login_screen.dart';
import 'package:fluterr/Cary/signup_screan.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint("Cary Global Error: ${details.exception}");
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    tz_data.initializeTimeZones();

    await Purchases.setLogLevel(LogLevel.debug);
    PurchasesConfiguration configuration = 
        PurchasesConfiguration("goog_HiLhZHTPCojZVKxWdcGmmwxJieZ");
    await Purchases.configure(configuration);

  } catch (e) {
    debugPrint("Initialization Error: $e");
  }

  runApp(const CaryApp());
}

class CaryApp extends StatelessWidget {
  const CaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cary', 
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        primaryColor: const Color(0xFF246BFE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF246BFE),
          brightness: Brightness.dark,
        ),
      ),

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Color(0xFF246BFE))),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            final user = snapshot.data!;
            
            bool isVerified = user.emailVerified || 
                             user.providerData.any((info) => info.providerId == 'google.com');

            if (isVerified) {
              // --- التعديل الجوهري هنا ---
              // نستخدم Future.wait لفحص الاشتراك والهدية في وقت واحد
              return FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  Purchases.getCustomerInfo(), // فحص RevenueCat
                  FirebaseFirestore.instance.collection('users').doc(user.uid).get(), // فحص Firestore
                ]),
                builder: (context, asyncSnapshot) {
                  if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator(color: Color(0xFF246BFE))),
                    );
                  }

                  // 1. فحص اشتراك RevenueCat
                  final customerInfo = asyncSnapshot.data?[0] as CustomerInfo?;
                  bool isPro = customerInfo?.entitlements.all["pro_access"]?.isActive ?? false;

                  // 2. فحص فترة الهدية من Firestore
                  bool isTrialActive = false;
                  final userDoc = asyncSnapshot.data?[1] as DocumentSnapshot?;
                  
                  if (userDoc != null && userDoc.exists) {
                    final userData = userDoc.data() as Map<String, dynamic>;
                    if (userData.containsKey('trialEndDate')) {
                      DateTime trialEnd = DateTime.parse(userData['trialEndDate']);
                      if (DateTime.now().isBefore(trialEnd)) {
                        isTrialActive = true;
                      }
                    }
                  }

                  // إذا كان مشتركاً بفلوس أو لا يزال في فترة الهدية يدخل الهوم
                  if (isPro || isTrialActive) {
                    return const Homepagee();
                  } else {
                    // إذا انتهى الاثنين يذهب لصفحة الدفع مباشرة أو يرى الـ Onboarding
                    return const SubscriptionScreen(); 
                  }
                },
              );
            } else {
              return const LoginScreen(); 
            }
          }

          return const CaryOnboardingScreen();
        },
      ),

      routes: {
        'login': (context) => const LoginScreen(),
        'signup': (context) => const SignUpScreen(),
        'homepage': (context) => const Homepagee(),
        'sub': (context) => const SubscriptionScreen(),
        'start': (context) => const CaryOnboardingScreen(),
      },
    );
  }
}