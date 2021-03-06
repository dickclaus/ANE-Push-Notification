/**
 * Copyright 2017 FreshPlanet
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.freshplanet.ane.AirPushNotification;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREInvalidObjectException;
import com.adobe.fre.FREObject;
import com.adobe.fre.FRETypeMismatchException;
import com.adobe.fre.FREWrongThreadException;

public class GoToNotifSettingsFunction implements FREFunction
{
    @Override
    public FREObject call(FREContext freContext, FREObject[] freObjects) {

        String channelId = null;
        if (freObjects.length > 0) {
            try {
                channelId = freObjects[0].getAsString();
                if(channelId.equals("")) {
                    channelId = null;
                }

            } catch (IllegalStateException e) {
                e.printStackTrace();
            } catch (FRETypeMismatchException e) {
                e.printStackTrace();
            } catch (FREInvalidObjectException e) {
                e.printStackTrace();
            } catch (FREWrongThreadException e) {
                e.printStackTrace();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        Context appContext = freContext.getActivity().getApplicationContext();
        Intent intent = new Intent();
        if(android.os.Build.VERSION.SDK_INT > Build.VERSION_CODES.N_MR1){
            if(channelId != null) {
                intent.setAction(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS);
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, appContext.getPackageName());
                intent.putExtra(Settings.EXTRA_CHANNEL_ID, channelId);
            }
            else {
                intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, appContext.getPackageName());
            }
        }else if(android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP){
            intent.setAction("android.settings.APP_NOTIFICATION_SETTINGS");
            intent.putExtra("app_package", appContext.getPackageName());
            intent.putExtra("app_uid", appContext.getApplicationInfo().uid);
        }else {
            intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            intent.addCategory(Intent.CATEGORY_DEFAULT);
            intent.setData(Uri.parse("package:" + appContext.getPackageName()));
        }

        appContext.startActivity(intent);

        return null;
    }
}
