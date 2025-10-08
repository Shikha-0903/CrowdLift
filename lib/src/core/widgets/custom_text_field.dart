import 'package:flutter/material.dart';

class ReusableTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool isPassword;
  final IconData? prefixIcon; // Made optional
  final bool readOnly;

  const ReusableTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon, // Now optional
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isPassword = false,
    this.readOnly = false,
  });

  @override
  ReusableTextFieldState createState() => ReusableTextFieldState();
}

class ReusableTextFieldState extends State<ReusableTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: widget.readOnly,
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword ? _obscureText : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintStyle: const TextStyle(color: Color(0xFF6750a4)),
        labelText: widget.hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: Color(0xFFA998F7))
            : null, // Show only if prefixIcon is provided
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Color(0xFFA998F7),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
      validator: widget.validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your ${widget.hintText}';
            }

            return null;
          },
    );
  }
}
