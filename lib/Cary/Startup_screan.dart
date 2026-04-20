// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; 

class OnboardingData {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const OnboardingData({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}

class CaryOnboardingScreen extends StatefulWidget {
  const CaryOnboardingScreen({super.key});

  @override
  State<CaryOnboardingScreen> createState() => _CaryOnboardingScreenState();
}

class _CaryOnboardingScreenState extends State<CaryOnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _loadingController;
  bool _isLoading = true;
  int _currentPage = 0;

  static const List<OnboardingData> _onboardingPages = [
    OnboardingData(
      icon: Icons.credit_card,
      title: "Track Every Pound\nYou Spend",
      desc: "Manage your car expenses easily with our smart tracking system.",
      color: Color(0xFF2D7DFF),
    ),
    OnboardingData(
      icon: Icons.build_circle_outlined,
      title: "Never Miss\nMaintenance Again",
      desc: "Get smart reminders before your next oil change or service.",
      color: Color(0xFF00C853),
    ),
    OnboardingData(
      icon: Icons.monitor_heart_outlined,
      title: "Know Your Car's\nReal Health",
      desc: "Real-time diagnostics and health score for your vehicle.",
      color: Color(0xFF2D7DFF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // محاكاة تحميل البيانات (Splash)
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  // دالة لإنهاء الـ Onboarding وحفظ الحالة
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true); // حفظ إن المستخدم شافها خلاص
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _isLoading ? _buildSplashScreen() : _buildOnboardingContent(),
      ),
    );
  }

  Widget _buildSplashScreen() {
    return Center(
      key: const ValueKey(1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'logo',
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D7DFF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.directions_car_filled, size: 64, color: Colors.white),
            ),
          ),
          const SizedBox(height: 30),
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8, width: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_loadingController.value > (index / 3) ? 1.0 : 0.2),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingContent() {
    return Column(
      key: const ValueKey(2),
      children: [
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: _completeOnboarding,
              child: const Text("Skip", style: TextStyle(color: Colors.white54, fontSize: 16)),
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _onboardingPages.length,
            itemBuilder: (context, index) {
              final item = _onboardingPages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: item.color.withOpacity(0.1),
                      child: Icon(item.icon, size: 80, color: item.color),
                    ),
                    const SizedBox(height: 50),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      item.desc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_onboardingPages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? const Color(0xFF2D7DFF) : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7DFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                if (_currentPage < _onboardingPages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _completeOnboarding();
                }
              },
              child: Text(
                _currentPage == _onboardingPages.length - 1 ? "Get Started" : "Next",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}