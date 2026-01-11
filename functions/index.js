const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.notifyAdminOnNewCustomer = functions.firestore
  .document('customers/{custId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const title = "مستخدم جديد";
    const body = `انضم: ${data?.name || 'مستخدم جديد'}`;

    // جلب جميع توكنات الادمن
    const tokensSnap = await admin.firestore().collection('admin_tokens').get();
    const tokens = tokensSnap.docs.map(d => d.id); // أنا خزّنت docId == token في المثال السابق

    if (!tokens.length) return null;

    const message = {
      notification: { title, body },
      tokens: tokens,
      data: { type: 'new_customer', id: snap.id }
    };

    return admin.messaging().sendMulticast(message);
  });

exports.notifyAdminOnNewOrder = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const title = "طلب جديد";
    const body = `طلب #${snap.id} — المجموع: ${data?.total || '-'}`;

    const tokensSnap = await admin.firestore().collection('admin_tokens').get();
    const tokens = tokensSnap.docs.map(d => d.id);

    if (!tokens.length) return null;

    const message = {
      notification: { title, body },
      tokens: tokens,
      data: { type: 'new_order', id: snap.id }
    };

    return admin.messaging().sendMulticast(message);
  });