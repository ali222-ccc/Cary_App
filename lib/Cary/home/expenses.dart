// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExpensesPage extends StatefulWidget {
  final String userId;
  final String carId;

  const ExpensesPage({super.key, required this.userId, required this.carId});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final Color accentColor = const Color(0xFF2D7DFF);
  final Color fuelColor = Colors.orangeAccent;
  final Color maintenanceColor = const Color(0xFF00C853);
  final Color cardColor = const Color(0xFF1A1F30);
  final Color bgColor = const Color(0xFF0B0E14);

  Stream<List<Map<String, dynamic>>> getAllExpenses() {
    var fuelStream = firestore
        .collection('fuels')
        .where('userId', isEqualTo: widget.userId)
        .where('carId', isEqualTo: widget.carId)
        .snapshots();

    var maintenanceStream = firestore
        .collection('maintenance')
        .where('userId', isEqualTo: widget.userId)
        .where('carId', isEqualTo: widget.carId)
        .snapshots();

    return CombineLatestStream.list([fuelStream, maintenanceStream]).map((
      snapshots,
    ) {
      List<Map<String, dynamic>> allLogs = [];

      for (var doc in snapshots[0].docs) {
        var data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'fuel';
        data['collection'] = 'fuels';
        data['displayTitle'] = 'Fuel Refill';
        data['subtitle'] = '${data['liters']} Liters added';
        data['amount'] = (data['totalCost'] as num).toDouble();
        allLogs.add(data);
      }

      for (var doc in snapshots[1].docs) {
        var data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'maintenance';
        data['collection'] = 'maintenance';
        data['displayTitle'] = data['serviceName'] ?? 'Service';
        data['subtitle'] = data['category'] ?? 'General';
        data['amount'] = (data['cost'] as num).toDouble();
        allLogs.add(data);
      }

      allLogs.sort(
        (a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp),
      );
      return allLogs;
    });
  }

  // --- دوال تصدير الـ PDF ---

  void _showExportOptions(
    BuildContext context,
    List<Map<String, dynamic>> allLogs,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Export Financial Report",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              _buildExportTile(
                context,
                "Monthly Report",
                Icons.calendar_month_rounded,
                () => _showMonthPicker(context, allLogs),
              ),
              _buildExportTile(
                context,
                "Yearly Report",
                Icons.calendar_today_rounded,
                () => _showYearPicker(context, allLogs),
              ),
              _buildExportTile(
                context,
                "Lifetime Report",
                Icons.all_inclusive_rounded,
                () => _generatePDF(allLogs, "Lifetime Report"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: accentColor),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showMonthPicker(
    BuildContext context,
    List<Map<String, dynamic>> allLogs,
  ) {
    int selectedYear = DateTime.now().year;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Month",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: DropdownButton<int>(
                    value: selectedYear,
                    dropdownColor: cardColor,
                    underline: const SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: accentColor),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                    items:
                        List.generate(
                              DateTime.now().year - 2020 + 1,
                              (index) => 2020 + index,
                            ).reversed
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedYear = val);
                    },
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.8,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  String monthName = DateFormat(
                    'MMM',
                  ).format(DateTime(2024, index + 1));
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _filterAndGenerate(
                        allLogs,
                        index + 1,
                        selectedYear,
                        "monthly",
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        monthName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showYearPicker(
    BuildContext context,
    List<Map<String, dynamic>> allLogs,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Select Year",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 5,
            itemBuilder: (context, index) {
              int year = DateTime.now().year - index;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Center(
                  child: Text(
                    year.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _filterAndGenerate(allLogs, 1, year, "yearly");
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _filterAndGenerate(
    List<Map<String, dynamic>> allLogs,
    int month,
    int year,
    String type,
  ) {
    List<Map<String, dynamic>> filtered;
    String label;
    if (type == "monthly") {
      filtered = allLogs.where((log) {
        DateTime d = (log['date'] as Timestamp).toDate();
        return d.month == month && d.year == year;
      }).toList();
      label =
          "Monthly Report - ${DateFormat('MMMM').format(DateTime(2024, month))} $year";
    } else {
      filtered = allLogs.where((log) {
        DateTime d = (log['date'] as Timestamp).toDate();
        return d.year == year;
      }).toList();
      label = "Yearly Report - $year";
    }
    _generatePDF(filtered, label);
  }

  Future<void> _generatePDF(
    List<Map<String, dynamic>> items,
    String title,
  ) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No data found for the selected period"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final pdf = pw.Document();
    // ignore: avoid_types_as_parameter_names
    final total = items.fold(0.0, (sum, item) => sum + item['amount']);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              "CARY - Financial Report",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text("Type: $title"),
          pw.Text(
            "Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
          ),
          pw.Divider(),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Type', 'Description', 'Amount (EGP)'],
            data: items
                .map(
                  (item) => [
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format((item['date'] as Timestamp).toDate()),
                    item['type'].toString().toUpperCase(),
                    item['displayTitle'],
                    NumberFormat('#,###.00').format(item['amount']),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 30),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "TOTAL SPENDING: ${NumberFormat('#,###.00').format(total)} EGP",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Cary_Report.pdf',
    );
  }

  Future<void> _deleteLog(String collection, String docId) async {
    try {
      await firestore.collection(collection).doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Record deleted successfully"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getAllExpenses(),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text(
              'Financial Report',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2D7DFF)),
                )
              : logs.isEmpty
              ? _buildEmptyState()
              : _buildMainList(logs),
        );
      },
    );
  }

  Widget _buildMainList(List<Map<String, dynamic>> logs) {
    double totalFuel = 0;
    double totalMaint = 0;
    for (var item in logs) {
      if (item['type'] == 'fuel') totalFuel += item['amount'];
      if (item['type'] == 'maintenance') totalMaint += item['amount'];
    }

    Map<String, Map<String, List<Map<String, dynamic>>>> groupedData = {};
    for (var log in logs) {
      DateTime date = (log['date'] as Timestamp).toDate();
      String year = DateFormat('yyyy').format(date);
      String month = DateFormat('MMMM').format(date);
      groupedData.putIfAbsent(year, () => {});
      groupedData[year]!.putIfAbsent(month, () => []);
      groupedData[year]![month]!.add(log);
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // --- زر الـ PDF الجديد (Full Width) تحت العنوان مباشرة ---
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: InkWell(
              onTap: () => _showExportOptions(context, logs),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "EXPORT AS PDF",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(child: _buildSummaryHeader(totalFuel, totalMaint)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            child: Row(
              children: [
                const Icon(
                  Icons.history_toggle_off_rounded,
                  color: Colors.white24,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "TIMELINE HISTORY",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            String year = groupedData.keys.elementAt(index);
            var months = groupedData[year]!;
            double yearTotal = 0;
            for (var mList in months.values) {
              for (var i in mList) {
                yearTotal += i['amount'];
              }
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: _buildYearExpansionCard(year, yearTotal, months),
            );
          }, childCount: groupedData.length),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 50)),
      ],
    );
  }

  Widget _buildSummaryHeader(double fuel, double maint) {
    double total = fuel + maint;
    double fuelRatio = total > 0 ? (fuel / total) : 0.5;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Text(
            "LIFETIME SPENDING",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${NumberFormat('#,###').format(total)} EGP",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 30),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: maintenanceColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fuelRatio,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: fuelColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat(
                "Fueling",
                fuel,
                fuelColor,
                Icons.local_gas_station_rounded,
              ),
              _buildHeaderStat(
                "Service",
                maint,
                maintenanceColor,
                Icons.build_circle_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "${NumberFormat('#,###').format(amount)} EGP",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ],
    );
  }

  Widget _buildYearExpansionCard(
    String year,
    double total,
    Map<String, List<Map<String, dynamic>>> months,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: accentColor,
          collapsedIconColor: Colors.white24,
          title: Text(
            year,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${total.toInt()} EGP",
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          children: months.entries.map((entry) {
            double mTotal = entry.value.fold(
              0,
              // ignore: avoid_types_as_parameter_names
              (sum, item) => sum + item['amount'],
            );
            return _buildMonthSection(entry.key, mTotal, entry.value);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthSection(
    String month,
    double total,
    List<Map<String, dynamic>> items,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        title: Text(
          month,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          "${total.toInt()} EGP",
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        children: items.map((log) => _buildTransactionTile(log)).toList(),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> data) {
    DateTime date = (data['date'] as Timestamp).toDate();
    return Dismissible(
      key: Key(data['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _deleteLog(data['collection'], data['id']),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.03)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd').format(date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: const TextStyle(color: Colors.white24, fontSize: 8),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['displayTitle'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    data['subtitle'],
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "-${NumberFormat('#,###').format(data['amount'])}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  "EGP",
                  style: TextStyle(color: Colors.white10, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 50,
              color: accentColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Financial history is empty",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Start tracking your fuel and services",
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
