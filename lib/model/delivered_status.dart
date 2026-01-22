class DeliveredStatus {
  final String? lastDeliveredMessageId;
  final String? lastReadMessageId;

  const DeliveredStatus({
    this.lastDeliveredMessageId,
    this.lastReadMessageId,
  });

  factory DeliveredStatus.fromJson(Map<String, dynamic> json) {
    return DeliveredStatus(
      lastDeliveredMessageId: json['last_delivered_message_id'] as String?,
      lastReadMessageId: json['last_read_message_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'last_delivered_message_id': lastDeliveredMessageId,
      'last_read_message_id': lastReadMessageId,
    };
  }

  DeliveredStatus copyWith({
    String? lastDeliveredMessageId,
    String? lastReadMessageId,
  }) {
    return DeliveredStatus(
      lastDeliveredMessageId:
          lastDeliveredMessageId ?? this.lastDeliveredMessageId,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
    );
  }
}
