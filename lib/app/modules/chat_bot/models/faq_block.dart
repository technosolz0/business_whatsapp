import 'package:flutter/material.dart';

class FAQBlock {
  final TextEditingController questionController;
  final TextEditingController answerController;

  FAQBlock({String question = '', String answer = ''})
      : questionController = TextEditingController(text: question),
        answerController = TextEditingController(text: answer);

  void dispose() {
    questionController.dispose();
    answerController.dispose();
  }

  Map<String, String> toMap() {
    return {
      'question': questionController.text.trim(),
      'answer': answerController.text.trim(),
    };
  }
}
