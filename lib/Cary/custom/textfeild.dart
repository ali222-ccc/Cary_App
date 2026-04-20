import 'package:flutter/material.dart';

class CustomTextForm extends StatefulWidget { // حولناه لـ StatefulWidget عشان نتحكم في رؤية الباسورد
  final String hinttext;
  final TextEditingController mycontroller;
  final String? Function(String?)? validator;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType; // إضافة نوع الكيبورد

  const CustomTextForm({
    super.key,
    required this.hinttext,
    required this.mycontroller,
    required this.validator,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text, // الافتراضي نص عادي
  });

  @override
  State<CustomTextForm> createState() => _CustomTextFormState();
}

class _CustomTextFormState extends State<CustomTextForm> {
  late bool _obscureText; // متغير للتحكم في إخفاء النص

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword; // يبدأ مخفي لو هو حقل باسورد
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF2D7DFF);

    return TextFormField(
      validator: widget.validator,
      controller: widget.mycontroller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: accentColor, // لون المؤشر
      decoration: InputDecoration(
        hintText: widget.hinttext,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        filled: true,
        fillColor: const Color(0xFF1A1F30),
        
        prefixIcon: Icon(widget.prefixIcon, color: Colors.white24, size: 22),
        
        // زر العين يظهر فقط لو كان الحقل باسورد
        suffixIcon: widget.isPassword 
          ? IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white24,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            )
          : null,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white10, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        // تنسيق رسالة الخطأ نفسها
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }
}