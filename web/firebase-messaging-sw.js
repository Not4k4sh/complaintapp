importScripts("https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAavQkV3PxI7Ixpfe3qCfu5XhxRbMdXdgg",
  authDomain: "hello-b441f.firebaseapp.com",
  projectId: "hello-b441f",
  storageBucket: "hello-b441f.firebasestorage.app",
  messagingSenderId: "613550733005",
  appId: "1:613550733005:web:825e3722f03da6d8d7db84"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/firebase-logo.png'  // Optional: Change to your app's icon
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
