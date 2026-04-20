// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluterr/Cary/custom/textfeild.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final GlobalKey<FormState> formstate = GlobalKey<FormState>();
  
  bool _isLoading = false;

  void _showDialog(String title, String desc, DialogType type) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkOnPress: () {},
      btnOkColor: type == DialogType.error ? Colors.red : const Color(0xFF2D7DFF),
    ).show();
  }

  // --- دالة فحص الاشتراك والهدية والتوجه للصفحة المناسبة ---
  Future<void> _checkSubscriptionAndNavigate(String uid) async {
    try {
      // 1. ربط الهوية في RevenueCat
      await Purchases.logIn(uid);
      
      // 2. جلب بيانات الاشتراك والهدية في وقت واحد
      final results = await Future.wait([
        Purchases.getCustomerInfo(),
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
      ]);

      CustomerInfo customerInfo = results[0] as CustomerInfo;
      DocumentSnapshot userDoc = results[1] as DocumentSnapshot;

      // 3. التحقق من الاشتراك المدفوع (RevenueCat)
      bool isPro = customerInfo.entitlements.all["pro_access"]?.isActive ?? false;

      // 4. التحقق من فترة الهدية (Firestore)
      bool isTrialActive = false;
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        if (userData.containsKey('trialEndDate')) {
          dynamic rawDate = userData['trialEndDate'];
          DateTime trialEnd;
          if (rawDate is Timestamp) {
            trialEnd = rawDate.toDate();
          } else {
            trialEnd = DateTime.parse(rawDate.toString());
          }
          
          if (DateTime.now().isBefore(trialEnd)) {
            isTrialActive = true;
          }
        } else if (userData.containsKey('joinDate')) {
          // --- التعديل هنا: الفحص بناءً على دقيقتين للاختبار ---
          DateTime joinDate = (userData['joinDate'] as Timestamp).toDate();
          if (DateTime.now().difference(joinDate).inDays <= 30) {
            isTrialActive = true;
          }
        }
      }

      if (!mounted) return;

      // القرار النهائي
      if (isPro || isTrialActive) {
        // يدخل الهوم ويمسح كل اللي فات عشان ميعرفش يرجع للوج إن
        Navigator.of(context).pushNamedAndRemoveUntil('homepage', (route) => false);
      } else {
        // لو الدقيقتين خلصوا يروح للاشتراك ويتم تسجيل الخروج فعلياً من الفايربيز لزيادة الأمان
        await FirebaseAuth.instance.signOut();
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushNamedAndRemoveUntil('sub', (route) => false);
      }

    } catch (e) {
      debugPrint("Subscription Check Error: $e");
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('sub', (route) => false);
    }
  }

  // --- تسجيل الدخول بجوجل ---
  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await GoogleSignIn().signOut(); 

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          await _checkSubscriptionAndNavigate(user.uid);
        } else {
          await GoogleSignIn().signOut();
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;
          _showDialog(
            "Account Not Found", 
            "No record found for this account. Please go to Sign Up to create your profile first.", 
            DialogType.warning
          );
        }
      }
    } catch (e) {
      debugPrint("Google Login Error: $e");
      _showDialog("Error", "Google Sign-In failed.", DialogType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- تسجيل الدخول بالبريد الإلكتروني ---
  Future<void> _handleEmailLogin() async {
    if (formstate.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text.trim(),
        );

        if (!mounted) return;

        if (credential.user!.emailVerified) {
          await _checkSubscriptionAndNavigate(credential.user!.uid);
        } else {
          _showDialog('Email Not Verified', 'Please verify your email first. A link has been sent.', DialogType.warning);
          await credential.user!.sendEmailVerification();
        }
      } on FirebaseAuthException catch (e) {
        _showDialog('Login Error', _getFirebaseErrorMessage(e.code), DialogType.error);
      } catch (e) {
        _showDialog('Error', 'An unexpected error occurred.', DialogType.error);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (email.text.isEmpty || !email.text.contains('@')) {
      _showDialog('Error', 'Please enter a valid email address first.', DialogType.error);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text.trim());
      _showDialog('Success', 'A password reset link has been sent to your email.', DialogType.success);
    } catch (e) {
      _showDialog('Error', 'Could not send reset email. Check if the email exists.', DialogType.error);
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'Account not found. Please sign up first.';
      case 'wrong-password': return 'Incorrect password.';
      case 'invalid-email': return 'The email format is incorrect.';
      case 'network-request-failed': return 'Please check your internet connection.';
      case 'user-disabled': return 'This account has been disabled.';
      default: return 'Login failed. Please try again.';
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E19),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: formstate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text(
                  "Welcome Back",
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Login to continue managing your car",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),

                CustomTextForm(
                  hinttext: "Email Address",
                  mycontroller: email,
                  validator: (val) => val == '' ? 'Field can\'t be empty' : null,
                  prefixIcon: Icons.email_outlined,
                ),

                const SizedBox(height: 20),

                CustomTextForm(
                  hinttext: "Password",
                  mycontroller: password,
                  validator: (val) => val == '' ? 'Field can\'t be empty' : null,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleForgotPassword,
                    child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF2D7DFF))),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7DFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _handleEmailLogin,
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 40),
                _buildDivider(),
                const SizedBox(height: 40),

                _buildMaterialSocialButton(
                  label: "Continue with Google",
                  icon: Icons.g_mobiledata_rounded,
                  color: Colors.redAccent,
                  onTap: _isLoading ? () {} : signInWithGoogle,
                ),

                const SizedBox(height: 60),
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.white10)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text("Or", style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider(color: Colors.white10)),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('signup'),
          child: const Text("Sign Up", style: TextStyle(color: Color(0xFF2D7DFF), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMaterialSocialButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 30),
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}