import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/skill_model.dart';
import '../models/notification_model.dart';
import '../models/session_model.dart';

class AppService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Skills Service Methods
  static Future<List<Skill>> getUserSkills(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('skills')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Skill.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting user skills: $e');
      return [];
    }
  }

  static Future<List<Skill>> getSkillsByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection('skills')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) => Skill.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting skills by category: $e');
      return [];
    }
  }

  static Future<List<Skill>> searchSkills(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('skills')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final allSkills =
          querySnapshot.docs.map((doc) => Skill.fromFirestore(doc)).toList();
      return allSkills.where((skill) => skill.matchesSearch(query)).toList();
    } catch (e) {
      print('Error searching skills: $e');
      return [];
    }
  }

  static Future<bool> addSkill(Skill skill, {String type = 'offer'}) async {
    try {
      await _firestore.collection('skills').add({
        'userId': skill.userId, // Changed from 'ownerId' to 'userId'
        'name': skill.name, // Changed from 'skillName' to 'name'
        'type': type, // 'offer' or 'want'
        'description': skill.description,
        'category': skill.category,
        'difficulty': skill.difficulty,
        'tags': skill.tags,
        'createdAt': Timestamp.fromDate(skill.createdAt),
        'updatedAt': Timestamp.fromDate(skill.updatedAt),
        'isActive': skill.isActive,
        'hourlyRate': skill.hourlyRate,
        'languages': skill.languages,
        'location': skill.location,
        'availability': skill.availability,
        'userName': skill.userName,
        'userPhotoUrl': skill.userPhotoUrl,
        'rating': skill.rating,
        'totalSessions': skill.totalSessions,
        'prerequisites': skill.prerequisites,
        'metadata': skill.metadata,
      });
      return true;
    } catch (e) {
      print('Error adding skill: $e');
      return false;
    }
  }

  static Future<bool> updateSkill(Skill skill) async {
    try {
      await _firestore
          .collection('skills')
          .doc(skill.id)
          .update(skill.copyWith(updatedAt: DateTime.now()).toFirestore());
      return true;
    } catch (e) {
      print('Error updating skill: $e');
      return false;
    }
  }

  static Future<bool> deleteSkill(String skillId) async {
    try {
      await _firestore.collection('skills').doc(skillId).delete();
      return true;
    } catch (e) {
      print('Error deleting skill: $e');
      return false;
    }
  }

  static Future<SkillStats> getSkillStats(String userId) async {
    try {
      final skills = await getUserSkills(userId);
      final categoryDistribution = <String, int>{};

      for (final skill in skills) {
        categoryDistribution[skill.category] =
            (categoryDistribution[skill.category] ?? 0) + 1;
      }

      final totalSessions =
          skills.fold(0, (sum, skill) => sum + skill.totalSessions);
      final totalRating = skills.fold(0, (sum, skill) => sum + skill.rating);
      final averageRating =
          totalSessions > 0 ? totalRating / totalSessions : 0.0;

      return SkillStats(
        totalSkills: skills.length,
        activeSkills: skills.where((s) => s.isActive).length,
        completedSessions: totalSessions,
        averageRating: averageRating,
        categoryDistribution: categoryDistribution,
      );
    } catch (e) {
      print('Error getting skill stats: $e');
      return SkillStats.empty();
    }
  }

  // Notifications Service Methods
  static Future<List<NotificationModel>> getUserNotifications(String userId,
      {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  static Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  static Future<int> getUnreadMessageCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  static Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  static Future<bool> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  static Future<bool> sendNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .add(notification.toFirestore());
      return true;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  static Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  static Future<bool> createSkillRequestNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String skillName,
    String? senderPhotoUrl,
  }) async {
    try {
      final notification = NotificationTemplates.skillRequest(
        id: '', // Will be set by Firestore
        userId: recipientId,
        senderId: senderId,
        senderName: senderName,
        skillName: skillName,
        senderPhotoUrl: senderPhotoUrl,
      );

      await sendNotification(notification);
      return true;
    } catch (e) {
      print('Error creating skill request notification: $e');
      return false;
    }
  }

  static Future<bool> respondToSessionRequest({
    required String sessionId,
    required String responderId,
    required bool accepted,
    String? message,
  }) async {
    try {
      final sessionDoc =
          await _firestore.collection('sessions').doc(sessionId).get();
      if (!sessionDoc.exists) return false;

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final requesterId = sessionData['requesterId'] as String?;

      if (requesterId == null) return false;

      // Update session status
      await _firestore.collection('sessions').doc(sessionId).update({
        'status': accepted ? 'confirmed' : 'cancelled',
        'responderId': responderId,
        'responseMessage': message,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Send notification to requester
      final responderDoc =
          await _firestore.collection('users').doc(responderId).get();
      final responderData = responderDoc.data() as Map<String, dynamic>?;
      final responderName = responderData?['fullName'] ?? 'User';

      await _firestore.collection('notifications').add({
        'userId': requesterId,
        'title': accepted ? 'Session Accepted' : 'Session Declined',
        'message': accepted
            ? '$responderName accepted your session request'
            : '$responderName declined your session request',
        'type': 'session_response',
        'senderId': responderId,
        'senderName': responderName,
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'data': {
          'sessionId': sessionId,
          'accepted': accepted,
          'message': message,
        },
      });

      return true;
    } catch (e) {
      print('Error responding to session request: $e');
      return false;
    }
  }

  // Sessions Service Methods
  static Future<List<SessionModel>> getUserSessions(String userId,
      {SessionStatus? status}) async {
    try {
      Query query = _firestore
          .collection('sessions')
          .where('participants', arrayContains: userId)
          .orderBy('scheduledAt', descending: true);

      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user sessions: $e');
      return [];
    }
  }

  static Future<List<SessionModel>> getHostedSessions(String userId,
      {SessionStatus? status}) async {
    try {
      Query query = _firestore
          .collection('sessions')
          .where('participants', arrayContains: userId)
          .orderBy('scheduledAt', descending: true);

      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting hosted sessions: $e');
      return [];
    }
  }

  static Future<List<SessionModel>> getPendingSessionRequests(
      String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('participants', arrayContains: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting pending session requests: $e');
      return [];
    }
  }

  static Future<String?> createSession(SessionModel session) async {
    try {
      final docRef =
          await _firestore.collection('sessions').add(session.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating session: $e');
      return null;
    }
  }

  static Future<bool> updateSession(SessionModel session) async {
    try {
      await _firestore
          .collection('sessions')
          .doc(session.id)
          .update(session.copyWith(updatedAt: DateTime.now()).toFirestore());
      return true;
    } catch (e) {
      print('Error updating session: $e');
      return false;
    }
  }

  static Future<bool> deleteSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).delete();
      return true;
    } catch (e) {
      print('Error deleting session: $e');
      return false;
    }
  }

  static Future<bool> joinSession(
      String sessionId, String userId, Map<String, dynamic> userDetails) async {
    try {
      final sessionDoc =
          await _firestore.collection('sessions').doc(sessionId).get();
      if (!sessionDoc.exists) return false;

      final session = SessionModel.fromFirestore(sessionDoc);
      if (session.participants.contains(userId)) return true; // Already joined

      final updatedSession = session.addParticipant(userId, userDetails);
      await updateSession(updatedSession);
      return true;
    } catch (e) {
      print('Error joining session: $e');
      return false;
    }
  }

  static Future<bool> leaveSession(String sessionId, String userId) async {
    try {
      final sessionDoc =
          await _firestore.collection('sessions').doc(sessionId).get();
      if (!sessionDoc.exists) return false;

      final session = SessionModel.fromFirestore(sessionDoc);
      if (!session.participants.contains(userId)) return true; // Not in session

      final updatedSession = session.removeParticipant(userId);
      await updateSession(updatedSession);
      return true;
    } catch (e) {
      print('Error leaving session: $e');
      return false;
    }
  }

  static Future<List<SessionModel>> getUpcomingSessions(String userId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('participants', arrayContains: userId)
          .where('scheduledAt', isGreaterThan: Timestamp.fromDate(now))
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('scheduledAt')
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting upcoming sessions: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSessionStats(String userId) async {
    try {
      final allSessions = await getUserSessions(userId);

      final totalSessions = allSessions.length;
      final completedSessions =
          allSessions.where((s) => s.status == SessionStatus.completed).length;
      final cancelledSessions =
          allSessions.where((s) => s.status == SessionStatus.cancelled).length;
      final upcomingSessions = allSessions.where((s) => s.isUpcoming).length;

      final totalDuration = allSessions
          .where((s) => s.status == SessionStatus.completed)
          .fold(0, (sum, session) => sum + session.duration);

      return {
        'totalSessions': totalSessions,
        'completedSessions': completedSessions,
        'cancelledSessions': cancelledSessions,
        'upcomingSessions': upcomingSessions,
        'totalDuration': totalDuration,
        'completionRate':
            totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 0.0,
      };
    } catch (e) {
      print('Error getting session stats: $e');
      return {};
    }
  }

  // Real-time listeners
  static Stream<List<NotificationModel>> listenToNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  static Stream<List<SessionModel>> listenToUserSessions(String userId) {
    return _firestore
        .collection('sessions')
        .where('participants', arrayContains: userId)
        .orderBy('scheduledAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SessionModel.fromFirestore(doc))
            .toList());
  }

  static Stream<List<Skill>> listenToSkillRequests(String userId) {
    return _firestore
        .collection('skills')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Skill.fromFirestore(doc)).toList());
  }

  // --- QUERY HELPERS ---
  static Stream<List<Skill>> listenToSkills({String? userId, String? type}) {
    Query query = _firestore.collection('skills');
    if (userId != null)
      query = query.where('userId',
          isEqualTo: userId); // Changed from 'ownerId' to 'userId'
    if (type != null) query = query.where('type', isEqualTo: type);
    return query.snapshots().map(
        (snap) => snap.docs.map((doc) => Skill.fromFirestore(doc)).toList());
  }

  static Stream<List<SessionModel>> listenToSessions(
      {String? userId, String? status}) {
    Query query = _firestore.collection('sessions');
    if (userId != null)
      query = query.where('participants', arrayContains: userId);
    if (status != null) query = query.where('status', isEqualTo: status);
    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => SessionModel.fromFirestore(doc)).toList());
  }
}
