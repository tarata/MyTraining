package com.mytraining;

import android.Manifest;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

public class PushService extends FirebaseMessagingService {
    private static final String CHANNEL = "ruoss_messages";

    static void createChannel(Context context) {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationManager manager = context.getSystemService(NotificationManager.class);
            manager.createNotificationChannel(new NotificationChannel(
                    CHANNEL, "Messaggi RUOSS", NotificationManager.IMPORTANCE_DEFAULT));
        }
    }

    @Override
    public void onMessageReceived(RemoteMessage message) {
        RemoteMessage.Notification payload = message.getNotification();
        if (payload == null || (Build.VERSION.SDK_INT >= 33 &&
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)) {
            return;
        }
        createChannel(this);
        Notification.Builder builder = Build.VERSION.SDK_INT >= 26
                ? new Notification.Builder(this, CHANNEL) : new Notification.Builder(this);
        Intent open = new Intent(this, MainActivity.class)
                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent tap = PendingIntent.getActivity(this, 0, open,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        Notification notification = builder.setSmallIcon(R.drawable.ic_training)
                .setContentTitle(payload.getTitle() == null ? "RUOSS" : payload.getTitle())
                .setContentText(payload.getBody())
                .setStyle(new Notification.BigTextStyle().bigText(payload.getBody()))
                .setAutoCancel(true).setContentIntent(tap).build();
        String tag = message.getMessageId();
        getSystemService(NotificationManager.class).notify(tag, 1, notification);
    }
}
