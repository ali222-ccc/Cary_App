import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyCarPage extends StatefulWidget {
  const MyCarPage({super.key});

  @override
  State<MyCarPage> createState() => _MyCarPageState();
}

class _MyCarPageState extends State<MyCarPage> {
  final _formKey = GlobalKey<FormState>();

  // تعريف الـ Controllers
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();

  bool _isLoading = true;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  final Color bgColor = const Color(0xFF0B0E14);
  final Color cardColor = const Color(0xFF1A1F30);
  final Color accentColor = const Color(0xFF2D7DFF);

  @override
  void initState() {
    super.initState();
    _loadCarData();
  }

  // --- التعديل الجوهري اللي فكرتني بيه ---
  @override
  void dispose() {
    // تنظيف الذاكرة فور إغلاق الشاشة
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _loadCarData() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('car_info')
          .doc('details')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data()!;
        if (mounted) {
          setState(() {
            _brandController.text = data['brand'] ?? '';
            _modelController.text = data['model'] ?? '';
            _yearController.text = data['year'] ?? '';
            _colorController.text = data['color'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading car data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCarData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('car_info')
            .doc('details')
            .set({
          'brand': _brandController.text.trim(),
          'model': _modelController.text.trim(),
          'year': _yearController.text.trim(),
          'color': _colorController.text.trim(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved Successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Car Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTopIcon(),
                    const SizedBox(height: 40),
                    _buildInputLabel("Brand Name"),
                    _buildTextField(_brandController, Icons.business, "e.g. Mercedes", isEnglish: true),
                    const SizedBox(height: 20),
                    _buildInputLabel("Model"),
                    _buildTextField(_modelController, Icons.car_rental, "e.g. C200", isEnglish: true),
                    const SizedBox(height: 20),
                    _buildInputLabel("Year"),
                    _buildTextField(_yearController, Icons.event, "e.g. 2024", isNumbers: true, maxLength: 4),
                    const SizedBox(height: 20),
                    _buildInputLabel("Color"),
                    _buildTextField(_colorController, Icons.colorize, "e.g. Black", isEnglish: true),
                    const SizedBox(height: 40),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  // دالة مساعدة للأيقونة العلوية
  Widget _buildTopIcon() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: accentColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.directions_car_filled_rounded, size: 50, color: accentColor),
    );
  }

  // دالة مساعدة للـ Label
  Widget _buildInputLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 14)),
      ),
    );
  }

  // دالة بناء حقل الإدخال
  Widget _buildTextField(TextEditingController controller, IconData icon, String hint, {bool isEnglish = false, bool isNumbers = false, int? maxLength}) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumbers ? TextInputType.number : TextInputType.text,
      inputFormatters: [
        if (isEnglish) FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
        if (isNumbers) FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        filled: true,
        fillColor: cardColor,
        counterText: "",
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: accentColor)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  // دالة بناء زر الحفظ
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _saveCarData,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}