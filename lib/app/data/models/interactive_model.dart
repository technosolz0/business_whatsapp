class InteractiveModel {
  final String type;
  final List<InteractiveButton> buttons;

  const InteractiveModel({required this.type, required this.buttons});

  factory InteractiveModel.fromJson(Map<String, dynamic> json) {
    return InteractiveModel(
      type: json['type'] as String,
      buttons: (json['buttons'] as List<dynamic>)
          .map((e) => InteractiveButton.fromJson(e))
          .toList(),
    );
  }
}

class InteractiveButton {
  final String type;
  final String text;

  final String? url;
  final String? phoneNumber;
  final List<String>? example;

  InteractiveButton({
    required this.type,
    required this.text,
    this.url,
    this.phoneNumber,
    this.example,
  });

  factory InteractiveButton.fromJson(Map<String, dynamic> json) {
    return InteractiveButton(
      type: json['type'] ?? "",
      text: json['text'] ?? "",
      url: json['url'],
      phoneNumber: json['phone_number'],
      example: (json['example'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    // SPECIAL HANDLING — COPY_CODE must output only example
    if (type == "COPY_CODE") {
      return {"type": type, "text": text, "example": example ?? []};
    }

    // OTHER BUTTONS
    return {
      "type": type,
      "text": text,
      if (url != null) "url": url,
      if (phoneNumber != null) "phone_number": phoneNumber,
      if (example != null) "example": example,
    };
  }
}

extension InteractiveButtonCopy on InteractiveButton {
  InteractiveButton copyWith({
    String? type,
    String? text,
    String? url,
    String? phoneNumber,
    List<String>? example,
  }) {
    final newType = type ?? this.type;

    return InteractiveButton(
      type: newType,
      text: text ?? this.text,

      // ❌ COPY_CODE must never store URL
      url: newType == "COPY_CODE" ? null : (url ?? this.url),

      phoneNumber: (phoneNumber ?? this.phoneNumber),

      // COPY_CODE stores ONLY example
      example: example ?? this.example,
    );
  }
}
