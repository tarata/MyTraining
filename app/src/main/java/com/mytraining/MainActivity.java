package com.mytraining;
import android.app.*; import android.os.*; import android.content.*; import android.webkit.*; import android.view.WindowManager;
public class MainActivity extends Activity {
 public void onCreate(Bundle b){super.onCreate(b);getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);WebView w=new WebView(this);w.getSettings().setJavaScriptEnabled(true);w.getSettings().setDomStorageEnabled(true);w.setWebChromeClient(new WebChromeClient());w.addJavascriptInterface(new Bridge(),"Android");setContentView(w);w.loadUrl("file:///android_asset/index.html");}
 class Bridge {
 @JavascriptInterface public void scheduleRest(long end,String name){AlarmManager a=(AlarmManager)getSystemService(ALARM_SERVICE);PendingIntent p=alarm(name);a.cancel(p);try{if(Build.VERSION.SDK_INT<31||a.canScheduleExactAlarms())a.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,end,p);else a.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,end,p);}catch(SecurityException e){a.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,end,p);}}
 @JavascriptInterface public void cancelRest(){((AlarmManager)getSystemService(ALARM_SERVICE)).cancel(alarm(""));}
 }
 PendingIntent alarm(String name){return PendingIntent.getBroadcast(this,1,new Intent(this,RestReceiver.class).putExtra("name",name),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);}
}