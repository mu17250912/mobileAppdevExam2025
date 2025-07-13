importScripts('https://www.gstatic.com/firebasejs/9.6.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDrazpMzhz5f85YDu0DedjIl0XKi1NaaPQ",
  authDomain: "saferide-65c14.firebaseapp.com",
  projectId: "saferide-65c14",
  messagingSenderId: "1021910036167",
  appId: "1:1021910036167:web:b40e8b1d6fa83fde7498e2"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png' // Update to your app icon path if needed
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});