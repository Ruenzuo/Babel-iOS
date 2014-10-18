//
//  BABAppDelegate.m
//  Babel
//
//  Created by Renzo Crisostomo on 20/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABAppDelegate.h"

@interface BABAppDelegate ()

- (void)configureCocoaLumberjack;
- (void)configureGoogleAnalytics;

@end

@implementation BABAppDelegate

NSString * const BABHockeyAppIdentifier = @"6fd9e830e7744e983eb60925d91d3d93";
NSString * const BABGoogleAnalyticsTrackingId = @"UA-53969387-1";

#pragma mark - Application Life cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self configureCocoaLumberjack];
    [self configureGoogleAnalytics];
    return YES;
}

#pragma mark - Private Methods

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
