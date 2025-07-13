// Firebase configuration for web
const firebaseConfig = {
  apiKey: "AIzaSyCZlfT-nIag64UUwYDdzrI1pl47oeab3HA",
  authDomain: "safegirl.firebaseapp.com",
  projectId: "safegirl-28a9a",
  storageBucket: "safegirl.appspot.com",
  messagingSenderId: "357204460452",
  appId: "1:357204460452:android:035656e8e9d00d09aa3731",
  
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize Firebase Analytics
const analytics = firebase.analytics();

// Initialize Firebase Auth
const auth = firebase.auth();

// Initialize Firestore
const db = firebase.firestore();

// Initialize Firebase Storage
const storage = firebase.storage();

// Initialize Firebase Messaging
const messaging = firebase.messaging(); 