# Smart Reminders Testing Guide

## 🎯 **Smart Reminders Feature Overview**

Your SmartBudget app now has a comprehensive **Smart Reminders** feature that allows users to:

- ✅ **Create reminders** for bills, subscriptions, and financial obligations
- ✅ **Set due dates and times** with priority levels
- ✅ **Receive notifications** 1 day before and on the due date
- ✅ **Mark reminders as completed** or delete them
- ✅ **View overdue, upcoming, and completed reminders**
- ✅ **Premium feature protection** with unlock logic

## 🚀 **How to Access Smart Reminders**

### **Step 1: Navigate to Smart Reminders**
1. Open the SmartBudget app
2. Go to the **Dashboard** screen
3. Look for the **"Smart Reminders"** tile in the premium features section
4. Tap on it (you'll see a lock icon if premium is not unlocked)

### **Step 2: Unlock Premium (if needed)**
1. If you see a paywall, tap **"Pay & Unlock"**
2. Or use the **Test Payment** feature to unlock premium
3. Once unlocked, you'll have full access to Smart Reminders

## 🧪 **Testing the Reminders Feature**

### **Debug Tools Available**

The Smart Reminders screen has debug tools in the app bar:

1. **🐛 Bug Report Icon** - Opens debug menu with testing options
2. **🔄 Refresh Icon** - Reloads reminders from Firestore
3. **➕ Add Icon** - Opens the add reminder dialog

### **Debug Menu Options**

Tap the bug report icon to access:

#### **1. Create Test Reminder**
- Creates a sample reminder for testing
- Bypasses premium checks
- Sets due date to 7 days from now
- Amount: 5000 FRW

#### **2. Create Test Reminder (Premium Check)**
- Creates a reminder with premium validation
- Will show paywall if premium not unlocked
- Good for testing premium unlock flow

#### **3. Show Debug Info**
- Displays current state information:
  - Total reminders count
  - Upcoming reminders count
  - Overdue reminders count
  - Completed reminders count
  - Premium unlock status
  - Details of first 5 reminders

#### **4. Clear All Reminders**
- Deletes ALL reminders (use with caution)
- Shows confirmation dialog
- Useful for resetting test data

#### **5. Test Notification**
- Shows an immediate test notification
- Verifies notification system is working
- Good for testing notification permissions

## 📱 **Testing Reminder Creation**

### **Manual Reminder Creation**

1. **Tap the + icon** in the app bar
2. **Fill in the form**:
   - **Title**: "Test Bill Payment"
   - **Description**: "Monthly electricity bill"
   - **Amount**: "15000" (FRW)
   - **Category**: Select "Utility"
   - **Priority**: Select "High"
   - **Due Date**: Select a date (tomorrow or later)
   - **Due Time**: Select a time (optional)
   - **Recurring**: Toggle if needed

3. **Tap "Add Reminder"**
4. **Verify**:
   - Reminder appears in the list
   - Notification is scheduled (check console logs)
   - Success message appears

### **Testing Different Scenarios**

#### **Overdue Reminders**
- Create a reminder with yesterday's date
- Should appear in "Overdue" section
- Should have red border and "Overdue by X days" text

#### **Upcoming Reminders**
- Create a reminder with future date
- Should appear in "Upcoming" section
- Should be sorted by due date

#### **Completed Reminders**
- Tap the checkbox on any reminder
- Should move to "Completed" section
- Should have strikethrough text
- Notifications should be cancelled

## 🔔 **Testing Notifications**

### **Immediate Test**
1. Tap the bug report icon
2. Select "Test Notification"
3. Should see a notification immediately
4. Check if notification appears on device

### **Scheduled Notifications**
1. Create a reminder for tomorrow
2. Check console logs for "Scheduled notification" messages
3. Wait for the notification to trigger
4. Verify notification content and timing

### **Notification Content**
- **1 day before**: "Reminder: [Title] - Due tomorrow: [Description]"
- **On due date**: "Due Today: [Title] - Your reminder is due today!"

## 🗄️ **Firestore Data Structure**

### **Reminders Collection**
```json
{
  "userId": "user_uid",
  "title": "Electricity Bill",
  "amount": 15000.0,
  "description": "Monthly electricity bill payment",
  "dueDate": "2024-01-15T00:00:00.000Z",
  "dueTime": "09:00",
  "category": "Utility",
  "priority": "High",
  "isRecurring": false,
  "recurrenceType": "Monthly",
  "isCompleted": false,
  "createdAt": "2024-01-10T10:30:00.000Z"
}
```

### **Verifying Data in Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Firestore Database**
4. Look for the **"reminders"** collection
5. Verify your test reminders are there

## 🔧 **Troubleshooting**

### **Common Issues**

#### **Reminders Not Loading**
- Check console for error messages
- Verify Firebase connection
- Use the refresh button in app bar
- Check debug info for clues

#### **Notifications Not Working**
- Check device notification permissions
- Verify notification service initialization
- Use "Test Notification" to debug
- Check console logs for scheduling errors

#### **Premium Unlock Issues**
- Verify premium features are unlocked
- Check Firestore user document
- Use test payment to unlock
- Check debug info for premium status

#### **Firestore Query Issues**
- Fixed: Removed `orderBy` on server timestamps
- Now sorts in memory after fetching
- Should resolve "Missing or insufficient permissions" errors

### **Debug Console Messages**
Look for these messages in the console:
- `"Loaded X reminders"`
- `"Scheduled notification: [title] for [date]"`
- `"Cancelled notifications for completed reminder: [id]"`
- `"Notification service initialized"`

## 🎯 **Testing Checklist**

### **Basic Functionality**
- [ ] Can access Smart Reminders screen
- [ ] Premium unlock works correctly
- [ ] Can create new reminders
- [ ] Reminders appear in correct sections
- [ ] Can mark reminders as completed
- [ ] Can delete reminders
- [ ] Data persists after app restart

### **Notifications**
- [ ] Test notification works immediately
- [ ] Scheduled notifications are created
- [ ] Notifications appear at correct times
- [ ] Notifications are cancelled when reminder completed
- [ ] Notifications are cancelled when reminder deleted

### **Premium Features**
- [ ] Paywall appears for non-premium users
- [ ] Premium unlock grants access
- [ ] Premium status persists across sessions
- [ ] Premium features work after unlock

### **Data Management**
- [ ] Reminders save to Firestore
- [ ] Reminders load from Firestore
- [ ] Data syncs across devices
- [ ] Debug tools work correctly
- [ ] Clear all reminders works

## 🚀 **Next Steps**

Once testing is complete:

1. **Remove debug tools** for production
2. **Test on real devices** for notifications
3. **Verify premium unlock flow** works end-to-end
4. **Test with real payment methods**
5. **Monitor Firestore usage** and costs

## 📞 **Support**

If you encounter issues:
1. Check the console logs for error messages
2. Use the debug tools to gather information
3. Verify Firebase configuration
4. Test with different scenarios
5. Check notification permissions on device

The Smart Reminders feature is now fully functional with comprehensive testing tools! 