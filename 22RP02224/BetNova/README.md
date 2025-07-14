# BetNova

I.	Idea Generation & Market Fit
1.	Real-World Problem 
Many people like to bet on football and other sports, but most betting apps do not show local matches or are hard to use. My app solves this by giving users in Rwanda and nearby countries an easy way to bet on local and international games using their phones.

2.	Target Audience.

My target audience is sports fans in Rwanda and nearby countries who use smartphones and want a simple, secure way to bet on football, basketball, and volleyball matches — especially local teams and leagues.

3. USP & Competitive Advantage.

Most betting apps are made for international users and ignore local teams. My app is different because it shows local matches, supports local leagues, and has an easy-to-use design for beginners. Only the admin can approve bets and set results, making it safer and more controlled.

4. Justification (How App Solves the Problem).

My app solves the problem by allowing users to easily bet on local and international matches through a simple mobile interface. It shows local teams, supports live matches, and lets users track their bets. Admin approval ensures fairness and security, which builds trust for local users.


II.	App Development & Implementation.

1.	Core Features
Here’s a clear and short answer based on My app BetNova:

A.	 User-Centric Design.
•	The app has a clean and simple design, making it easy for users to navigate.
•	It loads quickly on most Android phones.
•	I tested it on emulators and real devices to ensure it works well.
•	I used large buttons, clear icons, and readable fonts for better accessibility.

B.	Authentication & User Profiles
•	I used Firebase Authentication to let users sign up or log in with email and password.
•	Each user has a secure profile that shows their name, email, and betting history.
•	Only verified users can place bets.

C.	Key Functionality.
•	Users can view matches, select odds, and place bets.
•	Bets go to the admin for approval.
•	Admin can approve/reject bets, set match results, and manage teams and matches.
•	Users can see the status of each bet: Pending, Approved, Won, or Lost.

2. Income Generation Features.

•	I used Ad integration with Google AdMob to earn money from the app. Ads are shown on the home screen and match pages, so every time users open and use the app, I can generate revenue.
•	I chose this because it's simple to set up, doesn't require users to pay directly, and works well for apps with many active users.



3.	Payment Integration (Bonus).
I added a simulated MTN Mobile Money system. Users can enter an amount to deposit or withdraw, and the balance updates in Firestore.
A note shows: “This is a simulation – no real payment is made.

4.	Scalability & Performance.
I designed the app using clean code and modular widgets for easy updates and adding new features. I use lazy loading to load match and bet data only when needed, saving data and improving speed. The app works well on slow connections by minimizing data transfer and caching data locally.



III.  Monetization Strategy & Sustainability.

1.	Monetization Plan 

•	I use ad placement with Google AdMob to earn revenue. Ads appear on the home and match pages without interrupting users.
•	This choice fits my audience of sports fans who prefer a free app without mandatory payments. Ads allow me to earn while keeping the app easy and accessible.

2.	Analytics & Tracking.

I integrated Firebase Analytics to track user actions like sign-ups, bets placed, and app usage.
This helps me understand which features users like and how often they bet, so I can improve the app and increase revenue.

3. Sustainability Plan.

i. I will collect user feedback through in-app surveys and reviews to improve the app regularly.
ii. I plan to use referral programs to encourage users to invite friends, lowering customer acquisition costs.
iii. To keep users engaged, I use push notifications for match updates and results, plus a loyalty program to reward frequent bettors.




IV.	Security & Reliability.

1.	Security Measures 

•	I use Firebase Authentication for secure user sign-up and login. All user data is stored in Firestore with strict security rules that prevent unauthorized access.

•	I follow local data protection laws by only collecting necessary data and protecting user privacy. API calls are secured with proper permissions to avoid data leaks.

2.	Reliability.

I tested the app on different Android devices and screen sizes using emulators and real phones.
I used Flutter debug tools to fix bugs and ensure smooth performance.
I enabled Firebase Crashlytics to catch and report errors quickly, helping me fix issues before users notice



V.	Submission & Documentation.


1.	APK & AAB.

I submitted both the APK and AAB files in the correct format, ready for testing and Play Store deployment.

2.	Pull Request.

I created a clear pull request with my registration number 22RP02224 and a short summary of my project.


3.	Project Documentation.

i. Student Registration Number
MY Registration Number: 22RP02224

ii. App Name and Description.

App Name: BetNova
Description: A mobile betting app that lets users predict sports match outcomes (football, basketball, volleyball), place bets, and view results all controlled by one admin.

