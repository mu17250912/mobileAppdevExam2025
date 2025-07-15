class Application {
  final String id;
  final String internshipId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String studentPhone;
  final String cvGoogleDocsLink;
  final String coverLetter;
  final DateTime appliedDate;
  final String status; // pending, approved, rejected, withdrawn
  final String? feedback;
  final DateTime? reviewedDate;
  final String? reviewedBy;
  final String companyId;

  Application({
    required this.id,
    required this.internshipId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.studentPhone,
    required this.cvGoogleDocsLink,
    required this.coverLetter,
    required this.appliedDate,
    required this.status,
    required this.companyId,
    this.feedback,
    this.reviewedDate,
    this.reviewedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'internshipId': internshipId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'studentPhone': studentPhone,
      'cvGoogleDocsLink': cvGoogleDocsLink,
      'coverLetter': coverLetter,
      'appliedDate': appliedDate.toIso8601String(),
      'status': status,
      'feedback': feedback,
      'reviewedDate': reviewedDate?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'companyId': companyId,
    };
  }

  factory Application.fromMap(Map<String, dynamic> map) {
    return Application(
      id: map['id'],
      internshipId: map['internshipId'],
      studentId: map['studentId'],
      studentName: map['studentName'],
      studentEmail: map['studentEmail'],
      studentPhone: map['studentPhone'],
      cvGoogleDocsLink: map['cvGoogleDocsLink'],
      coverLetter: map['coverLetter'],
      appliedDate: DateTime.parse(map['appliedDate']),
      status: map['status'],
      feedback: map['feedback'],
      reviewedDate: map['reviewedDate'] != null ? DateTime.parse(map['reviewedDate']) : null,
      reviewedBy: map['reviewedBy'],
      companyId: map['companyId'],
    );
  }
} 