// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  // نفس باليتة الألوان اللي شغالين عليها
  final Color bgColor = const Color(0xFF0B0E14);
  final Color cardColor = const Color(0xFF1A1F30);
  final Color accentColor = const Color(0xFF2D7DFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أيقونة الحماية في الأعلى
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 50, color: Colors.greenAccent),
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              "Your Privacy Matters",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "At Cary, we take your car's data security seriously. Here is how we protect your information.",
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // أقسام السياسة
            _buildPolicySection(
              "1. Data Collection",
              "We collect information such as your name, car brand, model, and fuel expenses to provide accurate car health reports and daily reminders.",
            ),
            _buildPolicySection(
              "2. Data Storage & Security",
              "All your data is securely stored on Google Firebase. We use high-end encryption to ensure that your records are only accessible to you.",
            ),
            _buildPolicySection(
              "3. Why English Language?",
              "For technical accuracy in car health analysis (Overall Health), we require some car details like color and brand to be entered in English.",
            ),
            _buildPolicySection(
              "4. Daily Reminders",
              "The app schedules a midnight notification to help you track your daily logs. We do not use these notifications for advertising.",
            ),
            _buildPolicySection(
              "5. Your Rights",
              "You can edit or delete your car records and profile information at any time through the app settings.",
            ),

            const SizedBox(height: 20),
            
            // تذييل الصفحة
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white38, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "By using Cary, you agree to these terms. Last updated: Feb 2026.",
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ويدجت لبناء فقرات السياسة بشكل منظم
  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5, // لزيادة المسافة بين السطور وجعل القراءة مريحة
            ),
          ),
        ],
      ),
    );
  }
}