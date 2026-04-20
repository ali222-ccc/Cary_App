// ignore_for_file: deprecated_member_use

import 'package:fluterr/Cary/home/efficiency.dart';
import 'package:fluterr/Cary/home/expenses.dart';
import 'package:fluterr/Cary/home/fuel.dart';
import 'package:fluterr/Cary/home/maintenance.dart';
import 'package:fluterr/Cary/alert.dart';
import 'package:fluterr/Cary/home/report_screean.dart';
import 'package:fluterr/Cary/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class Homepagee extends StatefulWidget {
  const Homepagee({super.key});
  @override
  State<Homepagee> createState() => _HomepageeState();
}

class _HomepageeState extends State<Homepagee> {
  int _selectedIndex = 0;
  final List<GlobalKey> _pageKeys = List.generate(4, (index) => GlobalKey());

  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final String carId = "my_car_001";

  final Color accentColor = const Color(0xFF2D7DFF);
  final Color cardColor = const Color(0xFF1A1F30);
  final Color bgColor = const Color(0xFF0B0E14);

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String _cachedName = "Loading...";
  String _cachedGender = "Male";
  String _cachedCarName = "My Car";
  int _cachedHealth = 100;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _setupUserProfile();
    _checkPermissionAndInit();
    _checkAccess(); // تم استدعاء دالة الفحص هنا عند التشغيل
  }

  // --- دالة فحص الوصول (الاشتراك + فترة الهدية) ---
  Future<void> _checkAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. فحص الاشتراك من RevenueCat
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      bool isPaid =
          customerInfo.entitlements.all["pro_access"]?.isActive ?? false;

      if (isPaid) return; // لو مشترك بفلوس، استمر

      // 2. فحص فترة الـ 30 يوم (أو الـ 5 دقائق للتجربة) من Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data()!.containsKey('trialEndDate')) {
        DateTime trialEnd = DateTime.parse(userDoc['trialEndDate']);

        // لو الوقت الحالي تجاوز وقت نهاية التجربة
        if (DateTime.now().isAfter(trialEnd)) {
          if (mounted) {
            // التوجه لصفحة الاشتراك (تأكد أن اسم الراوت 'sub' أو 'subscription' مطابق لملف main.dart)
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('sub', (route) => false);
          }
        }
      } else {
        // لو ملوش سجل فترة تجريبية (مستخدم قديم مثلاً)، يروح يشترك
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('sub', (route) => false);
        }
      }
    } catch (e) {
      debugPrint("❌ Error checking access: $e");
    }
  }

  // --- دالات الـ Cache والـ Firebase الأساسية ---

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cachedName = prefs.getString('user_name') ?? "Driver";
      _cachedGender = prefs.getString('user_gender') ?? "Male";
      _cachedCarName = prefs.getString('car_name') ?? "My Car";
      _cachedHealth = prefs.getInt('car_health') ?? 100;
    });
  }

  Future<void> _updateUserCache(String name, String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_gender', gender);
  }

  Future<void> _updateCarCache(String carName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('car_name', carName);
  }

  Future<void> _updateHealthCache(int health) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('car_health', health);
    _cachedHealth = health;
  }

  Future<void> _setupUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'name': "Driver",
          'email': user.email,
          'gender': 'Male',
          'createdAt': FieldValue.serverTimestamp(),
          'isPremium': true,
        });
      }
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Color _parseColor(String? colorName) {
    if (colorName == null || colorName.isEmpty) {
      return Colors.black;
    }
    switch (colorName.toLowerCase().trim()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'grey':
        return Colors.grey;
      case 'silver':
        return const Color(0xFFC0C0C0);
      default:
        return Colors.black;
    }
  }

  // --- الإشعارات ---

  Future<void> _checkPermissionAndInit() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );
    await _notificationsPlugin.initialize(initSettings);
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      bool? isEnabled = await androidImplementation?.areNotificationsEnabled();
      if (isEnabled == false) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showWelcomePermissionDialog(),
        );
      } else {
        await _scheduleMidnightReminder();
      }
    }
  }

  void _showWelcomePermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: accentColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Smart Reminders",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "To get the best experience, we will remind you daily to log your expenses and fuel.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _requestSystemPermission();
                  },
                  child: const Text(
                    "Enable Now",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Maybe Later",
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _requestSystemPermission() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      bool? granted = await androidImplementation
          ?.requestNotificationsPermission();
      if (granted == true) await _scheduleMidnightReminder();
    }
  }

  Future<void> _scheduleMidnightReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      22,
      0,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    await _notificationsPlugin.zonedSchedule(
      888,
      'Cary Daily Reminder',
      "Day's Done! 🚗 Don't forget to track your fuel and costs",
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_log_id',
          'Daily Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // --- Streams جلب البيانات ---

  Stream<List<Map<String, dynamic>>> _getCombinedActivity() {
    var fuelStream = FirebaseFirestore.instance
        .collection('fuels')
        .where('userId', isEqualTo: currentUserId)
        .where('carId', isEqualTo: carId)
        .orderBy('date', descending: true)
        .limit(5)
        .snapshots();
    var maintenanceStream = FirebaseFirestore.instance
        .collection('maintenance')
        .where('userId', isEqualTo: currentUserId)
        .where('carId', isEqualTo: carId)
        .orderBy('date', descending: true)
        .limit(5)
        .snapshots();
    return CombineLatestStream.list([fuelStream, maintenanceStream]).map((
      snapshots,
    ) {
      List<Map<String, dynamic>> combined = [];
      for (int i = 0; i < snapshots.length; i++) {
        var snap = snapshots[i] as QuerySnapshot;
        for (var doc in snap.docs) {
          var data = doc.data() as Map<String, dynamic>;
          combined.add({
            ...data,
            'id': doc.id,
            'activityType': i == 0 ? 'Fuel' : 'Maintenance',
          });
        }
      }
      combined.sort(
        (a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp),
      );
      return combined.take(5).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(key: _pageKeys[0]),
      AnalysisPage(userId: currentUserId, carId: carId),
      RemindersPage(userId: currentUserId, carId: carId),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pages[_selectedIndex],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHomeContent({Key? key}) {
    return SafeArea(
      child: SingleChildScrollView(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 10),
            _buildCarInfoSubtitle(),
            const SizedBox(height: 25),
            _buildDynamicHealthCard(),
            const SizedBox(height: 15),
            _buildMonthlyExpenseCard(),
            const SizedBox(height: 30),
            const Text(
              "Quick Actions",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildMenuGrid(),
            const SizedBox(height: 30),
            _buildRecentActivitySection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        String name = _cachedName;
        String gender = _cachedGender;

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          name = userData['name'] ?? "Driver";
          gender = userData['gender'] ?? "Male";
          _updateUserCache(name, gender);
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedName == "Loading...") {
          return const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            CircleAvatar(
              radius: 25,
              backgroundColor: accentColor.withOpacity(0.1),
              child: Icon(
                gender == 'Male' ? Icons.face_retouching_natural : Icons.face_3,
                color: gender == 'Male' ? Colors.blueAccent : Colors.pinkAccent,
                size: 30,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarInfoSubtitle() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('car_info')
          .doc('details')
          .snapshots(),
      builder: (context, snapshot) {
        String displayCarName = "My Car";
        Color carIconColor = Colors.black;

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          String brand = data['brand']?.toString().trim() ?? "";
          String model = data['model']?.toString().trim() ?? "";
          String colorFromDb =
              data['color']?.toString().toLowerCase().trim() ?? "";

          if (brand.isNotEmpty || model.isNotEmpty) {
            displayCarName = "$brand $model".trim();
          }
          carIconColor = _parseColor(colorFromDb);
          _updateCarCache(displayCarName);
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedCarName == "Loading...") {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              color: Colors.white10,
            ),
          );
        }

        return Row(
          children: [
            Icon(
              Icons.directions_car_filled_rounded,
              color: carIconColor,
              size: 18,
              shadows: carIconColor == Colors.black
                  ? [const Shadow(color: Colors.white12, blurRadius: 2)]
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              displayCarName,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDynamicHealthCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('cars')
          .doc(carId)
          .collection('efficiency')
          .doc('latest_report')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildHealthUI(_cachedHealth, "Offline Mode", Colors.grey);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerHealthCard();
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildHealthUI(100, "Excellent", accentColor);
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        int health = data['overallHealth'] ?? 100;
        _updateHealthCache(health);

        String status = health >= 90
            ? "Excellent"
            : health >= 70
            ? "Good"
            : "Needs Attention";
        Color sColor = health >= 90
            ? accentColor
            : health >= 70
            ? Colors.green
            : Colors.orange;

        return _buildHealthUI(health, status, sColor);
      },
    );
  }

  Widget _buildHealthUI(int health, String status, Color sColor) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [sColor, sColor.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: sColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Car Health", style: TextStyle(color: Colors.white70)),
              Text(
                "$status ($health%)",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 40),
        ],
      ),
    );
  }

  Widget _buildShimmerHealthCard() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
      ),
    );
  }

  Widget _buildMonthlyExpenseCard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream:
          CombineLatestStream.list([
            FirebaseFirestore.instance
                .collection('fuels')
                .where('userId', isEqualTo: currentUserId)
                .snapshots(),
            FirebaseFirestore.instance
                .collection('maintenance')
                .where('userId', isEqualTo: currentUserId)
                .snapshots(),
          ]).map((snapshots) {
            double currentMonthTotal = 0;
            double lastMonthTotal = 0;
            DateTime now = DateTime.now();
            DateTime lastMonth = DateTime(now.year, now.month - 1);

            for (var snap in snapshots) {
              for (var doc in snap.docs) {
                DateTime date = (doc['date'] as Timestamp).toDate();
                double cost =
                    (doc.data()).containsKey(
                      'totalCost',
                    )
                    ? (doc['totalCost'] as num).toDouble()
                    : (doc['cost'] as num).toDouble();

                if (date.month == now.month && date.year == now.year) {
                  currentMonthTotal += cost;
                } else if (date.month == lastMonth.month &&
                    date.year == lastMonth.year) {
                  lastMonthTotal += cost;
                }
              }
            }
            return [
              {'current': currentMonthTotal, 'last': lastMonthTotal},
            ];
          }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerExpenseCard();
        }

        double current = snapshot.data != null
            ? snapshot.data![0]['current']
            : 0;
        double last = snapshot.data != null ? snapshot.data![0]['last'] : 0;
        double difference = current - last;
        bool isMore = difference > 0;
        double percent = last != 0 ? (difference.abs() / last) * 100 : 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D7DFF), Color(0xFF1A1F30)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D7DFF).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat(
                            'MMMM yyyy',
                          ).format(DateTime.now()).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Monthly Spending",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${NumberFormat('#,###').format(current)} EGP",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (last > 0)
                      Row(
                        children: [
                          Icon(
                            isMore
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: isMore
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isMore
                                  ? "${NumberFormat('#,###').format(difference.abs())} EGP (${percent.toStringAsFixed(0)}%) More"
                                  : "${NumberFormat('#,###').format(difference.abs())} EGP (${percent.toStringAsFixed(0)}%) Less",
                              style: TextStyle(
                                color: isMore
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        "First month tracking",
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerExpenseCard() {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF2D7DFF),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildMenuCard(
          "Expenses",
          Icons.account_balance_wallet_rounded,
          Colors.orange,
          () => _navTo(ExpensesPage(userId: currentUserId, carId: carId)),
        ),
        _buildMenuCard(
          "Efficiency",
          Icons.auto_graph_rounded,
          Colors.blue,
          () => _navTo(EfficiencyPage(userId: currentUserId, carId: carId)),
        ),
        _buildMenuCard(
          "Maintenance",
          Icons.build_circle_rounded,
          Colors.green,
          () => _navTo(MaintenancePage(userId: currentUserId, carId: carId)),
        ),
        _buildMenuCard(
          "Fuel",
          Icons.local_gas_station_rounded,
          Colors.purple,
          () => _navTo(FuelPage(userId: currentUserId, carId: carId)),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Activity",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getCombinedActivity(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "No records yet",
                  style: TextStyle(color: Colors.white24),
                ),
              );
            }
            return Column(
              children: snapshot.data!.map((item) {
                bool isFuel = item['activityType'] == 'Fuel';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: (isFuel ? Colors.purple : Colors.green)
                            .withOpacity(0.1),
                        child: Icon(
                          isFuel
                              ? Icons.local_gas_station_rounded
                              : Icons.build_circle_rounded,
                          color: isFuel
                              ? Colors.purpleAccent
                              : Colors.greenAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFuel
                                  ? "Fuel Fill-up"
                                  : (item['serviceName'] ?? "Service"),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'dd MMM, hh:mm a',
                              ).format((item['date'] as Timestamp).toDate()),
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${(item['totalCost'] ?? item['cost'] ?? 0).toStringAsFixed(0)} EGP",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: cardColor,
      selectedItemColor: accentColor,
      unselectedItemColor: Colors.white24,
      showSelectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          label: "Analysis",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_active),
          label: "Alerts",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: "Profile",
        ),
      ],
    );
  }

  void _navTo(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (c) => page));
}
