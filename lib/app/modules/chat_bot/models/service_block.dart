import 'package:flutter/material.dart';

class ServiceBlock {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController descController;

  ServiceBlock({String name = '', String price = '', String desc = ''})
      : nameController = TextEditingController(text: name),
        priceController = TextEditingController(text: price),
        descController = TextEditingController(text: desc);

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descController.dispose();
  }

  Map<String, String> toMap() {
    return {
      'name': nameController.text.trim(),
      'price': priceController.text.trim(),
      'description': descController.text.trim(),
    };
  }
}
