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

#import "CTAppController+APNAdditions.h"
#import <objc/runtime.h>
#import "AirPushNotification.h"

@implementation CTAppController (APNAdditions)

+ (void)load {
    if([UNUserNotificationCenter class] != nil) {
        return;
    }
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
    
        [self swizzleMethodWithOriginalSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)
                               swizzledSelector:@selector(APN_application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        
        [self swizzleMethodWithOriginalSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)
                               swizzledSelector:@selector(APN_application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)];
    });
}

+ (void)swizzleMethodWithOriginalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector {

    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    }
    else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)APN_application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {

    // track only when app is in background
    if (application.applicationState == UIApplicationStateBackground)
        [self performTracking:userInfo withCompletionHander:completionHandler];
    else
        completionHandler(UIBackgroundFetchResultNoData);

    [[AirPushNotification instance] trackRemoteNofiticationFromApp:application andUserInfo:userInfo];
}

- (void)APN_application:(UIApplication*)application handleActionWithIdentifier:(NSString *)identifier
            forRemoteNotification:(NSDictionary*)userInfo completionHandler:(void (^)(void))completionHandler {
    
    // track only when app is in background
    if (application.applicationState != UIApplicationStateBackground)
        completionHandler();
    else {
        
        [self performTracking:userInfo withCompletionHander:^(UIBackgroundFetchResult result) {
            completionHandler();
        }];
    }
    
    [[AirPushNotification instance] trackRemoteNofiticationFromApp:application andUserInfo:userInfo];
}

- (void) performTracking:(NSDictionary *)userInfo withCompletionHander:(void (^)(UIBackgroundFetchResult result))completionHandler {

    NSString* notifTrackingURL = [[NSUserDefaults standardUserDefaults] stringForKey:storedNotifTrackingUrl];
    
    if (!notifTrackingURL)
        completionHandler(UIBackgroundFetchResultNewData);
    else {

        NSString* link = nil;
        
        if ([userInfo objectForKey:@"type"] != NULL)
            link = [@"/?source_type=notif&source_ref=" stringByAppendingString:[userInfo objectForKey:@"type"]];
        else {
            
            completionHandler(UIBackgroundFetchResultNewData);
            return;
        }

        if ([userInfo objectForKey:@"sender"] != NULL)
            link = [[link stringByAppendingString:@"&source_userId="] stringByAppendingString:[userInfo objectForKey:@"sender"]];

        // we url-encode the link (with special cases for '&' and '=')
        link = [link stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        link = [link stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
        link = [link stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];

        link = [@"&link=" stringByAppendingString:link];

        notifTrackingURL = [notifTrackingURL stringByAppendingString:link];

        NSURL* url = [[NSURL alloc] initWithString:notifTrackingURL];
        
        if (!url)
            completionHandler(UIBackgroundFetchResultNewData);
        else {
            
            NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                     completionHandler:^(NSData *data, NSURLResponse *response,NSError *error) {
                completionHandler(UIBackgroundFetchResultNewData);
                
            }];
        
            [task resume];
        }
    }
}


@end
