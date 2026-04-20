// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MaintenancePage extends StatefulWidget {
  final String userId;
  final String carId;

  const MaintenancePage({super.key, required this.userId, required this.carId});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  // Controllers
  final TextEditingController serviceController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String selectedCategory = 'General Repair';
  bool isLoading = false;

  final List<String> categories = [
    'Oil Change', 'Brake System', 'Battery', 'Tires', 
    'Engine', 'General Repair', 'AC Service', 'Car Wash',
    'Garage/Parking', 'Accessories',
  ];

  // Colors
  final Color accentColor = const Color(0xFF00C853); // Maintenance Green
  final Color cardColor = const Color(0xFF1A1F30);
  final Color bgColor = const Color(0xFF0B0E14);

  @override
  void dispose() {
    serviceController.dispose();
    costController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // --- Delete Logic ---
  Future<void> _deleteSingleMaintenance(String docId) async {
    try {
      await firestore.collection('maintenance').doc(docId).delete();
      if (mounted) _showSnackBar('Record removed 🗑️', Colors.orangeAccent);
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.redAccent);
    }
  }

  void _showDeleteDialog(String docId, String serviceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('Delete Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Delete "$serviceName" from history?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              _deleteSingleMaintenance(docId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Save Logic ---
  Future<void> addMaintenanceEntry() async {
    final String service = serviceController.text.trim();
    final double? cost = double.tryParse(costController.text);

    if (service.isEmpty || cost == null || cost <= 0) {
      _showSnackBar('Please enter service name and cost! 🛠️', Colors.orangeAccent);
      return;
    }

    setState(() => isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      await firestore.collection('maintenance').add({
        'userId': widget.userId,
        'carId': widget.carId,
        'category': selectedCategory,
        'serviceName': service,
        'cost': cost,
        'description': descriptionController.text.trim(),
        'date': Timestamp.fromDate(selectedDate),
        'createdAt': FieldValue.serverTimestamp(),
      });

      serviceController.clear();
      costController.clear();
      descriptionController.clear();
      setState(() => selectedDate = DateTime.now());
      
      if (mounted) _showSnackBar('Service record saved! ✅', accentColor);
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: color, 
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Maintenance Archive', 
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
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: Row(
                children: [
                  Icon(Icons.history_edu_rounded, color: Colors.white24, size: 14),
                  SizedBox(width: 8),
                  Text("SERVICE HISTORY", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(child: _buildGroupedMaintenanceList()),
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
          DropdownButtonFormField<String>(
            value: selectedCategory,
            dropdownColor: cardColor,
            elevation: 16,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: _inputDecoration('Category', Icons.grid_view_rounded),
            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => selectedCategory = val!),
          ),
          const SizedBox(height: 12),
          _buildCustomField(serviceController, 'Service Detail (e.g. Brake Pads)', Icons.handyman_rounded),
          const SizedBox(height: 12),
          _buildCustomField(costController, 'Cost (EGP)', Icons.payments_rounded, isNumber: true),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: bgColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note_rounded, size: 16, color: accentColor),
                        const SizedBox(width: 10),
                        Text(DateFormat('MMM dd, yyyy').format(selectedDate), 
                             style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                    onPressed: isLoading ? null : addMaintenanceEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      elevation: 4,
                      shadowColor: accentColor.withOpacity(0.3),
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

  Widget _buildGroupedMaintenanceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('maintenance')
          .where('userId', isEqualTo: widget.userId)
          .where('carId', isEqualTo: widget.carId)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error', style: TextStyle(color: Colors.white24)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
        
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
                yearTotal += (d['cost'] ?? 0);
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
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text("${NumberFormat('#,###').format(total)} EGP", 
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          children: months.entries.map((mEntry) {
            // ignore: avoid_types_as_parameter_names
            double mTotal = mEntry.value.fold(0, (sum, d) => sum + (d['cost'] ?? 0));
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
        title: Text(month, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: Text("${total.toInt()} EGP", style: const TextStyle(color: Colors.white38, fontSize: 12)),
        children: docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp).toDate();
          return GestureDetector(
            onLongPress: () => _showDeleteDialog(doc.id, data['serviceName']),
            child: _buildLogTile(data, date),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> data, DateTime date) {
    IconData getCategoryIcon(String category) {
      switch (category) {
        case 'Oil Change': return Icons.oil_barrel_rounded;
        case 'Brake System': return Icons.settings_backup_restore_rounded;
        case 'Battery': return Icons.battery_charging_full_rounded;
        case 'Tires': return Icons.tire_repair_rounded;
        case 'AC Service': return Icons.ac_unit_rounded;
        case 'Car Wash': return Icons.local_car_wash_rounded;
        case 'Garage/Parking': return Icons.local_parking_rounded;
        case 'Accessories': return Icons.settings_input_component_rounded;
        default: return Icons.handyman_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.02)))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(getCategoryIcon(data['category']), size: 18, color: accentColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['serviceName'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(DateFormat('dd MMM, yyyy').format(date), style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(NumberFormat('#,###').format(data['cost']), 
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
              const Text("EGP", style: TextStyle(color: Colors.white10, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      decoration: _inputDecoration(hint, icon),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: accentColor, size: 20),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
      filled: true,
      fillColor: bgColor.withOpacity(0.6),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: accentColor.withOpacity(0.3))),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle_outlined, size: 70, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 15),
          const Text("No service records found", style: TextStyle(color: Colors.white24, fontSize: 14, fontWeight: FontWeight.bold)),
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
          colorScheme: ColorScheme.dark(primary: accentColor, onPrimary: Colors.white, surface: cardColor), dialogTheme: DialogThemeData(backgroundColor: bgColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }
}