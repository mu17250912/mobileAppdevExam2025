// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'BizTrackr';

  @override
  String get welcomeMessage => 'Bienvenue ! Veuillez sélectionner votre langue :';

  @override
  String get english => 'Anglais';

  @override
  String get kinyarwanda => 'Kinyarwanda';

  @override
  String get aboutBizTrackr => 'À propos de BizTrackr';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String welcomeUser(Object username) {
    return 'Bienvenue, $username!';
  }

  @override
  String get salesToday => 'Ventes aujourd\'hui';

  @override
  String get lowStockItems => 'Articles en rupture';

  @override
  String get customerCredit => 'Crédit client';

  @override
  String get salesThisWeek => 'Ventes cette semaine';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get recordSale => 'Enregistrer une vente';

  @override
  String get inventory => 'Inventaire';

  @override
  String get customers => 'Clients';

  @override
  String get reports => 'Rapports & Analyses';

  @override
  String get aiChart => 'Graphique IA';

  @override
  String get aiAssistant => 'Assistant IA';

  @override
  String get close => 'Fermer';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get changeAppLanguage => 'Changer la langue de l\'application';

  @override
  String get account => 'Compte';

  @override
  String get manageAccount => 'Gérer votre compte';

  @override
  String get premium => 'Premium';

  @override
  String get active => 'Actif';

  @override
  String get goPremium => 'Passer Premium';

  @override
  String get premiumRequired => 'Premium Requis';

  @override
  String get premiumFeatureMessage => 'Cette fonctionnalité n\'est disponible que pour les utilisateurs premium. Mettez à niveau maintenant pour débloquer les analyses avancées, les insights IA et les rapports détaillés.';

  @override
  String get upgradeNow => 'Mettre à niveau maintenant';

  @override
  String get premiumFeatures => 'Fonctionnalités Premium';

  @override
  String get premiumFeaturesList => '• Analyses et graphiques avancés\n• Insights IA pour l\'entreprise\n• Rapports détaillés\n• Stockage de données illimité\n• Support prioritaire';

  @override
  String get logout => 'Déconnexion';

  @override
  String get logoutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter?';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get save => 'Enregistrer';

  @override
  String get search => 'Rechercher';

  @override
  String get noProducts => 'Aucun produit pour le moment';

  @override
  String get noCustomers => 'Aucun client pour le moment';

  @override
  String get totalProducts => 'Total des Produits';

  @override
  String lowStock(Object count) {
    return 'Articles en rupture: $count';
  }

  @override
  String totalValue(Object value) {
    return 'Valeur totale: $value RWF';
  }

  @override
  String get categories => 'Catégories:';

  @override
  String get deleteProduct => 'Supprimer le produit';

  @override
  String deleteProductConfirm(Object name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\"?';
  }

  @override
  String get productDeleted => 'Produit supprimé avec succès';

  @override
  String errorDeletingProduct(Object error) {
    return 'Erreur lors de la suppression du produit: $error';
  }

  @override
  String get productUpdated => 'Produit mis à jour!';

  @override
  String get productAdded => 'Produit ajouté!';

  @override
  String errorSavingProduct(Object error) {
    return 'Erreur lors de l\'enregistrement du produit: $error';
  }

  @override
  String get deleteCustomer => 'Supprimer le client';

  @override
  String deleteCustomerConfirm(Object name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\"? Cela supprimera également tout son historique de transactions.';
  }

  @override
  String get customerDeleted => 'Client supprimé avec succès';

  @override
  String get customerUpdated => 'Client mis à jour!';

  @override
  String get customerAdded => 'Client ajouté!';

  @override
  String get customerAnalytics => 'Analyse des clients';

  @override
  String totalCustomers(Object count) {
    return 'Nombre total de clients: $count';
  }

  @override
  String totalCreditOutstanding(Object amount) {
    return 'Crédit total en attente: $amount RWF';
  }

  @override
  String totalRevenue(Object amount) {
    return 'Revenu total: $amount RWF';
  }

  @override
  String get topCustomers => 'Meilleurs clients:';

  @override
  String get recentSales => 'Ventes récentes';

  @override
  String get saleRecorded => 'Vente enregistrée!';

  @override
  String get done => 'Terminé';

  @override
  String get selectProduct => 'Sélectionner un produit';

  @override
  String get chooseProduct => 'Choisir un produit';

  @override
  String get quantity => 'Quantité';

  @override
  String get totalPrice => 'Prix total';

  @override
  String get paymentMethod => 'Méthode de paiement';

  @override
  String get customer => 'Client';

  @override
  String get recordAnother => 'Enregistrer un autre';

  @override
  String get transactionHistory => 'Historique des transactions';

  @override
  String get currentCredit => 'Crédit actuel';

  @override
  String get totalSpent => 'Total dépensé';

  @override
  String get recentTransactions => 'Transactions Récentes';

  @override
  String get purchase => 'Achat';

  @override
  String get payment => 'Paiement';

  @override
  String get updateCreditFor => 'Mettre à jour le crédit pour';

  @override
  String get newCreditAmount => 'Nouveau montant de crédit';

  @override
  String get pleaseEnterCreditAmount => 'Veuillez entrer le montant du crédit';

  @override
  String get creditUpdatedTo => 'Crédit mis à jour à';

  @override
  String get update => 'Mettre à jour';

  @override
  String get updateCredit => 'Mettre à jour le crédit';

  @override
  String get searchCustomers => 'Rechercher des clients...';

  @override
  String get editCustomer => 'Modifier le client';

  @override
  String get addNewCustomer => 'Ajouter un nouveau client';

  @override
  String get customerName => 'Nom du client';

  @override
  String get pleaseEnterCustomerName => 'Veuillez entrer le nom du client';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get pleaseEnterPhoneNumber => 'Veuillez entrer le numéro de téléphone';

  @override
  String get emailOptional => 'E-mail (Optionnel)';

  @override
  String get initialCredit => 'Crédit initial';

  @override
  String get addFirstCustomer => 'Ajouter le premier client';

  @override
  String get credit => 'Crédit';

  @override
  String get salesTrends => 'Tendances des ventes';

  @override
  String get chartsPlaceholder => 'Les graphiques apparaîtront ici';

  @override
  String get businessInsights => 'Aperçus de l\'entreprise';

  @override
  String get insightsPlaceholder => 'Les aperçus apparaîtront ici';

  @override
  String get aboutHeadline => 'BizTrackr – Entreprise intelligente dans votre poche';

  @override
  String get keyFeatures => 'Fonctionnalités clés';

  @override
  String get ourVision => 'Notre vision';

  @override
  String get areYouSureYouWantToDelete => 'Êtes-vous sûr de vouloir supprimer';

  @override
  String get thisWillAlsoDeleteAllTheirTransactionHistory => 'Cela supprimera également tout leur historique de transactions.';

  @override
  String get noCustomersYet => 'Aucun client pour le moment';

  @override
  String get noCustomersFound => 'Aucun client trouvé';

  @override
  String get french => 'Français';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get editProduct => 'Modifier le produit';

  @override
  String get addNewProduct => 'Ajouter un nouveau produit';

  @override
  String get productName => 'Nom du produit';

  @override
  String get pleaseEnterProductName => 'Veuillez entrer le nom du produit';

  @override
  String get price => 'Prix';

  @override
  String get pleaseEnterPrice => 'Veuillez entrer le prix';

  @override
  String get stock => 'Stock';

  @override
  String get pleaseEnterStock => 'Veuillez entrer le stock';

  @override
  String get category => 'Catégorie';

  @override
  String get pleaseSelectCategory => 'Veuillez sélectionner une catégorie';

  @override
  String get noProductsYet => 'Aucun produit pour le moment';

  @override
  String get noProductsFound => 'Aucun produit trouvé';

  @override
  String get addFirstProduct => 'Ajouter le premier produit';

  @override
  String get updateStock => 'Mettre à jour le stock';

  @override
  String get newStockLevel => 'Nouveau niveau de stock';

  @override
  String get enterQuantity => 'Entrer la quantité';

  @override
  String get clearForm => 'Effacer le formulaire';

  @override
  String get monday => 'Lundi';

  @override
  String get tuesday => 'Mardi';

  @override
  String get wednesday => 'Mercredi';

  @override
  String get thursday => 'Jeudi';

  @override
  String get friday => 'Vendredi';

  @override
  String get saturday => 'Samedi';

  @override
  String get sunday => 'Dimanche';

  @override
  String get pickChartColor => 'Choisissez la couleur du graphique :';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get languageChanged => 'Langue changée avec succès';

  @override
  String get premiumUpgradeSuccess => 'Bienvenue dans Premium ! Profitez de toutes les fonctionnalités avancées.';

  @override
  String get premiumUpgradeError => 'Échec de la mise à niveau vers premium. Veuillez réessayer.';

  @override
  String get freeUserMessage => 'Vous utilisez la version gratuite. Passez à premium pour les fonctionnalités avancées.';

  @override
  String get premiumUserMessage => 'Vous êtes un utilisateur premium. Profitez de toutes les fonctionnalités !';

  @override
  String get upgradeToPremium => 'Passer à Premium';

  @override
  String get premiumBenefits => 'Avantages Premium';

  @override
  String get unlimitedFeatures => 'Fonctionnalités illimitées';

  @override
  String get advancedAnalytics => 'Analyses avancées';

  @override
  String get aiInsights => 'Insights IA';

  @override
  String get detailedReports => 'Rapports détaillés';

  @override
  String get prioritySupport => 'Support prioritaire';

  @override
  String get pleaseFillAllFields => 'Veuillez remplir tous les champs';

  @override
  String registrationFailed(Object error) {
    return 'Échec de l\'inscription : $error';
  }

  @override
  String loginFailed(Object error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String get notLoggedIn => 'Non connecté';

  @override
  String currentLanguage(Object language) {
    return 'Langue actuelle : $language';
  }

  @override
  String get signOutOfAccount => 'Se déconnecter de votre compte';

  @override
  String get accountManagement => 'Gestion du compte';

  @override
  String get premiumFeature => 'Fonctionnalité Premium';

  @override
  String get upgrade => 'Mettre à niveau';

  @override
  String get reportsPayment => 'Paiement des Rapports';

  @override
  String get reportsAnalyticsAccess => 'Accès aux Rapports et Analyses';

  @override
  String get unlockAdvancedReporting => 'Débloquez les fonctionnalités de rapport avancées';

  @override
  String get only5000RWF => 'Seulement 5000 RWF';

  @override
  String get pay5000RWF => 'Payer 5000 RWF';

  @override
  String get reportsSubscriptionMessage => 'Cette fonctionnalité nécessite un abonnement séparé. Payez 5000 RWF pour accéder aux Rapports.';

  @override
  String get paymentSuccessful => 'Paiement réussi !';

  @override
  String get reportsAccessGranted => 'Vous avez maintenant accès aux Rapports et Analyses.';

  @override
  String get creditCard => 'Carte de crédit';

  @override
  String get mobileMoney => 'Argent mobile';

  @override
  String get cardholderName => 'Nom du titulaire';

  @override
  String get cardNumber => 'Numéro de carte';

  @override
  String get expiryDate => 'MM/AA';

  @override
  String get cvv => 'CVV';

  @override
  String get mobileMoneyInfo => 'Vous recevrez une demande de paiement sur votre téléphone';

  @override
  String get processing => 'Traitement...';

  @override
  String get paymentError => 'Erreur de paiement';

  @override
  String get pleaseFillAllPaymentDetails => 'Veuillez remplir tous les détails de paiement';

  @override
  String get topProducts => 'Meilleurs Produits';

  @override
  String get viewAll => 'Voir Tout';

  @override
  String get notificationsComingSoon => 'Les notifications seront bientôt disponibles !';

  @override
  String get inStock => 'En stock';

  @override
  String get needAttention => 'Nécessite attention';

  @override
  String get outstanding => 'En attente';

  @override
  String get fromYesterday => '+12% d\'hier';

  @override
  String get currentPlan => 'Plan Actuel';

  @override
  String get inactive => 'Inactif';

  @override
  String get expiresOn => 'Expire le';

  @override
  String get usage => 'Utilisation';

  @override
  String get products => 'Produits';

  @override
  String get sales30Days => 'Ventes (30 jours)';

  @override
  String get availablePlans => 'Plans Disponibles';

  @override
  String get current => 'ACTUEL';

  @override
  String get chooseThisPlan => 'Choisir ce Plan';

  @override
  String get paymentHistory => 'Historique des Paiements';

  @override
  String get keyMetrics => 'Métriques Clés';

  @override
  String get aiAnalytics => 'Analyse IA';

  @override
  String get predictiveAnalysis => 'Analyse prédictive et recommandations IA';

  @override
  String get performanceMetrics => 'Métriques de Performance';

  @override
  String get minimizationStrategies => 'Stratégies de Minimisation';

  @override
  String get totalSales => 'Ventes Totales';

  @override
  String get transactions => 'Transactions';

  @override
  String get avgTransaction => 'Moyenne Transaction';

  @override
  String get growth => 'Croissance';

  @override
  String get noSalesDataAvailable => 'Aucune donnée de vente disponible';

  @override
  String get potentialSavings => 'Économies Potentielles';

  @override
  String get implementationTime => 'Temps de mise en œuvre';

  @override
  String get activeCustomers => 'Clients Actifs';

  @override
  String get productsSold => 'Produits Vendus';

  @override
  String get printReport => 'Imprimer le rapport';

  @override
  String get premiumReports => 'Rapports Premium';

  @override
  String get security => 'Sécurité';

  @override
  String get inSales => 'en ventes';

  @override
  String get encouragement => 'Astuce : Gardez un œil sur vos stocks pour éviter les ruptures !';

  @override
  String greeting(Object username) {
    return 'Bienvenue, $username! Continuez à exceller aujourd\'hui !';
  }

  @override
  String get viewReports => 'Voir les Rapports';

  @override
  String get salesReport => 'Rapport de Ventes';

  @override
  String get financialReport => 'Rapport Financier';

  @override
  String get overview => 'Vue d\'ensemble';

  @override
  String get sales => 'Ventes';

  @override
  String get finance => 'Finances';

  @override
  String get strategies => 'Stratégies';

  @override
  String get salesDetails => 'Détails des Ventes';

  @override
  String get numberOfTransactions => 'Nombre de Transactions';

  @override
  String get averagePerTransaction => 'Moyenne par Transaction';

  @override
  String get monthlyGrowth => 'Croissance Mensuelle';

  @override
  String get revenue => 'Revenus';

  @override
  String get expenses => 'Dépenses';

  @override
  String get profit => 'Profit';

  @override
  String get margin => 'Marge';

  @override
  String get costAnalysis => 'Analyse des Coûts';

  @override
  String get inventoryCosts => 'Coûts d\'Inventaire';

  @override
  String get operationalCosts => 'Coûts Opérationnels';

  @override
  String get marketingCosts => 'Coûts Marketing';

  @override
  String get print => 'Imprimer';

  @override
  String get reportPrintedSuccessfully => 'Rapport imprimé avec succès!';

  @override
  String errorPrinting(Object error) {
    return 'Erreur lors de l\'impression: $error';
  }

  @override
  String get salesReportPrinted => 'Rapport de ventes imprimé!';

  @override
  String get financialReportPrinted => 'Rapport financier imprimé!';
}
