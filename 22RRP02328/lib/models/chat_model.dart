class ChatModel {
  final String id;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts; // userId -> count
  final bool isGroup;
  final String? groupName;

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCounts,
    this.isGroup = false,
    this.groupName,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      participantIds: List<String>.from(json['participantIds']),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
      isGroup: json['isGroup'] ?? false,
      groupName: json['groupName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCounts': unreadCounts,
      'isGroup': isGroup,
      'groupName': groupName,
    };
  }
} 