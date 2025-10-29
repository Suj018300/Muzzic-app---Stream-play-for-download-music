import 'package:flutter/material.dart';

class CustomeField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final bool isObscureText;
  final bool readOnly;
  final VoidCallback? onTap;
  final dynamic initialValue;

  const CustomeField({
    super.key,
    required this.hintText,
    required this.controller,
    this.isObscureText = false,
    this.readOnly = false,
    this.onTap,
    this.initialValue
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onTap: onTap,
      readOnly: readOnly,
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