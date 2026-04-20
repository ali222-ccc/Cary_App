// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  // ألوان التطبيق المتناسقة
  final Color cardColor = const Color(0xFF1A1F30);
  final Color bgColor = const Color(0xFF0B0E14);
  final Color accentColor = const Color(0xFF2D7DFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Help Center', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeroSection(),
            const SizedBox(height: 30),
            
            _buildSectionTitle("General Questions"),
            _buildFAQTile(
              "How to add a new car?",
              "You can add a new car by tapping the '+' icon or the car switcher on the home screen. Fill in the brand, model, and year to get started.",
            ),
            _buildFAQTile(
              "Where is my data stored?",
              "All your maintenance and fuel logs are securely synced to your private cloud account, ensuring you never lose your history.",
            ),
            
            const SizedBox(height: 20),
            _buildSectionTitle("Maintenance & Fuel"),
            _buildFAQTile(
              "How is 'Car Health' calculated?",
              "It's an intelligent estimate based on your service intervals (like oil changes) and how frequently you record maintenance vs. your mileage.",
            ),
            _buildFAQTile(
              "Can I export my records?",
              "We are working on a feature to export your car's history as a PDF report. Stay tuned for future updates!",
            ),
            _buildFAQTile(
              "How to delete an incorrect entry?",
              "Simply go to the Archive (Fuel or Maintenance), find the specific record, and long-press on it to show the delete option.",
            ),

            const SizedBox(height: 40),
            const Text(
              "App Version 1.0.2",
              style: TextStyle(color: Colors.white10, fontSize: 11, letterSpacing: 1),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // الجزء العلوي الجذاب
  Widget _buildHeroSection() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withOpacity(0.1), width: 2),
            ),
            child: Icon(Icons.auto_awesome_motion_rounded, size: 50, color: accentColor),
          ),
          const SizedBox(height: 20),
          const Text(
            "Frequently Asked Questions",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Find answers to common issues quickly",
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: accentColor,
          collapsedIconColor: Colors.white24,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          title: Text(
            question,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 0),
              child: Text(
                answer,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}