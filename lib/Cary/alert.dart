// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';

class RemindersPage extends StatefulWidget {
  final String userId;
  final String carId;

  const RemindersPage({super.key, required this.userId, required this.carId});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final Color bgColor = const Color(0xFF0B0E14);
  final Color cardColor = const Color(0xFF1A1F30);
  final Color accentColor = const Color(0xFF2D7DFF); // اللون الأزرق المميز لكاري
  final Color primaryGreen = const Color(0xFF00C853);

  String selectedType = 'Oil Change';
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final TextEditingController customTitleController = TextEditingController();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  // --- دالة مساعدة لاختيار الأيقونة واللون بناءً على النوع ---
  Map<String, dynamic> _getReminderStyle(String type) {
    if (type.contains('Oil')) return {'icon': Icons.opacity, 'color': Colors.orangeAccent};
    if (type.contains('License')) return {'icon': Icons.badge_outlined, 'color': Colors.redAccent};
    if (type.contains('Insurance')) return {'icon': Icons.security, 'color': Colors.blueAccent};
    if (type.contains('Maintenance')) return {'icon': Icons.build_circle_outlined, 'color': Colors.greenAccent};
    return {'icon': Icons.notifications_active_outlined, 'color': accentColor};
  }

  Future<void> _initNotifications() async {
    tz_data.initializeTimeZones();
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);

    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> _deleteReminder(String docId, int? notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users').doc(widget.userId)
          .collection('cars').doc(widget.carId)
          .collection('reminders').doc(docId).delete();
      
      if (notificationId != null) await _notificationsPlugin.cancel(notificationId);
      
      _showSnackBar("Reminder removed! 🗑️", Colors.orangeAccent);
    } catch (e) {
      _showSnackBar("Error deleting reminder", Colors.redAccent);
    }
  }

  Future<void> _saveReminder() async {
    final DateTime fullDateTime = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      selectedTime.hour, selectedTime.minute,
    );

    if (fullDateTime.isBefore(DateTime.now())) {
      _showSnackBar("Time must be in the future!", Colors.redAccent);
      return;
    }

    String finalTitle = customTitleController.text.trim().isEmpty ? selectedType : customTitleController.text.trim();
    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    try {
      await FirebaseFirestore.instance
          .collection('users').doc(widget.userId)
          .collection('cars').doc(widget.carId)
          .collection('reminders').add({
        'type': finalTitle,
        'dateTime': Timestamp.fromDate(fullDateTime),
        'notificationId': notificationId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _scheduleNotification(finalTitle, fullDateTime, notificationId);
      customTitleController.clear();
      _showSnackBar("Reminder locked in! 🚀", primaryGreen);
    } catch (e) {
      _showSnackBar("Cloud connection error", Colors.redAccent);
    }
  }

  Future<void> _scheduleNotification(String title, DateTime scheduledDate, int id) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cary_reminders_v2', 'Cary Alerts',
      importance: Importance.max, priority: Priority.high, playSound: true,
    );
    await _notificationsPlugin.zonedSchedule(
      id, 'Cary Alert 🚗', 'Time for: $title',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Car Alerts", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildInputContainer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Divider(color: Colors.white10, thickness: 1),
            ),
            SizedBox(
              height: 400, // يمكن تعديله أو استخدام Expanded في Column خارجي
              child: _buildRemindersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add New Alert", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildDropdown(),
          const SizedBox(height: 15),
          TextField(
            controller: customTitleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Or type a custom task...",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              prefixIcon: Icon(Icons.edit_calendar_rounded, color: accentColor),
              filled: true, fillColor: bgColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildPickerTile(Icons.calendar_today_rounded, "${selectedDate.day}/${selectedDate.month}", () async {
                DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                if (picked != null) setState(() => selectedDate = picked);
              })),
              const SizedBox(width: 10),
              Expanded(child: _buildPickerTile(Icons.alarm_rounded, selectedTime.format(context), () async {
                TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (picked != null) setState(() => selectedTime = picked);
              })),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: _saveReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 5, shadowColor: accentColor.withOpacity(0.4),
              ),
              child: const Text("Set Alert Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType, dropdownColor: cardColor, isExpanded: true,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          items: ['Oil Change', 'License Renewal', 'Insurance Payment', 'General Maintenance', 'Tire Rotation'].map((String val) {
            return DropdownMenuItem<String>(value: val, child: Text(val));
          }).toList(),
          onChanged: (val) => setState(() => selectedType = val!),
        ),
      ),
    );
  }

  Widget _buildPickerTile(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: bgColor.withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildRemindersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(widget.userId).collection('cars').doc(widget.carId)
          .collection('reminders').orderBy('dateTime').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            DateTime dt = (data['dateTime'] as Timestamp).toDate();
            var style = _getReminderStyle(data['type']);

            return Dismissible(
              key: Key(docs[index].id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(25)),
                child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
              ),
              onDismissed: (_) => _deleteReminder(docs[index].id, data['notificationId']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(25),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: style['color'].withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(style['icon'], color: style['color'], size: 26),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(data['type'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text("${dt.day}/${dt.month}/${dt.year} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}", 
                             style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 15),
          const Text("No pending alerts", style: TextStyle(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.w500)),
          const Text("Your car is in good hands!", style: TextStyle(color: Colors.white10, fontSize: 12)),
        ],
      ),
    );
  }
}