iii. Problem the App Solves.

Many sports fans lack access to local, secure, and easy-to-use betting platforms. BetNova fills this gap by supporting local teams and matches in a mobile-friendly way.

iv. Monetization Strategy

I use Google AdMob ads to generate income without charging users. This is best for my audience who prefer free apps.


v. Key Features Implemented


•	User registration/login
•	Match listing and filtering
•	Bet placement and tracking
•	Admin match and bet control
•	Balance simulation (deposit/withdraw)
•	Push notifications
•	Firebase integration (Auth, Firestore, Analytics)


vi. Instructions to Install APK.

1.	Download the APK file From the Email I have Transferred to you.
2.	Transfer it to your Android phone.
3.	Tap the file and install (enable “Install from Unknown Sources” if needed).
4.	Waiting for Installing Complete.
5.	Open the app and start using.


vii. Scalability, Sustainability, and Security Overview.


The app is built with clean code and scalable Firebase structure.
I use Firebase Analytics for updates and improvement.
Push notifications and loyalty features help keep users engaged.
User data is protected with Firebase security rules and best privacy practices.
___________________________________________________________________________________







HERE THERE IS BRIEF DESCRIPTION OF MY APP ALL FEATURES AND HOW IT WORKS ARE THE FOLLOWING:(MY app is a sports betting platform: Called BetNova).
_______________________________________________________________________________________________________________________


ADMIN FEATURES & WHST THEY DO FOR USERS
_______________________________________



1. Dashboard Analytics

•	For users: Admin can see all user stats, balances, bets, and more, which helps keep the app running smoothly and users’ experience reliable.

2. User Management

•	For users: Admin can view all users, help with account issues, and block/unblock users if needed, ensuring user safety and support.

3. Balance Management

•	For users: Admin can check user balances, assist with deposits/withdrawals, and solve any money-related problems quickly.

4. Bet Management

•	For users: Admin can view and approve bets, resolve disputes, and make sure all betting is fair and transparent.

5. Match/Fixture Management

•	For users: Admin adds or edits matches, teams, and odds, so users always have up-to-date and accurate betting options.

6. Team & League (Champion) Management

•	For users: Admin manages teams and leagues, allowing users to bet on a wide variety of sports and competitions.

7. Country Management

•	For users: Admin adds or updates countries, so users can see teams and matches from different nations.

8. Banner & Ads Management

•	For users: Admin uploads banners and ads, so users get information about promotions, news, or special offers.

9. Notifications Management

•	For users: Admin sends notifications to users about important updates, promotions, or reminders.

10. Subscription & Premium Management

•	For users: Admin tracks premium users, manages subscription plans, and ensures premium users get special benefits (like no ads, higher limits, etc.).

11. Settings & Help Management

•	For users: Admin sets up important app settings and help content, so users can find guidance and support when needed.

12. Sports Types Management

•	For users: Admin adds or expands available sports, giving users more betting choices.

13. Admin Events & Activity Logs

•	For users: Admin can see all actions taken in the app, which helps keep everything transparent and secure for users.

In Summary:

•	All admin features are designed to make the app reliable, safe, and enjoyable for users, ensuring quick support, fair play, and up-to-date betting options.





USER SIDE EXPERINCES (After Admin Setup)
________________________________________


1.	Registration & Login

•	Users create accounts and log in. Their info is managed securely.

2.	Browsing & Betting

•	Users see all matches, teams, and leagues added by the admin.

•	They can place bets on any available match with up-to-date odds.

3.	Balance Management

•	Users deposit and withdraw money.

•	Their balance updates instantly, and the admin can help if there’s a problem.

4.	Notifications

•	Users receive important messages, results, and promotions sent by the admin.

5.	Banners & Ads

•	Users see banners and ads set by the admin.

•	Free users see more ads; premium users see fewer or none.

6.	Premium Subscription

•	Users can upgrade to premium for extra benefits (no ads, higher limits, special features).

•	The admin manages and tracks all premium plans.

7.	Help & Support

•	Users access help content and support, all set by the admin, for easy problem-solving.

8.	Account Management

•	Users can view and edit their profile, see their betting history, and manage their account settings.

9.	Fair Play & Security

•	All user actions are logged and monitored by the admin for transparency and safety.

In summary:The admin sets up everything (matches, teams, odds, ads, notifications, help, etc.), and users enjoy a smooth, safe, and feature-rich betting experience. If users have issues, the admin can help directly.




