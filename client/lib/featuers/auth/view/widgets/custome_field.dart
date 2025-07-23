import 'package:flutter/material.dart';

class CustomeField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool isObscureText;

  const CustomeField({
    super.key,
    required this.hintText,
    required this.controller,
    this.isObscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        // border: 
      ),
      validator: (val) {
      if(val!.trim().isEmpty) {
        return "$hintText is missing";
      }
      return null;
      },

      obscureText: isObscureText,
    );
  }
}