package com.amplitude.amplitude_flutter;

import android.Manifest;
import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.LocaleList;
import android.provider.Settings;
import android.telephony.TelephonyManager;
import android.util.Log;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * AmplitudeFlutterPlugin
 */
public class AmplitudeFlutterPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {
    private static final String TAG = AmplitudeFlutterPlugin.class.getSimpleName();

    String carrierName;

    private MethodChannel mMethodChannel;
    private Activity mActivity;
    private TelephonyManager mTelephonyManager;
    private Result mCarrierResult;
    private static int READ_PHONE_STATE = 123;

    public AmplitudeFlutterPlugin() {
        Log.e(TAG, "AmplitudeFlutterPlugin: Initializing");
    }

    private AmplitudeFlutterPlugin(Activity activity) {
        this.mActivity = activity;
        mTelephonyManager = (TelephonyManager) activity.getSystemService(Context.TELEPHONY_SERVICE);
    }

    /**
     * Plugin registration. This's for Flutter SDK pre 1.12 support.
     */
    public static void registerWith(Registrar registrar) {
        final AmplitudeFlutterPlugin amplitudeFlutterPlugin = new AmplitudeFlutterPlugin(registrar.activity());
        amplitudeFlutterPlugin.setupChannel(registrar.messenger());

        /** Adds a callback allowing the plugin to take part in handling incoming calls
         * to Activity#onRequestPermissionsResult(int, String[], int[])
         **/
        registrar.addRequestPermissionsResultListener(new PluginRegistry.RequestPermissionsResultListener() {
            @Override
            public boolean onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
                if (requestCode == READ_PHONE_STATE) {
                    boolean permissionGranted = grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED;
                    amplitudeFlutterPlugin.processCarrierResult(permissionGranted);
                    return true;
                } else {
                    // We don't care other permissions other than READ_PHONE_STATE
                    return false;
                }
            }
        });
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        setupChannel(binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        teardownChannel();
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        mActivity = binding.getActivity();
        mTelephonyManager = (TelephonyManager) mActivity.getSystemService(Context.TELEPHONY_SERVICE);

        /** Adds a callback allowing the plugin to take part in handling incoming calls
         * to Activity#onRequestPermissionsResult(int, String[], int[])
         **/
        binding.addRequestPermissionsResultListener(new PluginRegistry.RequestPermissionsResultListener() {
            @Override
            public boolean onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
                if (requestCode == READ_PHONE_STATE) {
                    boolean permissionGranted = grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED;
                    processCarrierResult(permissionGranted);
                    return true;
                } else {
                    // We don't care other permissions other than READ_PHONE_STATE
                    return false;
                }
            }
        });
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }

    @Override
    public void onMethodCall(MethodCall call, final Result result) {
        switch (call.method) {
            case "carrierName": {
                mCarrierResult = result;
                if (Build.VERSION.SDK_INT >= 23) {
                    getCarrierInfoWithPermissions(mCarrierResult);
                } else {
                    processCarrierResult(true);
                }
            }
            break;
            case "preferredLanguages":
                result.success(getPreferredLanguages());
                break;
            case "currentLocale":
                result.success(getCurrentLocale());
                break;
            case "advertisingId":
                result.success(null);
                break;
            default:
                result.notImplemented();
        }
    }

    private void setupChannel(BinaryMessenger messenger) {
        mMethodChannel = new MethodChannel(messenger, "amplitude_flutter");
        mMethodChannel.setMethodCallHandler(this);
    }

    private void teardownChannel() {
        mMethodChannel.setMethodCallHandler(null);
        mMethodChannel = null;
    }

    private void getCarrierInfoWithPermissions(Result result) {
        boolean permissionGranted;
        permissionGranted = checkAlreadyExistingPermission();
        if (permissionGranted) {
            carrierName = getCarrierName();
            result.success(carrierName);
            mCarrierResult = null;
        } else {
            ActivityCompat.requestPermissions(this.mActivity, new String[]{Manifest.permission.READ_PHONE_STATE},
                    READ_PHONE_STATE);
        }
    }

    private boolean checkAlreadyExistingPermission() {
        int result = ContextCompat.checkSelfPermission(this.mActivity, Manifest.permission.READ_PHONE_STATE);
        if (result == PackageManager.PERMISSION_GRANTED) {
            return true;
        } else {
            return false;
        }
    }

    private void processCarrierResult(boolean permission) {
        // We only proceed only when permission is triggered when `device` method is called.
        // That means mCarrierResult is not null.
        if (mCarrierResult == null) {
            return;
        }

        if (permission) {
            String name = getCarrierName();
            mCarrierResult.success(name);
        } else {
            mCarrierResult.error("PERMISSION_DENIED", "PERMISSION_DENIED", null);
        }
        mCarrierResult = null;
    }

    private String getCarrierName() {
        String networkOperatorName = mTelephonyManager.getNetworkOperatorName();
        if (networkOperatorName == null) {
            networkOperatorName = "null";
        }
        return networkOperatorName;
    }

    private String getCurrentLocale() {
        return Locale.getDefault().toString();
    }

    private List<String> getPreferredLanguages() {
        List<String> result = new ArrayList<String>();

        if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            LocaleList list = LocaleList.getAdjustedDefault();
            for (int i = 0; i < list.size(); i++) {
                result.add(list.get(i).toString());
            }
        } else {
            result.add(getCurrentLocale());
        }

        return result;
    }

    private String getAdvertisingId() {
        // This should not be called on the main thread.
        if ("Amazon".equals(Build.MANUFACTURER)) {
            return getAmazonAdvertisingId();
        } else {
            return getGoogleAdvertisingId();
        }
    }

    private String getAmazonAdvertisingId() {
        ContentResolver cr = this.mActivity.getContentResolver();
        boolean enableAdsTracking = Settings.Secure.getInt(cr, "limit_ad_tracking", 0) == 1;
        return enableAdsTracking ? Settings.Secure.getString(cr, "advertising_id") : null;
    }

    private String getGoogleAdvertisingId() {
        String advertisingId = null;
        try {
            Class AdvertisingIdClient = Class
                    .forName("com.google.android.gms.ads.identifier.AdvertisingIdClient");
            Method getAdvertisingInfo = AdvertisingIdClient.getMethod("getAdvertisingIdInfo",
                    Context.class);
            Object advertisingInfo = getAdvertisingInfo.invoke(null, mActivity);

            Method isLimitAdTrackingEnabled = advertisingInfo.getClass().getMethod(
                    "isLimitAdTrackingEnabled");
            Boolean limitAdTrackingEnabled = (Boolean) isLimitAdTrackingEnabled
                    .invoke(advertisingInfo);

            if (limitAdTrackingEnabled != null && !limitAdTrackingEnabled) {
                Method getId = advertisingInfo.getClass().getMethod("getId");
                advertisingId = (String) getId.invoke(advertisingInfo);
            } else {
                return null;
            }
        } catch (ClassNotFoundException e) {
            Log.w(TAG, "Google Play Services SDK not found!");
        } catch (InvocationTargetException e) {
            Log.w(TAG, "Google Play Services not available");
        } catch (Exception e) {
            Log.e(TAG, "Encountered an error connecting to Google Play Services", e);
        }

        return advertisingId;
    }
}
