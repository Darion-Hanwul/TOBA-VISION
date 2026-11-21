importScripts("https://www.gstatic.com/firebasejs/11.0.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/11.0.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyD_uK-F5-4QfJwg6MdWICRDl2O9nJilBGY",
  authDomain: "toba-vision-47314.firebaseapp.com",
  projectId: "toba-vision-47314",
  storageBucket: "toba-vision-47314.firebasestorage.app",
  messagingSenderId: "1099104128",
  appId: "1:1099104128:web:8d71fd610fcf8ddca0cb65",
  measurementId: "G-LVVMTCNMEK"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = (payload.notification && payload.notification.title)
    ? payload.notification.title
    : "ALARM HUJAN DERAS!";
  const notificationOptions = {
    body: (payload.notification && payload.notification.body)
      ? payload.notification.body
      : "Segera angkat sasak daun tembakau ke gudang!",
    icon: "/icons/Icon-192.png",
    requireInteraction: true
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});