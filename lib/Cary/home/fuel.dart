// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FuelPage extends StatefulWidget {
  final String userId;
  final String carId;

  const FuelPage({super.key, required this.userId, required this.carId});

  @override
  State<FuelPage> createState() => _FuelPageState();
}

class _FuelPageState extends State<FuelPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Controllers
  final TextEditingController litersController = TextEditingController();
  final TextEditingController totalCostController = TextEditingController();
  final TextEditingController odometerController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  
  // المتغيرات المجلوبة من صفحة Efficiency
  double? storedFuelConsumption; 
  double estimatedRange = 0;    

  // Design Identity
final Color accentColor = Colors.purple; // اللون البنفسجي الأساسي
  final Color cardColor = const Color(0xFF1A1F30);
  final Color bgColor = const Color(0xFF0B0E14);
  final Color fuelAccent = Colors.purple.shade200;

  @override
  void initState() {
    super.initState();
    _loadEfficiencyData(); 
    litersController.addListener(_calculateRange);
  }

  @override
  void dispose() {
    litersController.removeListener(_calculateRange);
    litersController.dispose();
    totalCostController.dispose();
    odometerController.dispose();
    super.dispose();
  }

  // جلب معدل الاستهلاك (كم/لتر)
  Future<void> _loadEfficiencyData() async {
    try {
      DocumentSnapshot doc = await firestore
          .collection('users').doc(widget.userId)
          .collection('cars').doc(widget.carId)
          .collection('efficiency').doc('latest_report')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          // الآن القيمة المخزنة تعبر عن (كم/لتر)
          storedFuelConsumption = (data['fuelConsumption'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      debugPrint("Error fetching efficiency: $e");
    }
  }

  // --- المعادلة الجديدة المحدثة ---
  void _calculateRange() {
    final double? liters = double.tryParse(litersController.text);
    if (liters != null && storedFuelConsumption != null && storedFuelConsumption! > 0) {
      setState(() {
        // الحسبة أصبحت: اللترات مضروبة في الكيلومترات لكل لتر
        estimatedRange = liters * storedFuelConsumption!;
      });
    } else {
      setState(() {
        estimatedRange = 0;
      });
    }
  }

  Future<void> _deleteSingleLog(String docId) async {
    try {
      await firestore.collection('fuels').doc(docId).delete();
      if (mounted) _showStatusSnackBar('Deleted🗑️', Colors.orangeAccent);
    } catch (e) {
      if (mounted) _showStatusSnackBar('Error: $e', Colors.redAccent);
    }
  }

  void _showDeleteDialog(String docId, String details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('Delete record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Delete $details from history?', 
          style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              _deleteSingleLog(docId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> addFuelEntry() async {
    final double? liters = double.tryParse(litersController.text);
    final double? totalCost = double.tryParse(totalCostController.text);
    final double? odometer = double.tryParse(odometerController.text);

    if (liters == null || totalCost == null || liters <= 0 || totalCost <= 0) {
      _showStatusSnackBar('Please enter liters and total cost! ⛽', Colors.orangeAccent);
      return;
    }

    setState(() => isLoading = true);
    FocusScope.of(context).unfocus(); 

    try {
      await firestore.collection('fuels').add({
        'userId': widget.userId,
        'carId': widget.carId,
        'date': Timestamp.fromDate(selectedDate),
        'liters': liters,
        'totalCost': totalCost,
        'pricePerLiter': totalCost / liters,
        'odometer': odometer ?? 0,
        'estimatedRange': estimatedRange, 
        'createdAt': FieldValue.serverTimestamp(),
      });

      litersController.clear();
      totalCostController.clear();
      odometerController.clear();
      setState(() {
        selectedDate = DateTime.now();
        estimatedRange = 0;
      });
      
      if (mounted) _showStatusSnackBar('Saved ✨', accentColor);
    } catch (e) {
      if (mounted) _showStatusSnackBar('Erorr: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showStatusSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center), 
        backgroundColor: color, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Fuel Archive', 
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            _buildInputSection(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.white24, size: 14),
                  SizedBox(width: 8),
                  Text("Fueling History", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(child: _buildGroupedLogsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          // --- بطاقة حساب المسافة المحدثة ---
          if (storedFuelConsumption != null && estimatedRange > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: accentColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      "Estimated Range: ${estimatedRange.toStringAsFixed(0)} KM",
                      textAlign: TextAlign.right,
                      style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.directions_car_filled_rounded, color: accentColor, size: 20),
                ],
              ),
            ),
            
          Row(
            children: [
              Expanded(child: _buildCustomField(litersController, 'Liters', Icons.local_gas_station_rounded, 'L')),
              const SizedBox(width: 12),
              Expanded(child: _buildCustomField(totalCostController, 'Total Cost', Icons.monetization_on_rounded, 'EGP')),
            ],
          ),
          const SizedBox(height: 15),
          _buildCustomField(odometerController, 'Current Odometer(Optional)', Icons.speed_rounded, 'KM'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                    decoration: BoxDecoration(
                      color: bgColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: accentColor),
                        const SizedBox(width: 10),
                        Text(DateFormat('MMM dd, yyyy').format(selectedDate), 
                             style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : addFuelEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      elevation: 4,
                      shadowColor: accentColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Record', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGroupedLogsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('fuels')
          .where('userId', isEqualTo: widget.userId)
          .where('carId', isEqualTo: widget.carId)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Connection Error", style: TextStyle(color: Colors.redAccent.withOpacity(0.5))));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        Map<String, Map<String, List<QueryDocumentSnapshot>>> groupedData = {};
        for (var doc in docs) {
          DateTime date = (doc['date'] as Timestamp).toDate();
          String year = DateFormat('yyyy').format(date);
          String month = DateFormat('MMMM').format(date);

          groupedData.putIfAbsent(year, () => {});
          groupedData[year]!.putIfAbsent(month, () => []);
          groupedData[year]![month]!.add(doc);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          physics: const BouncingScrollPhysics(),
          itemCount: groupedData.length,
          itemBuilder: (context, index) {
            String year = groupedData.keys.elementAt(index);
            var months = groupedData[year]!;
            double yearTotal = 0;
            for (var mList in months.values) {
              for (var d in mList) {
                yearTotal += (d['totalCost'] ?? 0);
              }
            }
            return _buildYearCard(year, yearTotal, months);
          },
        );
      },
    );
  }

  Widget _buildYearCard(String year, double total, Map<String, List<QueryDocumentSnapshot>> months) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: accentColor,
          collapsedIconColor: Colors.white24,
          title: Text(year, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: Text("Total: ${NumberFormat('#,###').format(total)} EGP", 
                       style: TextStyle(color: accentColor.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
          children: months.entries.map((mEntry) {
            // ignore: avoid_types_as_parameter_names
            double mTotal = mEntry.value.fold(0, (sum, d) => sum + (d['totalCost'] ?? 0));
            return _buildMonthSection(mEntry.key, mTotal, mEntry.value);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthSection(String month, double total, List<QueryDocumentSnapshot> docs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bgColor.withOpacity(0.3), borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Text(month, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: Text("${total.toInt()} EGP", style: const TextStyle(color: Colors.white38, fontSize: 12)),
        children: docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp).toDate();
          return GestureDetector(
            onLongPress: () => _showDeleteDialog(doc.id, "${data['liters']} L"),
            child: _buildLogTile(data, date),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> data, DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.02)))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.local_gas_station_rounded, color: accentColor, size: 18),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data['liters']} L', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(DateFormat('EEE, dd MMM').format(date), style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${data['totalCost']} EGP', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
              if (data['odometer'] != 0) 
                Text('${NumberFormat('#,###').format(data['odometer'])} KM', 
                     style: TextStyle(color: fuelAccent.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomField(TextEditingController controller, String hint, IconData icon, String unit) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: accentColor, size: 18),
        suffixText: unit,
        suffixStyle: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        filled: true,
        fillColor: bgColor.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: accentColor.withOpacity(0.3))),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ev_station_rounded, size: 70, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 15),
          const Text("No fuel records yet", style: TextStyle(color: Colors.white24, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: accentColor, onPrimary: Colors.white, surface: cardColor),
          dialogBackgroundColor: bgColor,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }
}