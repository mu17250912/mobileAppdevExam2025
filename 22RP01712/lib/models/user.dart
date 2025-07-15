import 'dart:typed_data';
import 'dart:convert';

class Experience {
  final String? documentName; // file name
  final String? documentPath; // file path (mobile/desktop)
  final Uint8List? documentBytes; // file bytes (web)
  final String description;

  Experience({this.documentName, this.documentPath, this.documentBytes, required this.description});

  Map<String, dynamic> toMap() => {
    'documentName': documentName,
    'documentPath': documentPath,
    'documentBytes': documentBytes != null ? base64Encode(documentBytes!) : null,
    'description': description,
  };

  factory Experience.fromMap(Map<String, dynamic> map) => Experience(
    documentName: map['documentName'],
    documentPath: map['documentPath'],
    documentBytes: map['documentBytes'] != null ? base64Decode(map['documentBytes']) : null,
    description: map['description'],
  );
}

class UserDocument {
  final String name;
  final String type; // e.g., 'cv', 'certificate', 'other'
  final String url; // download/view URL

  UserDocument({required this.name, required this.type, required this.url});

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'url': url,
  };

  factory UserDocument.fromMap(Map<String, dynamic> map) => UserDocument(
    name: map['name'],
    type: map['type'],
    url: map['url'],
  );
}

class AppUser {
  final String id;
  final String idNumber;
  final String fullName;
  final String telephone;
  final String email;
  final String password;
  String? cvUrl;
  List<Experience> experiences;
  List<UserDocument> documents;
  List<String> degrees;
  List<String> certificates;

  AppUser({
    required this.id,
    required this.idNumber,
    required this.fullName,
    required this.telephone,
    required this.email,
    required this.password,
    this.cvUrl,
    List<Experience>? experiences,
    List<UserDocument>? documents,
    List<String>? degrees,
    List<String>? certificates,
  })  : experiences = experiences ?? [],
        documents = documents ?? [],
        degrees = degrees ?? [],
        certificates = certificates ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idNumber': idNumber,
      'fullName': fullName,
      'telephone': telephone,
      'email': email,
      'password': password,
      'cvUrl': cvUrl,
      'experiences': experiences.map((e) => e.toMap()).toList(),
      'documents': documents.map((d) => d.toMap()).toList(),
      'degrees': degrees,
      'certificates': certificates,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      idNumber: map['idNumber'],
      fullName: map['fullName'],
      telephone: map['telephone'],
      email: map['email'],
      password: map['password'],
      cvUrl: map['cvUrl'],
      experiences: (map['experiences'] as List<dynamic>?)
              ?.map((e) => Experience.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      documents: (map['documents'] as List<dynamic>?)?.map((d) => UserDocument.fromMap(Map<String, dynamic>.from(d))).toList() ?? [],
      degrees: List<String>.from(map['degrees'] ?? []),
      certificates: List<String>.from(map['certificates'] ?? []),
    );
  }
} 