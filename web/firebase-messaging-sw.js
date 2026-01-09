importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDIDyuVXQfhzXi82zD7mS1VYoW_4cR4DeE',
  authDomain: 'aqlan-spices.firebaseapp.com',
  projectId: 'aqlan-spices',
  storageBucket: 'aqlan-spices.firebasestorage.app',
  messagingSenderId: '348781799507',
  appId: '1:348781799507:web:8c3cb2b337510de46efea6',
  measurementId: 'G-5W1PM5YBW4',
});

const messaging = firebase.messaging();
