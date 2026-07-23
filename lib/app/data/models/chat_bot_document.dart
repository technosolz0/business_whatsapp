class ChatBotDocument {
  final String id;
  final String fileName;
  final String fileMimeType;
  final String? description;
  final String dateUploaded;

  ChatBotDocument({
    required this.id,
    required this.fileName,
    required this.fileMimeType,
    this.description,
    required this.dateUploaded,
  });

  factory ChatBotDocument.fromJson(Map<String, dynamic> json) {
    return ChatBotDocument(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? '',
      fileMimeType: json['fileMimeType'] ?? '',
      description: json['description'],
      dateUploaded: json['dateUploaded'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileMimeType': fileMimeType,
      'description': description,
      'dateUploaded': dateUploaded,
    };
  }
}
