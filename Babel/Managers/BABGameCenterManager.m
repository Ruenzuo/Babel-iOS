//
//  BABGameCenterManager.m
//  Babel
//
//  Created by Renzo Crisostomo on 12/08/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABGameCenterManager.h"

@interface BABGameCenterManager ()

@end

NSString * const BABGameCenterManagerDidFinishAuthenticationSuccessfullyNotification = @"BABGameCenterManagerDidFinishAuthenticationSuccessfullyNotification";

@implementation BABGameCenterManager

static NSString * const BABEasyLeaderboardIdentifier = @"BAB_001_EASY_LEADERBOARD";
static NSString * const BABNormalLeaderboardIdentifier = @"BAB_001_NORMAL_LEADERBOARD";
static NSString * const BABHardLeaderboardIdentifier = @"BAB_001_HARD_LEADERBOARD";

#pragma mark - Public Methods

- (id)init
{
    self = [super init];
    if (self) {
        self.gameCenterEnabled = NO;
    }
    return self;
}

- (void)authenticateLocalPlayer
{
    @weakify(self);
    
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    [localPlayer setAuthenticateHandler:^(UIViewController *viewController, NSError *error) {
        
        @strongify(self);
        
        if (error) {
            DDLogError(@"%@", [error localizedDescription]);
        } else if (viewController) {
            [self.delegate showAuthenticateViewController:viewController];
        } else {
            self.gameCenterEnabled = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:BABGameCenterManagerDidFinishAuthenticationSuccessfullyNotification
                                                                object:nil];
        }
    }];
}

- (void)reportPoints:(NSUInteger)points
   forDifficultyMode:(BABDifficultyMode)difficultyMode
{
    if (!self.gameCenterEnabled) {
        return;
    }
    GKScore *score = [[GKScore alloc] initWithLeaderboardIdentifier:[self identifierForDifficultyMode:difficultyMode]];
    score.value = points;
    [GKScore reportScores:@[score]
    withCompletionHandler:^(NSError *error) {
        if (error) {
            DDLogError(@"%@", [error localizedDescription]);
        }
    }];
}

- (NSString *)identifierForDifficultyMode:(BABDifficultyMode)difficultyMode
{
    switch (difficultyMode) {
        case BABDifficultyModeEasy:
            return BABEasyLeaderboardIdentifier;
        case BABDifficultyModeNormal:
            return BABNormalLeaderboardIdentifier;
        case BABDifficultyModeHard:
            return BABHardLeaderboardIdentifier;
        case BABDifficultyModeNone:
            return @"";
    }
}

@end
