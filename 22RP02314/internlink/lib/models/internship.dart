class Internship {
  final String id;
  final String companyId;
  final String companyName;
  final String title;
  final String description;
  final String requirements;
  final String location;
  final String duration;
  final String stipend;
  final String type; // full-time, part-time, remote
  final List<String> skills;
  final DateTime deadline;
  final DateTime postedDate;
  final String status; // open, closed, draft
  final int maxApplications;
  final int currentApplications;

  Internship({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.title,
    required this.description,
    required this.requirements,
    required this.location,
    required this.duration,
    required this.stipend,
    required this.type,
    required this.skills,
    required this.deadline,
    required this.postedDate,
    required this.status,
    required this.maxApplications,
    required this.currentApplications,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'title': title,
      'description': description,
      'requirements': requirements,
      'location': location,
      'duration': duration,
      'stipend': stipend,
      'type': type,
      'skills': skills,
      'deadline': deadline.toIso8601String(),
      'postedDate': postedDate.toIso8601String(),
      'status': status,
      'maxApplications': maxApplications,
      'currentApplications': currentApplications,
    };
  }

  factory Internship.fromMap(Map<String, dynamic> map) {
    return Internship(
      id: map['id'],
      companyId: map['companyId'],
      companyName: map['companyName'],
      title: map['title'],
      description: map['description'],
      requirements: map['requirements'],
      location: map['location'],
      duration: map['duration'],
      stipend: map['stipend'],
      type: map['type'],
      skills: List<String>.from(map['skills']),
      deadline: DateTime.parse(map['deadline']),
      postedDate: DateTime.parse(map['postedDate']),
      status: map['status'],
      maxApplications: map['maxApplications'],
      currentApplications: map['currentApplications'],
    );
  }
} 