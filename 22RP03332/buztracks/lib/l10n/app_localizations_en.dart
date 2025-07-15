// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BizTrackr';

  @override
  String get welcomeMessage => 'Welcome! Please select your language:';

  @override
  String get english => 'English';

  @override
  String get kinyarwanda => 'Kinyarwanda';

  @override
  String get aboutBizTrackr => 'About BizTrackr';

  @override
  String get dashboard => 'Dashboard';

  @override
  String welcomeUser(Object username) {
    return 'Welcome, $username!';
  }

  @override
  String get salesToday => 'Sales Today';

  @override
  String get lowStockItems => 'Low Stock Items';

  @override
  String get customerCredit => 'Customer Credit';

  @override
  String get salesThisWeek => 'Sales This Week';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get recordSale => 'Record Sale';

  @override
  String get inventory => 'Inventory';

  @override
  String get customers => 'Customers';

  @override
  String get reports => 'Reports & Analytics';

  @override
  String get aiChart => 'AI Chart';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get close => 'Close';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get changeAppLanguage => 'Change app language';

  @override
  String get account => 'Account';

  @override
  String get manageAccount => 'Manage your account';

  @override
  String get premium => 'Premium';

  @override
  String get active => 'Active';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get premiumRequired => 'Premium Required';

  @override
  String get premiumFeatureMessage => 'This feature is only available for premium users. Upgrade now to unlock advanced analytics, AI insights, and detailed reports.';

  @override
  String get upgradeNow => 'Upgrade Now';

  @override
  String get premiumFeatures => 'Premium Features';

  @override
  String get premiumFeaturesList => '• Advanced Analytics & Charts\n• AI Business Insights\n• Detailed Reports\n• Unlimited Data Storage\n• Priority Support';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get search => 'Search';

  @override
  String get noProducts => 'No products yet';

  @override
  String get noCustomers => 'No customers yet';

  @override
  String get totalProducts => 'Total Products';

  @override
  String lowStock(Object count) {
    return 'Low Stock Items: $count';
  }

  @override
  String totalValue(Object value) {
    return 'Total Value: $value RWF';
  }

  @override
  String get categories => 'Categories:';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String deleteProductConfirm(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get productDeleted => 'Product deleted successfully';

  @override
  String errorDeletingProduct(Object error) {
    return 'Error deleting product: $error';
  }

  @override
  String get productUpdated => 'Product updated!';

  @override
  String get productAdded => 'Product added!';

  @override
  String errorSavingProduct(Object error) {
    return 'Error saving product: $error';
  }

  @override
  String get deleteCustomer => 'Delete Customer';

  @override
  String deleteCustomerConfirm(Object name) {
    return 'Are you sure you want to delete \"$name\"? This will also delete all their transaction history.';
  }

  @override
  String get customerDeleted => 'Customer deleted successfully';

  @override
  String get customerUpdated => 'Customer updated!';

  @override
  String get customerAdded => 'Customer added!';

  @override
  String get customerAnalytics => 'Customer Analytics';

  @override
  String totalCustomers(Object count) {
    return 'Total Customers: $count';
  }

  @override
  String totalCreditOutstanding(Object amount) {
    return 'Total Credit Outstanding: $amount RWF';
  }

  @override
  String totalRevenue(Object amount) {
    return 'Total Revenue: $amount RWF';
  }

  @override
  String get topCustomers => 'Top Customers:';

  @override
  String get recentSales => 'Recent Sales';

  @override
  String get saleRecorded => 'Sale Recorded!';

  @override
  String get done => 'Done';

  @override
  String get selectProduct => 'Select Product';

  @override
  String get chooseProduct => 'Choose Product';

  @override
  String get quantity => 'Quantity';

  @override
  String get totalPrice => 'Total Price';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get customer => 'Customer';

  @override
  String get recordAnother => 'Record Another';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get currentCredit => 'Current Credit';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get purchase => 'Purchase';

  @override
  String get payment => 'Payment';

  @override
  String get updateCreditFor => 'Update Credit for';

  @override
  String get newCreditAmount => 'New Credit Amount';

  @override
  String get pleaseEnterCreditAmount => 'Please enter credit amount';

  @override
  String get creditUpdatedTo => 'Credit updated to';

  @override
  String get update => 'Update';

  @override
  String get updateCredit => 'Update Credit';

  @override
  String get searchCustomers => 'Search customers...';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get addNewCustomer => 'Add New Customer';

  @override
  String get customerName => 'Customer Name';

  @override
  String get pleaseEnterCustomerName => 'Please enter customer name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter phone number';

  @override
  String get emailOptional => 'Email (Optional)';

  @override
  String get initialCredit => 'Initial Credit';

  @override
  String get addFirstCustomer => 'Add First Customer';

  @override
  String get credit => 'Credit';

  @override
  String get salesTrends => 'Sales Trends';

  @override
  String get chartsPlaceholder => 'Charts will appear here';

  @override
  String get businessInsights => 'Business Insights';

  @override
  String get insightsPlaceholder => 'Insights will appear here';

  @override
  String get aboutHeadline => 'BizTrackr – Smart Business in Your Pocket';

  @override
  String get keyFeatures => 'Key Features';

  @override
  String get ourVision => 'Our Vision';

  @override
  String get areYouSureYouWantToDelete => 'Are you sure you want to delete';

  @override
  String get thisWillAlsoDeleteAllTheirTransactionHistory => 'This will also delete all their transaction history.';

  @override
  String get noCustomersYet => 'No customers yet';

  @override
  String get noCustomersFound => 'No customers found';

  @override
  String get french => 'French';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get username => 'Username';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get addNewProduct => 'Add New Product';

  @override
  String get productName => 'Product Name';

  @override
  String get pleaseEnterProductName => 'Please enter product name';

  @override
  String get price => 'Price';

  @override
  String get pleaseEnterPrice => 'Please enter price';

  @override
  String get stock => 'Stock';

  @override
  String get pleaseEnterStock => 'Please enter stock';

  @override
  String get category => 'Category';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get noProductsYet => 'No products yet';

  @override
  String get noProductsFound => 'No products found';

  @override
  String get addFirstProduct => 'Add First Product';

  @override
  String get updateStock => 'Update Stock';

  @override
  String get newStockLevel => 'New Stock Level';

  @override
  String get enterQuantity => 'Enter Quantity';

  @override
  String get clearForm => 'Clear Form';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get pickChartColor => 'Pick chart color:';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageChanged => 'Language changed successfully';

  @override
  String get premiumUpgradeSuccess => 'Welcome to Premium! Enjoy all advanced features.';

  @override
  String get premiumUpgradeError => 'Failed to upgrade to premium. Please try again.';

  @override
  String get freeUserMessage => 'You are using the free version. Upgrade to premium for advanced features.';

  @override
  String get premiumUserMessage => 'You are a premium user. Enjoy all features!';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String get premiumBenefits => 'Premium Benefits';

  @override
  String get unlimitedFeatures => 'Unlimited Features';

  @override
  String get advancedAnalytics => 'Advanced Analytics';

  @override
  String get aiInsights => 'AI Insights';

  @override
  String get detailedReports => 'Detailed Reports';

  @override
  String get prioritySupport => 'Priority Support';

  @override
  String get pleaseFillAllFields => 'Please fill all fields';

  @override
  String registrationFailed(Object error) {
    return 'Registration failed: $error';
  }

  @override
  String loginFailed(Object error) {
    return 'Login failed: $error';
  }

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String currentLanguage(Object language) {
    return 'Current language: $language';
  }

  @override
  String get signOutOfAccount => 'Sign out of your account';

  @override
  String get accountManagement => 'Account Management';

  @override
  String get premiumFeature => 'Premium Feature';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get reportsPayment => 'Reports Payment';

  @override
  String get reportsAnalyticsAccess => 'Reports & Analytics Access';

  @override
  String get unlockAdvancedReporting => 'Unlock advanced reporting features';

  @override
  String get only5000RWF => 'Only 5000 RWF';

  @override
  String get pay5000RWF => 'Pay 5000 RWF';

  @override
  String get reportsSubscriptionMessage => 'This feature requires a separate subscription. Pay 5000 RWF to access Reports.';

  @override
  String get paymentSuccessful => 'Payment Successful!';

  @override
  String get reportsAccessGranted => 'You now have access to Reports & Analytics.';

  @override
  String get creditCard => 'Credit Card';

  @override
  String get mobileMoney => 'Mobile Money';

  @override
  String get cardholderName => 'Cardholder Name';

  @override
  String get cardNumber => 'Card Number';

  @override
  String get expiryDate => 'MM/YY';

  @override
  String get cvv => 'CVV';

  @override
  String get mobileMoneyInfo => 'You will receive a payment prompt on your phone';

  @override
  String get processing => 'Processing...';

  @override
  String get paymentError => 'Payment Error';

  @override
  String get pleaseFillAllPaymentDetails => 'Please fill all payment details';

  @override
  String get topProducts => 'Top Products';

  @override
  String get viewAll => 'View All';

  @override
  String get notificationsComingSoon => 'Notifications will be available soon!';

  @override
  String get inStock => 'In stock';

  @override
  String get needAttention => 'Need attention';

  @override
  String get outstanding => 'Outstanding';

  @override
  String get fromYesterday => '+12% from yesterday';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String get inactive => 'Inactive';

  @override
  String get expiresOn => 'Expires on';

  @override
  String get usage => 'Usage';

  @override
  String get products => 'Products';

  @override
  String get sales30Days => 'Sales (30 days)';

  @override
  String get availablePlans => 'Available Plans';

  @override
  String get current => 'CURRENT';

  @override
  String get chooseThisPlan => 'Choose This Plan';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get keyMetrics => 'Key Metrics';

  @override
  String get aiAnalytics => 'AI Analytics';

  @override
  String get predictiveAnalysis => 'Predictive analysis and AI recommendations';

  @override
  String get performanceMetrics => 'Performance Metrics';

  @override
  String get minimizationStrategies => 'Minimization Strategies';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get transactions => 'Transactions';

  @override
  String get avgTransaction => 'Avg Transaction';

  @override
  String get growth => 'Growth';

  @override
  String get noSalesDataAvailable => 'No sales data available';

  @override
  String get potentialSavings => 'Potential Savings';

  @override
  String get implementationTime => 'Implementation time';

  @override
  String get activeCustomers => 'Active Customers';

  @override
  String get productsSold => 'Products Sold';

  @override
  String get printReport => 'Print report';

  @override
  String get premiumReports => 'Premium Reports';

  @override
  String get security => 'Security';

  @override
  String get inSales => 'in sales';

  @override
  String get encouragement => 'Tip: Keep an eye on your stock to avoid shortages!';

  @override
  String greeting(Object username) {
    return 'Welcome, $username! Keep excelling today!';
  }

  @override
  String get viewReports => 'View Reports';

  @override
  String get salesReport => 'Sales Report';

  @override
  String get financialReport => 'Financial Report';

  @override
  String get overview => 'Overview';

  @override
  String get sales => 'Sales';

  @override
  String get finance => 'Finance';

  @override
  String get strategies => 'Strategies';

  @override
  String get salesDetails => 'Sales Details';

  @override
  String get numberOfTransactions => 'Number of Transactions';

  @override
  String get averagePerTransaction => 'Average per Transaction';

  @override
  String get monthlyGrowth => 'Monthly Growth';

  @override
  String get revenue => 'Revenue';

  @override
  String get expenses => 'Expenses';

  @override
  String get profit => 'Profit';

  @override
  String get margin => 'Margin';

  @override
  String get costAnalysis => 'Cost Analysis';

  @override
  String get inventoryCosts => 'Inventory Costs';

  @override
  String get operationalCosts => 'Operational Costs';

  @override
  String get marketingCosts => 'Marketing Costs';

  @override
  String get print => 'Print';

  @override
  String get reportPrintedSuccessfully => 'Report printed successfully!';

  @override
  String errorPrinting(Object error) {
    return 'Error printing: $error';
  }

  @override
  String get salesReportPrinted => 'Sales report printed!';

  @override
  String get financialReportPrinted => 'Financial report printed!';
}
