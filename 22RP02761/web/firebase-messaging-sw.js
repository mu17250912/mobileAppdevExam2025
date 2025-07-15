importScripts('https://www.gstatic.com/firebasejs/9.6.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDHoMbcF1TVxjylGQXQDM9cOUa5zxGfERY",
        authDomain: "blood-donor-app3.firebaseapp.com",
        projectId: "blood-donor-app3",
        storageBucket: "blood-donor-app3.firebasestorage.app",
        messagingSenderId: "340736307208",
        appId: "1:340736307208:web:c2b8de6a136fb5543161bd",
});

const messaging = firebase.messaging(); 