import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_rw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('rw')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BizTrackr'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Please select your language:'**
  String get welcomeMessage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @kinyarwanda.
  ///
  /// In en, this message translates to:
  /// **'Kinyarwanda'**
  String get kinyarwanda;

  /// No description provided for @aboutBizTrackr.
  ///
  /// In en, this message translates to:
  /// **'About BizTrackr'**
  String get aboutBizTrackr;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {username}!'**
  String welcomeUser(Object username);

  /// No description provided for @salesToday.
  ///
  /// In en, this message translates to:
  /// **'Sales Today'**
  String get salesToday;

  /// No description provided for @lowStockItems.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Items'**
  String get lowStockItems;

  /// No description provided for @customerCredit.
  ///
  /// In en, this message translates to:
  /// **'Customer Credit'**
  String get customerCredit;

  /// No description provided for @salesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Sales This Week'**
  String get salesThisWeek;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @recordSale.
  ///
  /// In en, this message translates to:
  /// **'Record Sale'**
  String get recordSale;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get reports;

  /// No description provided for @aiChart.
  ///
  /// In en, this message translates to:
  /// **'AI Chart'**
  String get aiChart;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get changeAppLanguage;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @manageAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage your account'**
  String get manageAccount;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @premiumRequired.
  ///
  /// In en, this message translates to:
  /// **'Premium Required'**
  String get premiumRequired;

  /// No description provided for @premiumFeatureMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature is only available for premium users. Upgrade now to unlock advanced analytics, AI insights, and detailed reports.'**
  String get premiumFeatureMessage;

  /// No description provided for @upgradeNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeNow;

  /// No description provided for @premiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get premiumFeatures;

  /// No description provided for @premiumFeaturesList.
  ///
  /// In en, this message translates to:
  /// **'• Advanced Analytics & Charts\n• AI Business Insights\n• Detailed Reports\n• Unlimited Data Storage\n• Priority Support'**
  String get premiumFeaturesList;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProducts;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomers;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Items: {count}'**
  String lowStock(Object count);

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value: {value} RWF'**
  String totalValue(Object value);

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories:'**
  String get categories;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteProductConfirm(Object name);

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully'**
  String get productDeleted;

  /// No description provided for @errorDeletingProduct.
  ///
  /// In en, this message translates to:
  /// **'Error deleting product: {error}'**
  String errorDeletingProduct(Object error);

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated!'**
  String get productUpdated;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added!'**
  String get productAdded;

  /// No description provided for @errorSavingProduct.
  ///
  /// In en, this message translates to:
  /// **'Error saving product: {error}'**
  String errorSavingProduct(Object error);

  /// No description provided for @deleteCustomer.
  ///
  /// In en, this message translates to:
  /// **'Delete Customer'**
  String get deleteCustomer;

  /// No description provided for @deleteCustomerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This will also delete all their transaction history.'**
  String deleteCustomerConfirm(Object name);

  /// No description provided for @customerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Customer deleted successfully'**
  String get customerDeleted;

  /// No description provided for @customerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Customer updated!'**
  String get customerUpdated;

  /// No description provided for @customerAdded.
  ///
  /// In en, this message translates to:
  /// **'Customer added!'**
  String get customerAdded;

  /// No description provided for @customerAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Customer Analytics'**
  String get customerAnalytics;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Customers: {count}'**
  String totalCustomers(Object count);

  /// No description provided for @totalCreditOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total Credit Outstanding: {amount} RWF'**
  String totalCreditOutstanding(Object amount);

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue: {amount} RWF'**
  String totalRevenue(Object amount);

  /// No description provided for @topCustomers.
  ///
  /// In en, this message translates to:
  /// **'Top Customers:'**
  String get topCustomers;

  /// No description provided for @recentSales.
  ///
  /// In en, this message translates to:
  /// **'Recent Sales'**
  String get recentSales;

  /// No description provided for @saleRecorded.
  ///
  /// In en, this message translates to:
  /// **'Sale Recorded!'**
  String get saleRecorded;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProduct;

  /// No description provided for @chooseProduct.
  ///
  /// In en, this message translates to:
  /// **'Choose Product'**
  String get chooseProduct;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @recordAnother.
  ///
  /// In en, this message translates to:
  /// **'Record Another'**
  String get recordAnother;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @currentCredit.
  ///
  /// In en, this message translates to:
  /// **'Current Credit'**
  String get currentCredit;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @updateCreditFor.
  ///
  /// In en, this message translates to:
  /// **'Update Credit for'**
  String get updateCreditFor;

  /// No description provided for @newCreditAmount.
  ///
  /// In en, this message translates to:
  /// **'New Credit Amount'**
  String get newCreditAmount;

  /// No description provided for @pleaseEnterCreditAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter credit amount'**
  String get pleaseEnterCreditAmount;

  /// No description provided for @creditUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Credit updated to'**
  String get creditUpdatedTo;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @updateCredit.
  ///
  /// In en, this message translates to:
  /// **'Update Credit'**
  String get updateCredit;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers...'**
  String get searchCustomers;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// No description provided for @addNewCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add New Customer'**
  String get addNewCustomer;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @pleaseEnterCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Please enter customer name'**
  String get pleaseEnterCustomerName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get emailOptional;

  /// No description provided for @initialCredit.
  ///
  /// In en, this message translates to:
  /// **'Initial Credit'**
  String get initialCredit;

  /// No description provided for @addFirstCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add First Customer'**
  String get addFirstCustomer;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @salesTrends.
  ///
  /// In en, this message translates to:
  /// **'Sales Trends'**
  String get salesTrends;

  /// No description provided for @chartsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Charts will appear here'**
  String get chartsPlaceholder;

  /// No description provided for @businessInsights.
  ///
  /// In en, this message translates to:
  /// **'Business Insights'**
  String get businessInsights;

  /// No description provided for @insightsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Insights will appear here'**
  String get insightsPlaceholder;

  /// No description provided for @aboutHeadline.
  ///
  /// In en, this message translates to:
  /// **'BizTrackr – Smart Business in Your Pocket'**
  String get aboutHeadline;

  /// No description provided for @keyFeatures.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get keyFeatures;

  /// No description provided for @ourVision.
  ///
  /// In en, this message translates to:
  /// **'Our Vision'**
  String get ourVision;

  /// No description provided for @areYouSureYouWantToDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get areYouSureYouWantToDelete;

  /// No description provided for @thisWillAlsoDeleteAllTheirTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'This will also delete all their transaction history.'**
  String get thisWillAlsoDeleteAllTheirTransactionHistory;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomersYet;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @addNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @pleaseEnterProductName.
  ///
  /// In en, this message translates to:
  /// **'Please enter product name'**
  String get pleaseEnterProductName;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @pleaseEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter price'**
  String get pleaseEnterPrice;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @pleaseEnterStock.
  ///
  /// In en, this message translates to:
  /// **'Please enter stock'**
  String get pleaseEnterStock;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYet;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @addFirstProduct.
  ///
  /// In en, this message translates to:
  /// **'Add First Product'**
  String get addFirstProduct;

  /// No description provided for @updateStock.
  ///
  /// In en, this message translates to:
  /// **'Update Stock'**
  String get updateStock;

  /// No description provided for @newStockLevel.
  ///
  /// In en, this message translates to:
  /// **'New Stock Level'**
  String get newStockLevel;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter Quantity'**
  String get enterQuantity;

  /// No description provided for @clearForm.
  ///
  /// In en, this message translates to:
  /// **'Clear Form'**
  String get clearForm;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @pickChartColor.
  ///
  /// In en, this message translates to:
  /// **'Pick chart color:'**
  String get pickChartColor;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @premiumUpgradeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Premium! Enjoy all advanced features.'**
  String get premiumUpgradeSuccess;

  /// No description provided for @premiumUpgradeError.
  ///
  /// In en, this message translates to:
  /// **'Failed to upgrade to premium. Please try again.'**
  String get premiumUpgradeError;

  /// No description provided for @freeUserMessage.
  ///
  /// In en, this message translates to:
  /// **'You are using the free version. Upgrade to premium for advanced features.'**
  String get freeUserMessage;

  /// No description provided for @premiumUserMessage.
  ///
  /// In en, this message translates to:
  /// **'You are a premium user. Enjoy all features!'**
  String get premiumUserMessage;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @premiumBenefits.
  ///
  /// In en, this message translates to:
  /// **'Premium Benefits'**
  String get premiumBenefits;

  /// No description provided for @unlimitedFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Features'**
  String get unlimitedFeatures;

  /// No description provided for @advancedAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics'**
  String get advancedAnalytics;

  /// No description provided for @aiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get aiInsights;

  /// No description provided for @detailedReports.
  ///
  /// In en, this message translates to:
  /// **'Detailed Reports'**
  String get detailedReports;

  /// No description provided for @prioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority Support'**
  String get prioritySupport;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed: {error}'**
  String registrationFailed(Object error);

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(Object error);

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current language: {language}'**
  String currentLanguage(Object language);

  /// No description provided for @signOutOfAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutOfAccount;

  /// No description provided for @accountManagement.
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get accountManagement;

  /// No description provided for @premiumFeature.
  ///
  /// In en, this message translates to:
  /// **'Premium Feature'**
  String get premiumFeature;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @reportsPayment.
  ///
  /// In en, this message translates to:
  /// **'Reports Payment'**
  String get reportsPayment;

  /// No description provided for @reportsAnalyticsAccess.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics Access'**
  String get reportsAnalyticsAccess;

  /// No description provided for @unlockAdvancedReporting.
  ///
  /// In en, this message translates to:
  /// **'Unlock advanced reporting features'**
  String get unlockAdvancedReporting;

  /// No description provided for @only5000RWF.
  ///
  /// In en, this message translates to:
  /// **'Only 5000 RWF'**
  String get only5000RWF;

  /// No description provided for @pay5000RWF.
  ///
  /// In en, this message translates to:
  /// **'Pay 5000 RWF'**
  String get pay5000RWF;

  /// No description provided for @reportsSubscriptionMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature requires a separate subscription. Pay 5000 RWF to access Reports.'**
  String get reportsSubscriptionMessage;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccessful;

  /// No description provided for @reportsAccessGranted.
  ///
  /// In en, this message translates to:
  /// **'You now have access to Reports & Analytics.'**
  String get reportsAccessGranted;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// No description provided for @mobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Mobile Money'**
  String get mobileMoney;

  /// No description provided for @cardholderName.
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get cardholderName;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'MM/YY'**
  String get expiryDate;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @mobileMoneyInfo.
  ///
  /// In en, this message translates to:
  /// **'You will receive a payment prompt on your phone'**
  String get mobileMoneyInfo;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @paymentError.
  ///
  /// In en, this message translates to:
  /// **'Payment Error'**
  String get paymentError;

  /// No description provided for @pleaseFillAllPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Please fill all payment details'**
  String get pleaseFillAllPaymentDetails;

  /// No description provided for @topProducts.
  ///
  /// In en, this message translates to:
  /// **'Top Products'**
  String get topProducts;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @notificationsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Notifications will be available soon!'**
  String get notificationsComingSoon;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @needAttention.
  ///
  /// In en, this message translates to:
  /// **'Need attention'**
  String get needAttention;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @fromYesterday.
  ///
  /// In en, this message translates to:
  /// **'+12% from yesterday'**
  String get fromYesterday;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires on'**
  String get expiresOn;

  /// No description provided for @usage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get usage;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @sales30Days.
  ///
  /// In en, this message translates to:
  /// **'Sales (30 days)'**
  String get sales30Days;

  /// No description provided for @availablePlans.
  ///
  /// In en, this message translates to:
  /// **'Available Plans'**
  String get availablePlans;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get current;

  /// No description provided for @chooseThisPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose This Plan'**
  String get chooseThisPlan;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @keyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Key Metrics'**
  String get keyMetrics;

  /// No description provided for @aiAnalytics.
  ///
  /// In en, this message translates to:
  /// **'AI Analytics'**
  String get aiAnalytics;

  /// No description provided for @predictiveAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Predictive analysis and AI recommendations'**
  String get predictiveAnalysis;

  /// No description provided for @performanceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Performance Metrics'**
  String get performanceMetrics;

  /// No description provided for @minimizationStrategies.
  ///
  /// In en, this message translates to:
  /// **'Minimization Strategies'**
  String get minimizationStrategies;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSales;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @avgTransaction.
  ///
  /// In en, this message translates to:
  /// **'Avg Transaction'**
  String get avgTransaction;

  /// No description provided for @growth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get growth;

  /// No description provided for @noSalesDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No sales data available'**
  String get noSalesDataAvailable;

  /// No description provided for @potentialSavings.
  ///
  /// In en, this message translates to:
  /// **'Potential Savings'**
  String get potentialSavings;

  /// No description provided for @implementationTime.
  ///
  /// In en, this message translates to:
  /// **'Implementation time'**
  String get implementationTime;

  /// No description provided for @activeCustomers.
  ///
  /// In en, this message translates to:
  /// **'Active Customers'**
  String get activeCustomers;

  /// No description provided for @productsSold.
  ///
  /// In en, this message translates to:
  /// **'Products Sold'**
  String get productsSold;

  /// No description provided for @printReport.
  ///
  /// In en, this message translates to:
  /// **'Print report'**
  String get printReport;

  /// No description provided for @premiumReports.
  ///
  /// In en, this message translates to:
  /// **'Premium Reports'**
  String get premiumReports;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @inSales.
  ///
  /// In en, this message translates to:
  /// **'in sales'**
  String get inSales;

  /// No description provided for @encouragement.
  ///
  /// In en, this message translates to:
  /// **'Tip: Keep an eye on your stock to avoid shortages!'**
  String get encouragement;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {username}! Keep excelling today!'**
  String greeting(Object username);

  /// No description provided for @viewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get viewReports;

  /// No description provided for @salesReport.
  ///
  /// In en, this message translates to:
  /// **'Sales Report'**
  String get salesReport;

  /// No description provided for @financialReport.
  ///
  /// In en, this message translates to:
  /// **'Financial Report'**
  String get financialReport;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @strategies.
  ///
  /// In en, this message translates to:
  /// **'Strategies'**
  String get strategies;

  /// No description provided for @salesDetails.
  ///
  /// In en, this message translates to:
  /// **'Sales Details'**
  String get salesDetails;

  /// No description provided for @numberOfTransactions.
  ///
  /// In en, this message translates to:
  /// **'Number of Transactions'**
  String get numberOfTransactions;

  /// No description provided for @averagePerTransaction.
  ///
  /// In en, this message translates to:
  /// **'Average per Transaction'**
  String get averagePerTransaction;

  /// No description provided for @monthlyGrowth.
  ///
  /// In en, this message translates to:
  /// **'Monthly Growth'**
  String get monthlyGrowth;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @margin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get margin;

  /// No description provided for @costAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Cost Analysis'**
  String get costAnalysis;

  /// No description provided for @inventoryCosts.
  ///
  /// In en, this message translates to:
  /// **'Inventory Costs'**
  String get inventoryCosts;

  /// No description provided for @operationalCosts.
  ///
  /// In en, this message translates to:
  /// **'Operational Costs'**
  String get operationalCosts;

  /// No description provided for @marketingCosts.
  ///
  /// In en, this message translates to:
  /// **'Marketing Costs'**
  String get marketingCosts;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @reportPrintedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Report printed successfully!'**
  String get reportPrintedSuccessfully;

  /// No description provided for @errorPrinting.
  ///
  /// In en, this message translates to:
  /// **'Error printing: {error}'**
  String errorPrinting(Object error);

  /// No description provided for @salesReportPrinted.
  ///
  /// In en, this message translates to:
  /// **'Sales report printed!'**
  String get salesReportPrinted;

  /// No description provided for @financialReportPrinted.
  ///
  /// In en, this message translates to:
  /// **'Financial report printed!'**
  String get financialReportPrinted;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr', 'rw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'rw': return AppLocalizationsRw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
