// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluterr/Cary/custom/textfeild.dart';
import 'package:fluterr/Cary/welcome.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final GlobalKey<FormState> formstate = GlobalKey<FormState>();

  Timer? timer;
  bool _isLoading = false;

  // --- دالة إعداد المستخدم الجديد وحساب فترة الهدية ---
  Future<void> _setupNewUser(User user) async {
    // مدة تجريبية 5 دقائق للاختبار
    DateTime trialEndDate = DateTime.now().add(const Duration(days: 30));
    
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'name': "Driver",
      'createdAt': FieldValue.serverTimestamp(),
      'trialEndDate': trialEndDate.toIso8601String(), 
      'isPro': false, 
    });

    await Purchases.logIn(user.uid);
  }

  // --- 1. تسجيل الاشتراك بجوجل ---
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

      if (userCredential.user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
        
        if (!userDoc.exists) {
          // مستخدم جديد تماماً -> إعداد البيانات والتوجه لصفحة الويلكم
          await _setupNewUser(userCredential.user!);
          if (!mounted) return;
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const WelcomeCaryScreen())
          );
        } else {
          // مستخدم موجود مسبقاً -> منعه من الدخول كجديد
          await FirebaseAuth.instance.signOut();
          await GoogleSignIn().signOut();
          
          if (!mounted) return;
          _showAlreadyRegisteredDialog();
        }
      }
      
    } catch (e) {
      _showErrorDialog("Google Sign-Up failed. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. التحقق من تفعيل الإيميل ---
  void checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    if (user?.emailVerified ?? false) {
      timer?.cancel();
      if (mounted) {
        await _setupNewUser(user!); 
        // التوجه لصفحة الويلكم بعد تفعيل الإيميل
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context, 
          MaterialPageRoute(builder: (context) => const WelcomeCaryScreen())
        );
      }
    }
  }

  // --- 3. عملية الـ SignUp بالبريد الإلكتروني ---
  Future<void> _handleSignUp() async {
    if (formstate.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: email.text.trim(),
              password: password.text.trim(),
            );

        await credential.user!.sendEmailVerification();

        if (!mounted) return;

        AwesomeDialog(
          context: context,
          dialogType: DialogType.info,
          animType: AnimType.rightSlide,
          title: 'Verify Your Email',
          desc: 'A verification link sent to ${email.text.trim()}. Please verify it to start your trial.',
          btnOkText: "Waiting...",
          btnOkOnPress: () {},
        ).show();

        timer = Timer.periodic(const Duration(seconds: 3), (timer) {
          if (timer.tick > 40) timer.cancel();
          checkEmailVerified();
        });
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          _showAlreadyRegisteredDialog();
        } else {
          _showErrorDialog(_getFirebaseErrorMessage(e.code));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showAlreadyRegisteredDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: 'Account Exists',
      desc: 'This email is already registered. Please sign in to access your account.',
      btnOkText: "Log In",
      btnOkOnPress: () {
        Navigator.of(context).pushReplacementNamed('login');
      },
    ).show();
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'weak-password': return 'The password is too weak.';
      case 'invalid-email': return 'The email format is incorrect.';
      default: return 'Signup failed. Please try again.';
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: 'Error',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  void dispose() {
    timer?.cancel();
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
                  "Create Account",
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Get your premium trial for free!",
                  style: TextStyle(color: Color(0xFF2D7DFF), fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 40),

                CustomTextForm(
                  hinttext: "Email Address",
                  mycontroller: email,
                  validator: (val) => val == '' ? 'Field cannot be empty' : null,
                  prefixIcon: Icons.email_outlined,
                ),

                const SizedBox(height: 20),

                CustomTextForm(
                  hinttext: "Password",
                  mycontroller: password,
                  validator: (val) => val!.length < 6 ? 'Min 6 characters' : null,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 50),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7DFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _handleSignUp,
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 40),
                _buildDivider(),
                const SizedBox(height: 40),

                _buildSocialButton(
                  label: "Sign up with Google",
                  icon: Icons.g_mobiledata_rounded,
                  onTap: _isLoading ? () {} : signInWithGoogle,
                ),

                const SizedBox(height: 60),
                _buildLoginLink(),
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

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? ", style: TextStyle(color: Colors.white70)),
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('login'),
          child: const Text("Log In", style: TextStyle(color: Color(0xFF2D7DFF), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSocialButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.redAccent, size: 30),
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}