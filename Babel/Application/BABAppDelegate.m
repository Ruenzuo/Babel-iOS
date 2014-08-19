//
//  BABAppDelegate.m
//  Babel
//
//  Created by Renzo Crisostomo on 20/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABAppDelegate.h"
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>

@interface BABAppDelegate ()

- (void)configureHockeyApp;
- (void)configureCocoaLumberjack;
- (void)configureGoogleAnalytics;

@end

@implementation BABAppDelegate

NSString * const BABHockeyAppIdentifier = @"6fd9e830e7744e983eb60925d91d3d93";
NSString * const BABGoogleAnalyticsTrackingId = @"UA-53969387-1";

#pragma mark - Application Life cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self configureHockeyApp];
    [self configureCocoaLumberjack];
    [self configureGoogleAnalytics];
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    if( [[BITHockeyManager sharedHockeyManager].authenticator handleOpenURL:url
                                                          sourceApplication:sourceApplication
                                                                 annotation:annotation]) {
        return YES;
    }
    return NO;
}

#pragma mark - Private Methods

- (void)configureHockeyApp
{
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:BABHockeyAppIdentifier];
    if (!APP_STORE) {
        [[[BITHockeyManager sharedHockeyManager] authenticator] setIdentificationType:BITAuthenticatorIdentificationTypeDevice];
    }
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[[BITHockeyManager sharedHockeyManager] authenticator] authenticateInstallation];
}

- (void)configureCocoaLumberjack
{
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
}

- (void)configureGoogleAnalytics
{
    [[GAI sharedInstance] trackerWithTrackingId:BABGoogleAnalyticsTrackingId];
}

@end
