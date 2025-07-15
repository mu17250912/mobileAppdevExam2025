import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AiAssistantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Enhanced AI Response with Business Intelligence
  Future<String> getIntelligentResponse(String userInput, String language) async {
    final input = userInput.toLowerCase();
    
    // Get business data for context-aware responses
    final businessData = await _getBusinessContext();
    
    // Stock management queries
    if (input.contains('stock') || input.contains('inventory')) {
      return _getStockAdvice(businessData, language);
    }
    
    // Sales and revenue queries
    if (input.contains('sales') || input.contains('revenue') || input.contains('profit')) {
      return _getSalesAdvice(businessData, language);
    }
    
    // Cost optimization queries
    if (input.contains('cost') || input.contains('save') || input.contains('minimize') || input.contains('optimize')) {
      return _getCostOptimizationAdvice(businessData, language);
    }
    
    // Customer management queries
    if (input.contains('customer') || input.contains('client')) {
      return _getCustomerAdvice(businessData, language);
    }
    
    // General business advice
    if (input.contains('advice') || input.contains('help') || input.contains('suggestion')) {
      return _getGeneralBusinessAdvice(businessData, language);
    }
    
    // Greeting responses
    if (input.contains('hello') || input.contains('hi') || input.contains('bonjour')) {
      return _getGreetingResponse(businessData, language);
    }
    
    // Default response
    return _getDefaultResponse(language);
  }

  // Get business context for intelligent responses
  Future<Map<String, dynamic>> _getBusinessContext() async {
    if (currentUserId == null) return {};

    try {
      // Get recent sales
      final salesQuery = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sales')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final sales = salesQuery.docs.map((doc) => doc.data()).toList();

      // Get products
      final productsQuery = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('products')
          .get();

      final products = productsQuery.docs.map((doc) => doc.data()).toList();

      // Get customers
      final customersQuery = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('customers')
          .get();

      final customers = customersQuery.docs.map((doc) => doc.data()).toList();

      // Calculate metrics
      final totalSales = sales.fold<double>(0, (sum, sale) => sum + (sale['totalAmount'] ?? 0));
      final lowStockProducts = products.where((p) => (p['stock'] ?? 0) <= (p['minStock'] ?? 10)).toList();
      final topProducts = _getTopProducts(sales);

      return {
        'totalSales': totalSales,
        'recentSales': sales.length,
        'totalProducts': products.length,
        'lowStockProducts': lowStockProducts,
        'topProducts': topProducts,
        'totalCustomers': customers.length,
        'averageTransactionValue': sales.isNotEmpty ? totalSales / sales.length : 0,
      };
    } catch (e) {
      return {};
    }
  }

  List<Map<String, dynamic>> _getTopProducts(List<Map<String, dynamic>> sales) {
    final productSales = <String, int>{};
    for (final sale in sales) {
      final productName = sale['productName'] ?? 'Unknown';
      productSales[productName] = (productSales[productName] ?? 0) + ((sale['quantity'] ?? 0) as int);
    }
    
    return productSales.entries
        .map((e) => {'name': e.key, 'quantity': e.value})
        .toList()
      ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
  }

  String _getStockAdvice(Map<String, dynamic> businessData, String language) {
    final lowStockProducts = businessData['lowStockProducts'] as List? ?? [];
    final totalProducts = businessData['totalProducts'] ?? 0;
    
    if (language == 'fr') {
      if (lowStockProducts.isNotEmpty) {
        final productNames = lowStockProducts.map((p) => p['name']).join(', ');
        return '⚠️ Alerte Stock Faible: ${lowStockProducts.length} produit(s) ont un stock faible.\n\nProduits concernés: $productNames\n\nRecommandations:\n• Réapprovisionnez ces produits rapidement\n• Analysez les tendances de vente\n• Considérez augmenter le stock minimum\n• Surveillez les produits populaires';
      } else {
        return '✅ Votre inventaire est bien géré! Aucun produit en stock faible.\n\nConseils pour maintenir:\n• Vérifiez régulièrement les niveaux de stock\n• Analysez les tendances de vente\n• Ajustez les seuils de stock minimum\n• Planifiez les réapprovisionnements';
      }
    } else {
      if (lowStockProducts.isNotEmpty) {
        final productNames = lowStockProducts.map((p) => p['name']).join(', ');
        return '⚠️ Low Stock Alert: ${lowStockProducts.length} product(s) have low stock.\n\nAffected products: $productNames\n\nRecommendations:\n• Restock these products quickly\n• Analyze sales trends\n• Consider increasing minimum stock\n• Monitor popular products';
      } else {
        return '✅ Your inventory is well managed! No products with low stock.\n\nTips to maintain:\n• Regularly check stock levels\n• Analyze sales trends\n• Adjust minimum stock thresholds\n• Plan restocking schedules';
      }
    }
  }

  String _getSalesAdvice(Map<String, dynamic> businessData, String language) {
    final totalSales = businessData['totalSales'] ?? 0;
    final recentSales = businessData['recentSales'] ?? 0;
    final averageTransaction = businessData['averageTransactionValue'] ?? 0;
    final topProducts = businessData['topProducts'] as List? ?? [];

    if (language == 'fr') {
      String response = '📊 Analyse des Ventes:\n\n';
      response += '• Ventes totales: ${NumberFormat('#,##0').format(totalSales)} RWF\n';
      response += '• Transactions récentes: $recentSales\n';
      response += '• Valeur moyenne par transaction: ${NumberFormat('#,##0').format(averageTransaction)} RWF\n\n';

      if (topProducts.isNotEmpty) {
        response += '🏆 Produits les plus vendus:\n';
        for (int i = 0; i < topProducts.take(3).length; i++) {
          final product = topProducts[i];
          response += '${i + 1}. ${product['name']} - ${product['quantity']} unités\n';
        }
        response += '\nStratégies d\'amélioration:\n• Promouvoir les produits populaires\n• Créer des offres groupées\n• Améliorer l\'expérience client\n• Analyser les tendances saisonnières';
      }

      return response;
    } else {
      String response = '📊 Sales Analysis:\n\n';
      response += '• Total sales: ${NumberFormat('#,##0').format(totalSales)} RWF\n';
      response += '• Recent transactions: $recentSales\n';
      response += '• Average transaction value: ${NumberFormat('#,##0').format(averageTransaction)} RWF\n\n';

      if (topProducts.isNotEmpty) {
        response += '🏆 Top selling products:\n';
        for (int i = 0; i < topProducts.take(3).length; i++) {
          final product = topProducts[i];
          response += '${i + 1}. ${product['name']} - ${product['quantity']} units\n';
        }
        response += '\nImprovement strategies:\n• Promote popular products\n• Create bundle offers\n• Enhance customer experience\n• Analyze seasonal trends';
      }

      return response;
    }
  }

  String _getCostOptimizationAdvice(Map<String, dynamic> businessData, String language) {
    final averageTransaction = businessData['averageTransactionValue'] ?? 0;
    final totalProducts = businessData['totalProducts'] ?? 0;
    final lowStockProducts = businessData['lowStockProducts'] as List? ?? [];

    if (language == 'fr') {
      String response = '💰 Stratégies de Minimisation des Coûts:\n\n';

      // Inventory optimization
      if (lowStockProducts.isNotEmpty) {
        response += '📦 Optimisation des stocks:\n';
        response += '• Réduisez les pertes en gérant mieux l\'inventaire\n';
        response += '• Évitez les ruptures de stock coûteuses\n';
        response += '• Analysez les tendances pour optimiser les commandes\n\n';
      }

      // Transaction value optimization
      if (averageTransaction < 5000) {
        response += '💡 Amélioration de la valeur transactionnelle:\n';
        response += '• Créez des offres groupées\n';
        response += '• Proposez des services premium\n';
        response += '• Encouragez les achats multiples\n\n';
      }

      response += '🎯 Recommandations générales:\n';
      response += '• Négociez de meilleurs prix avec les fournisseurs\n';
      response += '• Optimisez les processus de vente\n';
      response += '• Utilisez les données pour prendre des décisions éclairées\n';
      response += '• Considérez les paiements numériques pour réduire les coûts de gestion';

      return response;
    } else {
      String response = '💰 Cost Minimization Strategies:\n\n';

      // Inventory optimization
      if (lowStockProducts.isNotEmpty) {
        response += '📦 Inventory optimization:\n';
        response += '• Reduce losses by better inventory management\n';
        response += '• Avoid costly stockouts\n';
        response += '• Analyze trends to optimize orders\n\n';
      }

      // Transaction value optimization
      if (averageTransaction < 5000) {
        response += '💡 Transaction value improvement:\n';
        response += '• Create bundle offers\n';
        response += '• Offer premium services\n';
        response += '• Encourage multiple purchases\n\n';
      }

      response += '🎯 General recommendations:\n';
      response += '• Negotiate better prices with suppliers\n';
      response += '• Optimize sales processes\n';
      response += '• Use data for informed decisions\n';
      response += '• Consider digital payments to reduce handling costs';

      return response;
    }
  }

  String _getCustomerAdvice(Map<String, dynamic> businessData, String language) {
    final totalCustomers = businessData['totalCustomers'] ?? 0;
    final averageTransaction = businessData['averageTransactionValue'] ?? 0;

    if (language == 'fr') {
      return '👥 Gestion des Clients:\n\n'
          '• Nombre total de clients: $totalCustomers\n'
          '• Valeur moyenne par client: ${NumberFormat('#,##0').format(averageTransaction)} RWF\n\n'
          'Stratégies d\'amélioration:\n'
          '• Créez un programme de fidélité\n'
          '• Collectez les commentaires clients\n'
          '• Personnalisez les offres\n'
          '• Améliorez le service client\n'
          '• Analysez les préférences clients';
    } else {
      return '👥 Customer Management:\n\n'
          '• Total customers: $totalCustomers\n'
          '• Average customer value: ${NumberFormat('#,##0').format(averageTransaction)} RWF\n\n'
          'Improvement strategies:\n'
          '• Create a loyalty program\n'
          '• Collect customer feedback\n'
          '• Personalize offers\n'
          '• Enhance customer service\n'
          '• Analyze customer preferences';
    }
  }

  String _getGeneralBusinessAdvice(Map<String, dynamic> businessData, String language) {
    if (language == 'fr') {
      return '💼 Conseils Généraux d\'Entreprise:\n\n'
          '📈 Croissance:\n'
          '• Analysez régulièrement vos données\n'
          '• Identifiez les tendances saisonnières\n'
          '• Diversifiez votre offre de produits\n'
          '• Investissez dans le marketing\n\n'
          '⚡ Efficacité:\n'
          '• Automatisez les processus répétitifs\n'
          '• Utilisez la technologie pour la gestion\n'
          '• Formez votre équipe régulièrement\n'
          '• Optimisez vos opérations quotidiennes\n\n'
          '🎯 Stratégie:\n'
          '• Définissez des objectifs clairs\n'
          '• Mesurez vos performances\n'
          '• Adaptez-vous aux changements du marché\n'
          '• Maintenez une relation client solide';
    } else {
      return '💼 General Business Advice:\n\n'
          '📈 Growth:\n'
          '• Regularly analyze your data\n'
          '• Identify seasonal trends\n'
          '• Diversify your product offering\n'
          '• Invest in marketing\n\n'
          '⚡ Efficiency:\n'
          '• Automate repetitive processes\n'
          '• Use technology for management\n'
          '• Train your team regularly\n'
          '• Optimize daily operations\n\n'
          '🎯 Strategy:\n'
          '• Set clear objectives\n'
          '• Measure your performance\n'
          '• Adapt to market changes\n'
          '• Maintain strong customer relationships';
    }
  }

  String _getGreetingResponse(Map<String, dynamic> businessData, String language) {
    final totalSales = businessData['totalSales'] ?? 0;
    final recentSales = businessData['recentSales'] ?? 0;

    if (language == 'fr') {
      return '👋 Bonjour! Je suis votre assistant IA pour la gestion d\'entreprise.\n\n'
          '📊 Aperçu rapide:\n'
          '• Ventes totales: ${NumberFormat('#,##0').format(totalSales)} RWF\n'
          '• Transactions récentes: $recentSales\n\n'
          'Comment puis-je vous aider aujourd\'hui?\n'
          '• Analyse des ventes\n'
          '• Optimisation des coûts\n'
          '• Gestion des stocks\n'
          '• Conseils d\'entreprise';
    } else {
      return '👋 Hello! I\'m your AI assistant for business management.\n\n'
          '📊 Quick overview:\n'
          '• Total sales: ${NumberFormat('#,##0').format(totalSales)} RWF\n'
          '• Recent transactions: $recentSales\n\n'
          'How can I help you today?\n'
          '• Sales analysis\n'
          '• Cost optimization\n'
          '• Inventory management\n'
          '• Business advice';
    }
  }

  String _getDefaultResponse(String language) {
    if (language == 'fr') {
      return '🤖 Je suis votre assistant IA pour la gestion d\'entreprise.\n\n'
          'Posez-moi des questions sur:\n'
          '• L\'analyse de vos ventes\n'
          '• L\'optimisation des coûts\n'
          '• La gestion des stocks\n'
          '• Les stratégies d\'entreprise\n'
          '• Les recommandations personnalisées';
    } else {
      return '🤖 I\'m your AI assistant for business management.\n\n'
          'Ask me about:\n'
          '• Sales analysis\n'
          '• Cost optimization\n'
          '• Inventory management\n'
          '• Business strategies\n'
          '• Personalized recommendations';
    }
  }

  // Generate detailed minimization strategy report
  Future<Map<String, dynamic>> generateDetailedMinimizationStrategy() async {
    final businessData = await _getBusinessContext();
    
    final strategies = <String, Map<String, dynamic>>{};
    
    // Inventory optimization
    final lowStockProducts = businessData['lowStockProducts'] as List? ?? [];
    if (lowStockProducts.isNotEmpty) {
      strategies['inventory'] = {
        'priority': 'high',
        'category': 'inventory',
        'title': 'Stock Optimization',
        'description': 'Optimize inventory management to reduce costs and prevent stockouts',
        'actions': [
          'Implement just-in-time inventory system',
          'Set up automated reorder points',
          'Analyze demand patterns',
          'Negotiate better supplier terms',
        ],
        'potentialSavings': '15-25% reduction in inventory costs',
        'implementationTime': '2-4 weeks',
      };
    }

    // Transaction value optimization
    final averageTransaction = businessData['averageTransactionValue'] ?? 0;
    if (averageTransaction < 5000) {
      strategies['transaction'] = {
        'priority': 'medium',
        'category': 'sales',
        'title': 'Transaction Value Optimization',
        'description': 'Increase average transaction value through bundling and upselling',
        'actions': [
          'Create product bundles',
          'Implement cross-selling strategies',
          'Offer premium services',
          'Develop loyalty programs',
        ],
        'potentialSavings': '20-30% increase in revenue',
        'implementationTime': '1-2 weeks',
      };
    }

    // Process optimization
    strategies['process'] = {
      'priority': 'medium',
      'category': 'operations',
      'title': 'Process Optimization',
      'description': 'Streamline business processes to reduce operational costs',
      'actions': [
        'Automate repetitive tasks',
        'Implement digital payment systems',
        'Optimize staff scheduling',
        'Reduce paper-based processes',
      ],
      'potentialSavings': '10-20% reduction in operational costs',
      'implementationTime': '3-6 weeks',
    };

    // Customer retention
    strategies['retention'] = {
      'priority': 'low',
      'category': 'marketing',
      'title': 'Customer Retention Strategy',
      'description': 'Focus on retaining existing customers to reduce acquisition costs',
      'actions': [
        'Implement customer feedback system',
        'Create personalized offers',
        'Develop customer loyalty program',
        'Improve customer service',
      ],
      'potentialSavings': '5-15% increase in customer lifetime value',
      'implementationTime': '4-8 weeks',
    };

    return {
      'strategies': strategies,
      'businessData': businessData,
      'summary': {
        'totalPotentialSavings': '30-50% cost reduction',
        'implementationTimeframe': '2-8 weeks',
        'priorityOrder': ['inventory', 'transaction', 'process', 'retention'],
      },
    };
  }
} 