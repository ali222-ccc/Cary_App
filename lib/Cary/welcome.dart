// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class WelcomeCaryScreen extends StatelessWidget {
  const WelcomeCaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E19), // الخلفية الداكنة اللي بنستخدمها
      body: Stack(
        children: [
          // خلفية جمالية خفيفة (تدرج لوني في الزوايا)
          const PositionContextDecoration(),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة بريميوم مع تأثير توهج
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D7DFF).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      size: 110,
                      color: Color(0xFF2D7DFF),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // عنوان الترحيب
                  const Text(
                    "Welcome to Cary!",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // وصف المدة التجريبية
                  const Text(
                    "You've unlocked 30 days of Premium Access for free.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: Color(0xFF2D7DFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // قائمة مميزات سريعة
                  _buildFeatureItem(Icons.check_circle_outline, "Track Expenses & Fuel Efficiency"),
                  _buildFeatureItem(Icons.check_circle_outline, "Smart Maintenance Reminders"),
                  _buildFeatureItem(Icons.check_circle_outline, "Advanced Analytics & Reports"),
                  
                  const SizedBox(height: 30),

                  // تنبيه نهاية المدة
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Text(
                      "After your 30-day trial expires, you will be redirected to the subscription page to continue enjoying our premium features.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // زر البدء
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D7DFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 10,
                        shadowColor: const Color(0xFF2D7DFF).withOpacity(0.4),
                      ),
                      onPressed: () => Navigator.pushReplacementNamed(context, 'homepage'),
                      child: const Text(
                        "Get Started",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ودجت صغيرة لبناء سطر المميزات
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

// إضافة تدرج لوني في الخلفية لإعطاء مظهر عصري
class PositionContextDecoration extends StatelessWidget {
  const PositionContextDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2D7DFF).withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2D7DFF).withOpacity(0.05),
            ),
          ),
        ),
      ],
    );
  }
}