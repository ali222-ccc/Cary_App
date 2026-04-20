// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluterr/Cary/profile/PrivacyPolicy.dart';
import 'package:fluterr/Cary/profile/help&support.dart';
import 'package:fluterr/Cary/profile/mycar.dart';
import 'package:fluterr/Cary/profile/myprofile.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart'; // إضافة المكتبة

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final Color cardColor = const Color(0xFF1A1F30);
  final Color accentColor = const Color(0xFF2D7DFF);
  final Color bgColor = const Color(0xFF0B0E14);

  // متغيرات الكاش لمنع الرمشة
  String _cachedName = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadCachedName(); // تحميل الاسم المخزن فوراً عند الدخول للبروفايل
  }

  // دالة تحميل الاسم من الذاكرة المحلية
  Future<void> _loadCachedName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cachedName = prefs.getString('user_name') ?? "Driver";
    });
  }

  // تحديث الكاش لو حصل تغيير في الداتا
  Future<void> _updateNameCache(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newName);
  }

  // --- دالة مسح الحساب والبيانات بالكامل ---
  Future<void> _handleDeleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final String uid = user.uid;
      final firestore = FirebaseFirestore.instance;
      final WriteBatch batch = firestore.batch();

      final maintenanceDocs = await firestore
          .collection('maintenance')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in maintenanceDocs.docs) {
        batch.delete(doc.reference);
      }

      final fuelDocs = await firestore
          .collection('fuels')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in fuelDocs.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(firestore.collection('users').doc(uid));
      await batch.commit();
      await user.delete();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('login', (route) => false);

    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showErrorDialog("Security: Please log out and log back in before deleting your account to verify your identity.");
      } else {
        _showErrorDialog("Failed to delete account. Error: ${e.message}");
      }
    } catch (e) {
      debugPrint("Delete Account Error: $e");
      _showErrorDialog("An unexpected error occurred while deleting your data.");
    }
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: 'Error',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  void _showDeleteConfirmation() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      headerAnimationLoop: false,
      animType: AnimType.bottomSlide,
      title: 'Delete Everything?',
      desc: 'This will permanently delete your account, car data, fuel logs, and maintenance records. This cannot be undone!',
      btnCancelText: "Cancel",
      btnOkText: "Yes, Delete All",
      btnOkColor: Colors.redAccent,
      btnCancelOnPress: () {},
      btnOkOnPress: _handleDeleteAccount,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  // نبدأ بالاسم المخزن (الكاش)
                  String name = _cachedName;
                  String email = currentUser?.email ?? "User";

                  // لو الداتا جت من Firestore نحدث الاسم ونخزنه
                  if (snapshot.hasData && snapshot.data!.exists) {
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    name = data['name'] ?? "Driver";
                    _updateNameCache(name); 
                  }

                  // لو لسه بيحمل لأول مرة خالص ومفيش كاش، نظهر لودينج بسيط
                  bool isLoading = snapshot.connectionState == ConnectionState.waiting && _cachedName == "Loading...";

                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor.withOpacity(0.5), width: 3),
                          boxShadow: [
                            BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 20)
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: cardColor,
                          child: Icon(Icons.person, size: 60, color: accentColor),
                        ),
                      ),
                      const SizedBox(height: 20),
                      isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24))
                        : Text(
                            name,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                      const SizedBox(height: 5),
                      Text(
                        email,
                        style: const TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),
              const Divider(color: Colors.white10),
              const SizedBox(height: 20),

              _buildProfileOption(Icons.person_outline_rounded, "My Profile", () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyProfilePage()));
              }),

              _buildProfileOption(Icons.directions_car_filled_outlined, "My Car", () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyCarPage()));
              }),

              _buildProfileOption(Icons.security_outlined, "Privacy & Safety", () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()));
              }),

              _buildProfileOption(Icons.help_outline_rounded, "Help & Support", () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HelpSupportPage()));
              }),

              const SizedBox(height: 20),

              _buildProfileOption(Icons.logout_rounded, "Log Out", _showLogoutDialog, isLogout: true),
              
              _buildProfileOption(Icons.delete_forever_rounded, "Delete Account", _showDeleteConfirmation, isDelete: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap, {bool isLogout = false, bool isDelete = false}) {
    Color itemColor = isLogout ? Colors.orangeAccent : (isDelete ? Colors.redAccent : accentColor);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: itemColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: itemColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDelete || isLogout ? itemColor : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: itemColor.withOpacity(0.3),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Log Out", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to exit?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: accentColor, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () async {
              GoogleSignIn googleSignIn = GoogleSignIn();
              await googleSignIn.signOut();
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.of(context).pushNamedAndRemoveUntil('login', (route) => false);
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}