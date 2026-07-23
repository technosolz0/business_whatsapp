import 'package:flutter/material.dart';

class WhatsAppTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> children = [];
    final RegExp exp = RegExp(
      r'(\*.*?\*)|(_.*?_)|(~.*?~)|({{.*?}})|([^*_~{]+)|(.)',
      multiLine: true,
      dotAll: true,
    );

    text.splitMapJoin(
      exp,
      onMatch: (m) {
        final match = m.group(0)!;
        if (match.startsWith('*') && match.endsWith('*') && match.length > 1) {
          children.add(
            TextSpan(
              text: match,
              style: style?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF25D366),
              ),
            ),
          );
        } else if (match.startsWith('_') &&
            match.endsWith('_') &&
            match.length > 1) {
          children.add(
            TextSpan(
              text: match,
              style: style?.copyWith(
                fontStyle: FontStyle.italic,
                color: const Color(0xFF25D366),
              ),
            ),
          );
        } else if (match.startsWith('~') &&
            match.endsWith('~') &&
            match.length > 1) {
          children.add(
            TextSpan(
              text: match,
              style: style?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: const Color(0xFF25D366),
              ),
            ),
          );
        } else if (match.startsWith('{{') && match.endsWith('}}')) {
          children.add(
            TextSpan(
              text: match,
              style: style?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          );
        } else {
          children.add(TextSpan(text: match, style: style));
        }
        return '';
      },
      onNonMatch: (nm) {
        children.add(TextSpan(text: nm, style: style));
        return '';
      },
    );

    return TextSpan(style: style, children: children);
  }
}
