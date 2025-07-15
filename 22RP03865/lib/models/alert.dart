class Alert {
  String type;
  String description;
  String location;
  DateTime dateTime;
  String? photoUrl;

  Alert({
    required this.type,
    required this.description,
    required this.location,
    required this.dateTime,
    this.photoUrl,
  });
} 