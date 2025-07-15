class NotificationItem {
  final String emoji;
  final String title;
  final String message;
  final String timestamp;
  final String? animalId; // For linking to animal details
  bool unread;

  NotificationItem({
    required this.emoji,
    required this.title,
    required this.message,
    required this.timestamp,
    this.animalId,
    this.unread = true,
  });
}