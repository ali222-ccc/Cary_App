// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  String _displayPrice = "---";

  final Color accentColor = const Color(0xFF2D7DFF);
  final Color cardColor = const Color(0xFF1A1F30);
  final Color bgColor = const Color(0xFF0B0E14);
  final Color goldColor = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _setupRevenueCat();
  }

  Future<void> _setupRevenueCat() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await Purchases.logIn(uid);
        debugPrint("🚀 Cary User ID Synced: $uid");
      } catch (e) {
        debugPrint("❌ Error logging in to RevenueCat: $e");
      }
    }

    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.monthly != null) {
        if (mounted) {
          setState(() {
            _displayPrice =
                offerings.current!.monthly!.storeProduct.priceString;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching price: $e");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Subscription Status',
      desc: msg,
      btnOkOnPress: () {},
      btnOkColor: Colors.red,
    ).show();
  }

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);
    try {
      Offerings offerings = await Purchases.getOfferings();
      Package? package = offerings.current?.monthly;

      if (package != null) {
        PurchaseResult result = await Purchases.purchasePackage(package);

        if (result.customerInfo.entitlements.all["pro_access"]?.isActive ??
            false) {
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('homepage', (route) => false);
        }
      } else {
        _showError(
          "No monthly plan found. Please check your RevenueCat dashboard.",
        );
      }
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        _showError(e.message ?? "Error connecting to store");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      if (customerInfo.entitlements.all["pro_access"]?.isActive ?? false) {
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('homepage', (route) => false);
      } else {
        _showError("No active subscription found.");
      }
    } catch (e) {
      _showError("Failed to sync.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: accentColor.withOpacity(0.1),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 20),
                  _buildHeroSection(),
                  const SizedBox(height: 40),
                  _buildFeaturesList(),
                  const SizedBox(height: 40),
                  _buildPriceCard(),
                  const SizedBox(height: 40),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                  const Text(
                    "\nYou can cancel anytime through your Google Play settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('login', (route) => false),
        ),
        TextButton(
          onPressed: _isLoading ? null : _handleRestore,
          child: Text(
            "Restore",
            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withOpacity(0.2)),
          ),
          child: Icon(Icons.auto_awesome_rounded, color: goldColor, size: 50),
        ),
        const SizedBox(height: 20),
        const Text(
          "Cary PRO",
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your car deserves the best care",
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      children: [
        _buildFeatureRow(
          Icons.block_rounded,
          "100% Ad-Free",
          "Zero interruptions. Focused on your car.",
        ),
        _buildFeatureRow(
          Icons.description_rounded,
          "Professional Reports",
          "Get detailed monthly summaries of your car expenses.",
        ),
        _buildFeatureRow(
          Icons.analytics_rounded,
          "Advanced Insights",
          "Deep analysis of fuel and maintenance costs.",
        ),
        _buildFeatureRow(
          Icons.picture_as_pdf_rounded,
          "Monthly Reports",
          "Export professional PDF reports for your data.",
        ),
        _buildFeatureRow(
          Icons.notifications_active_rounded,
          "Priority Alerts",
          "Smart reminders for licenses and maintenance.",
        ),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cardColor, bgColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Premium Monthly",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$_displayPrice / month",
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
              Icon(Icons.stars_rounded, color: goldColor, size: 40),
            ],
          ),
        ),
        Positioned(
          top: -15,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "Cary Pro",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          shadowColor: accentColor.withOpacity(0.5),
        ),
        onPressed: _isLoading ? null : _handlePurchase,
        child: const Text(
          "Start Now ",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
