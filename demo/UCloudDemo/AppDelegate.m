//
//  AppDelegate.m
//  UCloudDemo
//
//  Created by yisanmao on 15/8/27.
//  Copyright (c) 2015年 yisanmao. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
//    [self configurePre];
//    [self performSelectorOnMainThread:@selector(noti) withObject:self waitUntilDone:YES];
    return YES;
}

#pragma mark - pre 日志分析，并不是.a文件所必需的
//- (void)configurePre
//{
//    PreToolsConfig* config = [PreToolsConfig defaultConfig];
//    config.enabledShakeReport = YES;
//    
//    [PreTools init:@"c73c904b9aaca257019bd4a5798f8d3b" channel:nil config:config];
//}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    /**
     *  这里移动要注意，条件判断成功的是在播放器播放过程中返回的
        下面的是播放器没有弹出来的所支持的设备方向
     */
    if (self.vc)
    {
        return self.vc.playerManager.supportInterOrtation;
    }
    else
    {
        return UIInterfaceOrientationMaskPortrait;
    }
}
@end
