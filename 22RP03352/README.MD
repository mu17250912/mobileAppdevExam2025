# BudgetWise - Smart Budget Management App

**Student Registration Number:** 22RP03352  
**Academic Year:** 2024-2025  
**Module:** Mobile Application Development (ITLMA701)  
**Developer:** Sandrine Irah

## 📱 App Overview

BudgetWise is a budget management mobile application built with Flutter that helps users track their expenses, manage budgets by category, and visualize their spending with comprehensive analytics and progress indicators.

## 🎯 Problem Statement

**The Problem:** Many people struggle with managing their personal finances due to:
- Lack of awareness about spending patterns
- Difficulty tracking expenses across multiple categories
- No clear visualization of budget vs. actual spending

**Our Solution:** BudgetWise provides an intuitive, user-friendly platform that:
- Simplifies expense tracking and categorization
- Provides real-time budget monitoring with visual progress indicators
- Offers comprehensive analytics with charts, trends, and insights for premium users

## 👥 Target Audience

- Young professionals and students managing personal budgets
- Anyone who wants a simple, mobile-first budgeting tool

## 🏆 Unique Selling Proposition (USP)

- **Category-Based Budgeting:** Easy-to-use interface for setting and tracking budgets by category
- **Visual Progress:** Progress bars and circular indicators for budget utilization
- **Firebase-Powered:** Secure, scalable cloud-based data storage
- **Gamification:** Monthly badges and confetti for first expense and first budget each month
- **Advanced Analytics:** Comprehensive charts, trends, and insights for premium users

## 💰 Monetization Strategy

BudgetWise uses a **freemium monetization strategy**:

- **Free users:**
  - Access all core budgeting and expense features
  - See banner ads (Google AdMob) in the app
- **Premium (Simulated Payment):**
  - Removes ads
  - Unlocks access to comprehensive Analytics and Enhanced Analytics screens
  - Access to advanced analytics, charts, trends, and insights
  - Data export functionality (CSV, TXT formats)
  - **Upgrade is done through a realistic payment simulation (no real money is collected)**

### **Commission-Based Monetization (Affiliate Link)**
- The app includes a commission-based monetization feature via an affiliate link (Amazon).
- When users click the "Shop on Amazon (Affiliate)" button, they are redirected to Amazon using a referral link.
- Each click is tracked using Firebase Analytics (`ad_interaction` event with `adType: 'affiliate'`).
- In a real deployment, this would use a valid affiliate ID to earn commissions on qualifying purchases. For this assessment, the affiliate link is a placeholder and no real commissions are earned.

> **Note:** Payment/subscription logic is **simulated only**. The "Go Premium" button launches a realistic payment flow, but no real money is collected. All payment screens, validation, and history are for demonstration purposes only.
> 
> **Why No Real Income Collection:** This is a student project focused on demonstrating technical skills and monetization concepts. Real payment processing, affiliate accounts, and ad revenue require business registration, compliance, and published app status - the app has not been published yet.

## 🔧 Key Features Implemented

### **Core Features:**
- User authentication (Firebase Auth)
- Create and manage budgets by category
- Add and categorize expenses
- Visual progress indicators (circular and linear)
- Quick actions (add expense, view budgets)
- AdMob banner ads for free users
- Affiliate button (Amazon link)
- Analytics event tracking (Firebase Analytics)

### **Premium Features (Simulated Payment):**
- **Realistic payment simulation for premium upgrades:**
  - Multiple payment methods (Credit Card, Debit Card, PayPal, Apple Pay, MTN Mobile Money, Airtel Money, M-Pesa, Orange Money)
  - Card number validation and card type detection
  - Mobile money phone number validation
  - Simulated payment errors (declined, insufficient funds, etc.)
  - Professional payment form UI with mobile money support
  - Payment summary and confirmation dialogs
  - **Transaction History with Firestore Integration:**
  - Real-time transaction data stored in Firestore
  - Clean empty state for new users (no sample data)
  - Clear transaction history functionality
  - Detailed transaction information with payment methods
  - Sorted by date (newest first)
- **Push notification sent after successful upgrade**
- **Downgrade to Freemium functionality** - Premium users can downgrade back to freemium
- **Synchronous UI Updates** - Home screen refreshes immediately after upgrade/downgrade
- No real money is collected; all payments are simulated for demo purposes
- **Comprehensive Analytics Screen:**
  - Pie charts for spending by category
  - Bar charts for monthly spending trends
  - Budget vs actual spending comparisons
  - Interactive charts with real data
- **Enhanced Analytics Screen:**
  - Advanced insights and recommendations
  - Comprehensive spending analysis
  - AI-powered financial insights
  - Detailed trend analysis
