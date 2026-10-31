class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime sentAt;

  ChatMessageModel({required this.text, required this.isUser, DateTime? sentAt})
      : sentAt = sentAt ?? DateTime.now();
}
