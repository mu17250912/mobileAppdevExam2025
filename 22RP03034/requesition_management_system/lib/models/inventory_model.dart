class InventoryItem {
  final String id;
  final String name;
  final String category; // 'Tool' or 'Material'
  final String description;
  int quantity;
  final String unit; // 'pcs', 'kg', 'm', etc.
  final DateTime dateAdded;
  final String addedBy;
  String? location;
  String? notes;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.dateAdded,
    required this.addedBy,
    this.location,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'dateAdded': dateAdded.toIso8601String(),
      'addedBy': addedBy,
      'location': location,
      'notes': notes,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      quantity: json['quantity'],
      unit: json['unit'],
      dateAdded: DateTime.parse(json['dateAdded']),
      addedBy: json['addedBy'],
      location: json['location'],
      notes: json['notes'],
    );
  }
}

class HandoverDocument {
  final String id;
  final String requestId;
  final String itemName;
  final String itemCategory;
  final int quantity;
  final String unit;
  final String employeeName;
  final String employeePost;
  final String logisticsName;
  final DateTime handoverDate;
  final String employeeSignature;
  final String logisticsSignature;
  final String notes;

  HandoverDocument({
    required this.id,
    required this.requestId,
    required this.itemName,
    required this.itemCategory,
    required this.quantity,
    required this.unit,
    required this.employeeName,
    required this.employeePost,
    required this.logisticsName,
    required this.handoverDate,
    required this.employeeSignature,
    required this.logisticsSignature,
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'itemName': itemName,
      'itemCategory': itemCategory,
      'quantity': quantity,
      'unit': unit,
      'employeeName': employeeName,
      'employeePost': employeePost,
      'logisticsName': logisticsName,
      'handoverDate': handoverDate.toIso8601String(),
      'employeeSignature': employeeSignature,
      'logisticsSignature': logisticsSignature,
      'notes': notes,
    };
  }

  factory HandoverDocument.fromJson(Map<String, dynamic> json) {
    return HandoverDocument(
      id: json['id'],
      requestId: json['requestId'],
      itemName: json['itemName'],
      itemCategory: json['itemCategory'],
      quantity: json['quantity'],
      unit: json['unit'],
      employeeName: json['employeeName'],
      employeePost: json['employeePost'],
      logisticsName: json['logisticsName'],
      handoverDate: DateTime.parse(json['handoverDate']),
      employeeSignature: json['employeeSignature'],
      logisticsSignature: json['logisticsSignature'],
      notes: json['notes'] ?? '',
    );
  }
}

class InventoryStore {
  static List<InventoryItem> items = [
    // Sample data
    InventoryItem(
      id: '1',
      name: 'Screwdriver Set',
      category: 'Tool',
      description: 'Complete set of screwdrivers with different sizes',
      quantity: 15,
      unit: 'pcs',
      dateAdded: DateTime.now().subtract(const Duration(days: 30)),
      addedBy: 'Logistics Manager',
      location: 'Warehouse A - Shelf 1',
    ),
    InventoryItem(
      id: '2',
      name: 'Steel Pipes',
      category: 'Material',
      description: 'Galvanized steel pipes for construction',
      quantity: 200,
      unit: 'm',
      dateAdded: DateTime.now().subtract(const Duration(days: 15)),
      addedBy: 'Logistics Manager',
      location: 'Warehouse B - Section 3',
    ),
    InventoryItem(
      id: '3',
      name: 'Safety Helmets',
      category: 'Tool',
      description: 'Hard hats for construction safety',
      quantity: 50,
      unit: 'pcs',
      dateAdded: DateTime.now().subtract(const Duration(days: 7)),
      addedBy: 'Logistics Manager',
      location: 'Warehouse A - Safety Section',
    ),
  ];

  static List<HandoverDocument> handoverDocuments = [];

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static InventoryItem? findItemByName(String name) {
    try {
      return items.firstWhere((item) => 
        item.name.toLowerCase().contains(name.toLowerCase()));
    } catch (e) {
      return null;
    }
  }

  static bool checkStockAvailability(String itemName, int requestedQuantity) {
    final item = findItemByName(itemName);
    return item != null && item.quantity >= requestedQuantity;
  }

  static void updateStock(String itemName, int quantity, bool isReduction) {
    final item = findItemByName(itemName);
    if (item != null) {
      if (isReduction) {
        item.quantity -= quantity;
        if (item.quantity < 0) item.quantity = 0;
      } else {
        item.quantity += quantity;
      }
    }
  }

  static void addItem(InventoryItem item) {
    items.add(item);
  }

  static void removeItem(String id) {
    items.removeWhere((item) => item.id == id);
  }

  static void updateItem(InventoryItem updatedItem) {
    final index = items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      items[index] = updatedItem;
    }
  }

  static void addHandoverDocument(HandoverDocument document) {
    handoverDocuments.add(document);
  }
} 