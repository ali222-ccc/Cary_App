// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class AnalysisPage extends StatefulWidget {
  final String userId;
  final String carId;

  const AnalysisPage({super.key, required this.userId, required this.carId});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final Color bgColor = const Color(0xFF0B0E14);
  final Color cardColor = const Color(0xFF1A1F30);
  final Color accentColor = const Color(0xFF2D7DFF);
  final Color chartColor = Colors.orangeAccent;

  // --- دمج تدفق البيانات (بنزين + صيانة) ---
  Stream<List<Map<String, dynamic>>> _getCombinedExpenses() {
    var fuelStream = FirebaseFirestore.instance
        .collection('fuels')
        .where('userId', isEqualTo: widget.userId)
        .where('carId', isEqualTo: widget.carId)
        .snapshots();

    var maintenanceStream = FirebaseFirestore.instance
        .collection('maintenance')
        .where('userId', isEqualTo: widget.userId)
        .where('carId', isEqualTo: widget.carId)
        .snapshots();

    return CombineLatestStream.list([fuelStream, maintenanceStream]).map((
      snapshots,
    ) {
      List<Map<String, dynamic>> allExpenses = [];
      for (var snapshot in snapshots) {
        for (var doc in snapshot.docs) {
          var data = doc.data();
          allExpenses.add({
            'date': data['date'],
            'amount': (data['totalCost'] ?? data['cost'] ?? 0.0) as num,
          });
        }
      }
      allExpenses.sort(
        (a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp),
      );
      return allExpenses;
    });
  }

  Stream<Map<String, dynamic>> _getEfficiencyData() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('cars')
        .doc(widget.carId)
        .collection('efficiency')
        .doc('latest_report')
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  double _statusToValue(String status) {
    switch (status) {
      case 'Excellent':
        return 95.0;
      case 'Good':
        return 75.0;
      case 'Fair':
        return 50.0;
      case 'Needs Service':
        return 25.0;
      default:
        return 95.0; // جعل الديفولت للأعمدة أيضاً عالى
    }
  }

  // ودجت لودينج مخصصة للكروت
  Widget _buildLoadingCard({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.orangeAccent,
          strokeWidth: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Car Insights & Reports",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getCombinedExpenses(),
        builder: (context, snapshot) {
          // حالة اللودينج للمستند الأساسي
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            );
          }

          final allData = snapshot.data ?? [];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  "Efficiency Analysis",
                  Icons.analytics_rounded,
                ),
                StreamBuilder<Map<String, dynamic>>(
                  stream: _getEfficiencyData(),
                  builder: (context, effSnapshot) {
                    // إذا كان جاري التحميل، أظهر كارت اللودينج بدل الديفولت
                    if (effSnapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingCard(height: 250);
                    }

                    var effData = effSnapshot.data ?? {};
                    var parts = effData['partsStatus'] as Map<String, dynamic>? ?? {};
                    
                    // القيمة الافتراضية هنا 100% كما طلبت
                    int health = effData['overallHealth'] ?? 100; 
                    
                    return _buildEfficiencyCard(parts, health);
                  },
                ),

                _buildSectionHeader(
                  "Financial Activity",
                  Icons.insights_rounded,
                ),

                if (allData.isEmpty)
                  _buildEmptyState()
                else ...[
                  _buildDynamicExpenseChart(allData),
                  const SizedBox(height: 15),
                  _buildComparisonRow(allData),
                  const SizedBox(height: 15),
                  _buildSixMonthInsightCard(allData),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- كارت كفاءة الأجزاء المطور ---
  Widget _buildEfficiencyCard(Map<String, dynamic> parts, int healthScore) {
    List<String> labels = [
      'Engine',
      'Brakes',
      'Fuel System',
      'Battery',
      'Tyres',
      'Cooling System',
    ];
    bool isHealthLow = healthScore < 60;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isHealthLow
              ? Colors.redAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          width: isHealthLow ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Vehicle Health Index",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$healthScore%",
                    style: TextStyle(
                      color: healthScore >= 60
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (healthScore >= 60 ? accentColor : Colors.redAccent)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  healthScore >= 60
                      ? Icons.verified_user_rounded
                      : Icons.report_problem_rounded,
                  color: healthScore >= 60 ? accentColor : Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: 100,
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(labels.length, (i) {
                  // إذا كانت البيانات فارغة (حالة الـ 100%)، اجعل الأعمدة ممتلئة
                  double val = parts.isEmpty ? 95.0 : _statusToValue(parts[labels[i]] ?? 'Excellent');
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: val < 40
                            ? Colors.redAccent
                            : (val < 70 ? Colors.orangeAccent : accentColor),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: Colors.white.withOpacity(0.02),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          if (isHealthLow) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "How about anew chapter?🚗💨 Your car has been a loyal companion, but it’s starting to hint that it’s time for a well-deserved rest.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- كارت استهلاك 6 شهور ---
  Widget _buildSixMonthInsightCard(List<Map<String, dynamic>> allData) {
    double totalLast6Months = 0;
    DateTime sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));

    for (var item in allData) {
      if (item['date'] != null) {
        DateTime date = (item['date'] as Timestamp).toDate();
        if (date.isAfter(sixMonthsAgo)) totalLast6Months += item['amount'];
      }
    }

    bool shouldChangeCar = totalLast6Months >= 50000;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: shouldChangeCar
              ? Colors.redAccent.withOpacity(0.4)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "6-Month Financial Load",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                shouldChangeCar
                    ? Icons.warning_amber_rounded
                    : Icons.eco_rounded,
                color: shouldChangeCar ? Colors.redAccent : Colors.greenAccent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${NumberFormat('#,###').format(totalLast6Months)} EGP",
            style: TextStyle(
              color: shouldChangeCar ? Colors.redAccent : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 15),
          Divider(color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 10),
          Text(
            shouldChangeCar
                ? "Your expenses are extremely high. Selling might be a wise financial move."
                : "Vehicle expenses are within a healthy range for the last 6 months.",
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- شارت المصروفات المطور ---
  Widget _buildDynamicExpenseChart(List<Map<String, dynamic>> dataList) {
    DateTime now = DateTime.now();
    int lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    Map<int, double> fullMonthMap = {
      for (var i = 1; i <= lastDayOfMonth; i++) i: 0.0,
    };
    double monthlyTotal = 0;
    double maxAmountInDay = 0;

    for (var item in dataList) {
      if (item['date'] == null) continue;
      DateTime date = (item['date'] as Timestamp).toDate();
      if (date.month == now.month && date.year == now.year) {
        fullMonthMap[date.day] = (fullMonthMap[date.day] ?? 0) + item['amount'];
        monthlyTotal += item['amount'];
        if (fullMonthMap[date.day]! > maxAmountInDay) {
          maxAmountInDay = fullMonthMap[date.day]!;
        }
      }
    }

    List<FlSpot> spots = fullMonthMap.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(now),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${NumberFormat('#,###').format(monthlyTotal)} EGP",
                style: TextStyle(
                  color: chartColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxAmountInDay == 0 ? 1000 : maxAmountInDay * 1.3,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.white.withOpacity(0.03)),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(color: Colors.white12, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 7,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: chartColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (s, b) => s.y > 0,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [chartColor.withOpacity(0.2), chartColor.withOpacity(0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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

  Widget _buildComparisonRow(List<Map<String, dynamic>> dataList) {
    double current = 0;
    double previous = 0;
    DateTime now = DateTime.now();
    DateTime lastMonth = DateTime(now.year, now.month - 1);

    for (var item in dataList) {
      if (item['date'] == null) continue;
      DateTime date = (item['date'] as Timestamp).toDate();
      if (date.month == now.month && date.year == now.year) {
        current += item['amount'];
      } else if (date.month == lastMonth.month && date.year == lastMonth.year) {
        previous += item['amount'];
      }
    }

    double diff = current - previous;
    bool isMore = diff > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            isMore ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: isMore ? Colors.redAccent : Colors.greenAccent,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              isMore
                  ? "Spent ${diff.abs().toStringAsFixed(0)} EGP more than last month"
                  : "Saved ${diff.abs().toStringAsFixed(0)} EGP vs last month",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.query_stats_rounded,
            size: 60,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 10),
          const Text(
            "No financial data to analyze.",
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }
}