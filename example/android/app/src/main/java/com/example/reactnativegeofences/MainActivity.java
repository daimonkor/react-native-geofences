package com.example.reactnativegeofences;

import com.facebook.react.ReactActivity;

import android.content.Intent;
import android.content.IntentFilter;


public class MainActivity extends ReactActivity {
  private final ShutDownReceiver mReceiver = new ShutDownReceiver();

  /**
   * Returns the name of the main component registered from JavaScript. This is used to schedule
   * rendering of the component.
   */
  @Override
  protected String getMainComponentName() {
    return "GeofencesExample";
  }

  @Override
  public void onResume() {
    super.onResume();
    IntentFilter filter = new IntentFilter(Intent.ACTION_SHUTDOWN);
    registerReceiver(mReceiver, filter);
  }

  @Override
  public void onPause() {
    super.onPause();
    unregisterReceiver(mReceiver);
  }
}
