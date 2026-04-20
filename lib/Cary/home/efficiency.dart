// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EfficiencyPage extends StatefulWidget {
  final String userId;
  final String carId;

  const EfficiencyPage({super.key, required this.userId, required this.carId});

  @override
  State<EfficiencyPage> createState() => _EfficiencyPageState();
}

class _EfficiencyPageState extends State<EfficiencyPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Controllers
  final TextEditingController modelController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController mileageController = TextEditingController();
  final TextEditingController fuelConsController = TextEditingController();

  bool isLoading = false;
  bool isPageLoading = true;

  // القائمة الشاملة المحدثة (16 جزء)
  Map<String, dynamic> partsStatus = {
    'Engine': 'Excellent',
    'Transmission': 'Excellent',
    'Brakes': 'Excellent',
    'Steering System': 'Excellent',
    'Suspension': 'Excellent',
    'Battery': 'Excellent',
    'Tyres': 'Excellent',
    'Cooling System': 'Excellent',
    'Fuel System': 'Excellent',
    'Air Conditioning': 'Excellent',
    'Electrical System': 'Excellent',
    'Exhaust System': 'Excellent',
    'Oil & Fluids': 'Excellent',
    'Lights & Signals': 'Excellent',
    'Body & Paint': 'Excellent',
    'Interior State': 'Excellent',
  };

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    modelController.dispose();
    yearController.dispose();
    mileageController.dispose();
    fuelConsController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      DocumentSnapshot doc = await firestore
          .collection('users').doc(widget.userId)
          .collection('cars').doc(widget.carId)
          .collection('efficiency').doc('latest_report')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          modelController.text = data['model'] ?? '';
          yearController.text = data['year']?.toString() ?? '';
          mileageController.text = data['mileage']?.toString() ?? '';
          // تأكدنا هنا أنه لو كانت القيمة 0 أو null لا يضعها في النص ليظهر الـ Hint
          String savedFuel = data['fuelConsumption']?.toString() ?? '';
          fuelConsController.text = (savedFuel == '0' || savedFuel == '0.0') ? '' : savedFuel;
          
          partsStatus = Map<String, dynamic>.from(data['partsStatus'] ?? partsStatus);
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      if (mounted) setState(() => isPageLoading = false);
    }
  }

  // --- خوارزمية الحساب المحدثة (تم تعديل منطق الوقود) ---
  double calculateOverallHealth() {
    double baseScore = 100.0;
    int currentYear = DateTime.now().year;
    
    // 1. الخصم بناءً على عمر السيارة
    int year = int.tryParse(yearController.text) ?? currentYear;
    baseScore -= (currentYear - year) * 1.2;

    // 2. الخصم بناءً على الممشى
    double mileage = double.tryParse(mileageController.text) ?? 0;
    baseScore -= (mileage / 40000) * 2.0;

    // 3. التعديل الجوهري: الخصم بناءً على استهلاك البنزين (كم/لتر)
    // الآن: إذا كان الحقل فارغاً، لا يتم خصم أي نقاط ولا يؤثر على الهيلث
    String fuelText = fuelConsController.text.trim();
    if (fuelText.isNotEmpty) {
      double kmPerLiter = double.tryParse(fuelText) ?? 12;
      if (kmPerLiter < 12) {
        baseScore -= (12 - kmPerLiter) * 5.0; // خصم فقط إذا كانت الكفاءة أقل من 12
      } else if (kmPerLiter > 15) {
        baseScore += 5.0; // مكافأة إضافية إذا كانت السيارة موفرة جداً
      }
    }

    // 4. حساب حالة الأجزاء
    double weightedSum = 0;
    double totalWeight = 0;

    Map<String, double> weights = {
      'Engine': 4.0, 'Transmission': 3.5, 'Brakes': 3.0,
      'Steering System': 2.0, 'Suspension': 2.0, 'Cooling System': 2.0,
      'Fuel System': 2.0, 'Battery': 1.5, 'Tyres': 1.5,
      'Electrical System': 1.5, 'Oil & Fluids': 1.5,
      'Exhaust System': 1.0, 'Air Conditioning': 1.0,
      'Lights & Signals': 0.8, 'Body & Paint': 0.7, 'Interior State': 0.5,
    };

    partsStatus.forEach((key, value) {
      double weight = weights[key] ?? 1.0;
      double val;
      switch (value) {
        case 'Excellent': val = 100; break;
        case 'Good': val = 80; break;
        case 'Fair': val = 50; break;
        case 'Needs Service': val = 15; break;
        default: val = 100;
      }
      weightedSum += (val * weight);
      totalWeight += weight;
    });
    
    double partsAvg = weightedSum / totalWeight;
    return ((baseScore + partsAvg) / 2).clamp(0, 100);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Excellent': return Colors.greenAccent;
      case 'Good': return Colors.blueAccent;
      case 'Fair': return Colors.orangeAccent;
      case 'Needs Service': return Colors.redAccent;
      default: return Colors.white;
    }
  }

  IconData _getPartIcon(String part) {
    switch (part) {
      case 'Engine': return Icons.settings_applications;
      case 'Transmission': return Icons.alt_route;
      case 'Brakes': return Icons.stop_circle_outlined;
      case 'Battery': return Icons.battery_charging_full;
      case 'Tyres': return Icons.panorama_fish_eye;
      case 'Cooling System': return Icons.ac_unit;
      case 'Fuel System': return Icons.local_gas_station;
      case 'Steering System': return Icons.explore_outlined;
      case 'Suspension': return Icons.shutter_speed;
      case 'Electrical System': return Icons.electric_bolt;
      case 'Air Conditioning': return Icons.air;
      case 'Exhaust System': return Icons.co2;
      case 'Oil & Fluids': return Icons.water_drop;
      case 'Lights & Signals': return Icons.lightbulb;
      case 'Body & Paint': return Icons.format_paint;
      case 'Interior State': return Icons.chair;
      default: return Icons.settings;
    }
  }

  Future<void> updateReport() async {
    setState(() => isLoading = true);
    try {
      double health = calculateOverallHealth();

      await firestore
          .collection('users').doc(widget.userId)
          .collection('cars').doc(widget.carId)
          .collection('efficiency').doc('latest_report')
          .set({
        'userId': widget.userId,
        'carId': widget.carId,
        'model': modelController.text.trim(),
        'year': yearController.text.trim(),
        'mileage': double.tryParse(mileageController.text) ?? 0,
        // خزن القيمة المدخلة أو 0 لو فارغة
        'fuelConsumption': double.tryParse(fuelConsController.text) ?? 0,
        'partsStatus': partsStatus,
        'overallHealth': health.toInt(),
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car Analysis Completed! 🚀'), backgroundColor: Color(0xFF246BFE)),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isPageLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0E14),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF246BFE))),
      );
    }

    double health = calculateOverallHealth();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        title: const Text('Efficiency Radar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildMainHealthCard(health),
            const SizedBox(height: 25),
            _buildQuickInputSection(),
            const SizedBox(height: 30),
            _buildSectionHeader("Full System Diagnoses", Icons.analytics_outlined),
            const SizedBox(height: 15),
            _buildPartsGrid(),
            const SizedBox(height: 30),
            _buildUpdateActionButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMainHealthCard(double health) {
    Color color = health > 75 ? Colors.greenAccent : (health > 45 ? Colors.orangeAccent : Colors.redAccent);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 130, width: 130,
                child: CircularProgressIndicator(
                  value: health / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${health.toInt()}%", style: TextStyle(color: color, fontSize: 38, fontWeight: FontWeight.bold)),
                  const Text("SCORE", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            health > 75 ? "Your vehicle is in optimal condition" : "Some systems require your attention",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161A26),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          _buildModernField(modelController, "Car Model", Icons.directions_car),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildModernField(yearController, "Year", Icons.calendar_today, isNum: true)),
              const SizedBox(width: 15),
              Expanded(child: _buildModernField(mileageController, "Mileage", Icons.speed, isNum: true)),
            ],
          ),
          const SizedBox(height: 15),
          // تم تحديث الحقل ليقبل الـ Hint بشكل صحيح
          _buildModernField(
            fuelConsController, 
            "Fuel Consumption (Km/L)", 
            Icons.local_gas_station, 
            isNum: true,
            hint: "How many km per liter?",
          ),
        ],
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, {bool isNum = false, String? hint}) {
    return TextField(
      controller: controller,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      // الـ setState هنا مهمة لتحديث الـ Score في الـ UI لحظياً
      onChanged: (value) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white10, fontSize: 12),
        labelStyle: const TextStyle(color: Colors.white30, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF246BFE), size: 20),
        filled: true,
        fillColor: const Color(0xFF0B0E14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF246BFE), size: 22),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPartsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.45,
      ),
      itemCount: partsStatus.length,
      itemBuilder: (context, index) {
        String part = partsStatus.keys.elementAt(index);
        String status = partsStatus[part];
        return _buildPartCard(part, status);
      },
    );
  }

  Widget _buildPartCard(String part, String status) {
    Color statusColor = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161A26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getPartIcon(part), color: Colors.white38, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(part, 
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)
                ),
              ),
            ],
          ),
          const Spacer(),
          DropdownButton<String>(
            value: status,
            isExpanded: true,
            dropdownColor: const Color(0xFF1A1F30),
            underline: const SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: statusColor, size: 18),
            items: ['Excellent', 'Good', 'Fair', 'Needs Service'].map((s) => 
              DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: _getStatusColor(s), fontSize: 11, fontWeight: FontWeight.bold)))
            ).toList(),
            onChanged: (val) {
              if (val != null) setState(() => partsStatus[part] = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateActionButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: const Color(0xFF246BFE).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF246BFE),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 0,
        ),
        onPressed: isLoading ? null : updateReport,
        child: isLoading 
          ? const CircularProgressIndicator(color: Colors.white) 
          : const Text("GENERATE ANALYSIS REPORT", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}