- **Data Export Functionality:**
  - Export expenses to CSV format
  - Export budget reports to CSV
  - Export monthly summaries to TXT
  - Share functionality for exported files
- Ad removal (UI only, no real payment logic)

### **Gamification & Engagement:**
- **Monthly Badges:**
  - Earn a badge and see a confetti animation every time you add your first expense or first budget for each month.
  - Badges are stored in Firestore and sync across devices.
  - Motivates users to keep tracking and budgeting every month.
- **Confetti Animation:**
  - Fun, celebratory confetti appears with a congratulatory dialog when a badge is earned.
- **Push Notification:**
  - After a successful premium upgrade, users receive a local push notification.
- **No Streaks:**
  - The streaks feature has been removed for a cleaner experience.

## 📊 Analytics & Tracking

- **Firebase Analytics** integration for user actions (budget creation, expense addition, feature usage, etc.)
- Analytics events can be viewed in Firebase DebugView and Events tab
- **Comprehensive Analytics Implementation:**
  - Real-time spending analysis by category
  - Monthly trend analysis with interactive charts
  - Budget vs actual spending comparisons
  - Enhanced analytics with AI insights and recommendations

### **How to View Analytics Data:**
1. Go to [Firebase Console](https://console.firebase.google.com/), select your project.
2. Navigate to **Analytics > DebugView** for real-time events, or **Analytics > Events** for aggregated data (may take up to 24 hours).
3. Use the app or the Test Analytics button (debug mode) to see events appear.

## 🔒 Security & Reliability

- **Security:**
  - Firebase Security Rules for database access
  - Secure login with Firebase Auth
  - Data privacy awareness (GDPR/local compliance considered)
  - All data sent over secure HTTPS
  - Only authenticated users can access their own data
  - Secure API handling (all backend via Firebase)
- **Reliability:**
  - App tested on Android emulator and real device
  - Error handling for network and data issues
  - Bug fixing through iterative testing
  - No known critical bugs at submission

## ♿ Accessibility

- **Accessibility Service Implementation:**
  - Screen reader support with semantic labels
  - Navigation guidance for different screens
  - Accessibility hints for interactive elements
  - High contrast mode support
  - Large text support
  - Focus management for keyboard navigation
- **Current Features:**
  - Semantic labels for all major UI elements
  - Screen reader announcements
  - Accessibility hints for user interactions
  - Voice guidance for navigation

## 🚀 Scalability & Performance

- Firebase backend for scalability
- Modular code structure for easy updates
- Efficient data handling and queries
- Designed for future growth in users and data

## 🔄 Sustainability Plan

- Codebase structured for easy updates and maintenance
- **Feedback Loops:** User feedback will be collected via app reviews and future in-app feedback forms
- **CAC Strategies:** Organic growth (word-of-mouth), potential referral programs (planned)
- **User Retention/Engagement:**
  - Core features are simple and useful
  - **Monthly badges and confetti for first expense and budget each month**
  - **Push notification after premium upgrade to increase engagement**
  - Future plans for more push notifications, gamification, and loyalty programs
- **Continuous Updates:** Planned for new features and security improvements

## 📱 Installation Instructions

### **For End Users:**
1. Download the APK file from provided zip folder.
2. Enable "Install from Unknown Sources" in Android settings
3. Install the APK file
4. Open the app and create an account
5. Start managing your budget!

### **For Developers:**
1. Clone the repository(https://github.com/Sandrine-Ira/mobileAppdevExam2025.git)
2. Install Flutter dependencies: `flutter pub get`
3. Configure Firebase project
4. Run the app: `flutter run`

## 🛠️ Technical Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Firestore, Authentication, Analytics)
- **Ads:** Google AdMob
- **State Management:** Flutter StatefulWidget
- **UI Framework:** Material Design
- **Charts:** fl_chart for data visualization
- **Export:** share_plus for file sharing
- **Version Control:** Git

## 📈 Future Roadmap (Planned/Not Yet Implemented)
- Real payment/subscription for premium (currently simulated)
- Community features (forums, support)
- Bill reminders, investment tracking, financial goals
- AI-powered insights, banking API, multi-currency
- More advanced push notifications (beyond upgrade event)
- More gamification (additional badges, challenges, etc.)

## 📞 Support & Contact

- **Email:** irashimwakmsandrine@gmail.com
- **GitHub:** https://github.com/Sandrine-Ira/mobileAppdevExam2025.git

---

**Note:** This project is developed as part of the Mobile Application Development module assessment. Most features are fully implemented and functional, with payment processing simulated for educational purposes.
