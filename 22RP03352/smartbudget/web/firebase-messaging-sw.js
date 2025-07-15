// Firebase Messaging Service Worker
// This file is required for Firebase Cloud Messaging to work on web

importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Firebase configuration
// This should match your firebase_options.dart configuration
firebase.initializeApp({
  apiKey: "AIzaSyAuzeeWlcgoxKwKXmRuzfA9QU8eHdEXEfw",
  authDomain: "budgetwise-98ee2.firebaseapp.com",
  projectId: "budgetwise-98ee2",
  storageBucket: "budgetwise-98ee2.firebasestorage.app",
  messagingSenderId: "320050492235",
  appId: "1:320050492235:web:1715a6e0587a441fb0eece",
  measurementId: "G-HG033CX2PR"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'New Message';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
}); 