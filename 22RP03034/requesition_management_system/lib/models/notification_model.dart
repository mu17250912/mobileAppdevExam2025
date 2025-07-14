class NotificationModel {
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'request_rejected', 'request_forwarded', 'request_approved', 'request_rejected_by_approver', 'delivery_completed'
  final String? targetRole; // null for all roles, or specific role like 'Employee', 'Logistics', 'Approver'
  final String? targetUser; // null for all users, or specific user name
  final String? requestSubject; // to identify which request this notification is about
  bool read;

  NotificationModel({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.targetRole,
    this.targetUser,
    this.requestSubject,
    this.read = false,
  });
}

class NotificationStore {
  static final List<NotificationModel> notifications = [];

  static void add(String title, String message, {
    String type = 'general',
    String? targetRole,
    String? targetUser,
    String? requestSubject,
  }) {
    notifications.insert(0, NotificationModel(
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      targetRole: targetRole,
      targetUser: targetUser,
      requestSubject: requestSubject,
    ));
  }

  static void addRequestRejectedNotification(String requestSubject, String employeeName, String logisticsComment) {
    // Notification for employee when logistics rejects
    add(
      'Request Rejected by Logistics',
      'Your request "$requestSubject" was rejected by Logistics.\n\nReason: $logisticsComment',
      type: 'request_rejected',
      targetRole: 'Employee',
      targetUser: employeeName,
      requestSubject: requestSubject,
    );
  }

  static void addRequestForwardedNotification(String requestSubject, String employeeName) {
    // Notification for employee when request is forwarded to approver
    add(
      'Request Forwarded to Approver',
      'Your request "$requestSubject" has been forwarded to the approver for review.',
      type: 'request_forwarded',
      targetRole: 'Employee',
      targetUser: employeeName,
      requestSubject: requestSubject,
    );
    
    // Notification for logistics when request is forwarded
    add(
      'Request Forwarded to Approver',
      'Request "$requestSubject" from $employeeName has been forwarded to the approver.',
      type: 'request_forwarded',
      targetRole: 'Logistics',
      requestSubject: requestSubject,
    );
  }

  static void addRequestApprovedNotification(String requestSubject, String employeeName, String approverComment) {
    // Notification for employee when approver approves
    add(
      'Request Approved',
      'Your request "$requestSubject" has been approved by the approver.\n\nJustification: $approverComment',
      type: 'request_approved',
      targetRole: 'Employee',
      targetUser: employeeName,
      requestSubject: requestSubject,
    );
    
    // Notification for logistics when approver approves
    add(
      'Request Approved by Approver',
      'Request "$requestSubject" from $employeeName has been approved by the approver.',
      type: 'request_approved',
      targetRole: 'Logistics',
      requestSubject: requestSubject,
    );
  }

  static void addRequestRejectedByApproverNotification(String requestSubject, String employeeName, String approverComment) {
    // Notification for employee when approver rejects
    add(
      'Request Rejected by Approver',
      'Your request "$requestSubject" was rejected by the approver.\n\nReason: $approverComment',
      type: 'request_rejected_by_approver',
      targetRole: 'Employee',
      targetUser: employeeName,
      requestSubject: requestSubject,
    );
    
    // Notification for logistics when approver rejects
    add(
      'Request Rejected by Approver',
      'Request "$requestSubject" from $employeeName was rejected by the approver.',
      type: 'request_rejected_by_approver',
      targetRole: 'Logistics',
      requestSubject: requestSubject,
    );
  }

  static void markAllRead() {
    for (var n in notifications) {
      n.read = true;
    }
  }

  static int unreadCount() {
    return notifications.where((n) => !n.read).length;
  }

  static int unreadCountForUser(String? userRole, String? userName) {
    return notifications.where((n) => 
      !n.read && 
      (n.targetRole == null || n.targetRole == userRole) &&
      (n.targetUser == null || n.targetUser == userName)
    ).length;
  }

  static List<NotificationModel> getNotificationsForUser(String? userRole, String? userName) {
    return notifications.where((n) => 
      (n.targetRole == null || n.targetRole == userRole) &&
      (n.targetUser == null || n.targetUser == userName)
    ).toList();
  }

  static void clearAll() {
    notifications.clear();
  }

  static void clearForUser(String? userRole, String? userName) {
    notifications.removeWhere((n) => 
      (n.targetRole == null || n.targetRole == userRole) &&
      (n.targetUser == null || n.targetUser == userName)
    );
  }
} 