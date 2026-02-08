class QuotaModel {
  final int usedQuota;
  final List<BroadcastHistory> broadcasts;
  QuotaModel({required this.usedQuota, required this.broadcasts});
  Map<String, dynamic> toJson() {
    return {
      "usedQuota": usedQuota,
      "broacast_history": broadcasts.map((b) => b.toJson()).toList(),
    };
  }
}

class BroadcastHistory {
  final String broadcastId;
  final int messageCount;
  BroadcastHistory({required this.broadcastId, required this.messageCount});

  Map<String, dynamic> toJson() {
    return {"broadcastId": broadcastId, "message_count": messageCount};
  }
}
