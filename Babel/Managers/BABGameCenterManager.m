//
//  BABGameCenterManager.m
//  Babel
//
//  Created by Renzo Crisostomo on 12/08/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABGameCenterManager.h"

@interface BABGameCenterManager ()

@property (nonatomic, assign, getter = isGameCenterEnabled) BOOL gameCenterEnabled;

- (NSString *)identifierForDifficultyMode:(BABDifficultyMode)difficultyMode;

@end

@implementation BABGameCenterManager

NSString * const BABEasyLeaderboardIdentifier = @"BAB_001_EASY_LEADERBOARD";
NSString * const BABNormalLeaderboardIdentifier = @"BAB_001_NORMAL_LEADERBOARD";
NSString * const BABHardLeaderboardIdentifier = @"BAB_001_HARD_LEADERBOARD";

#pragma mark - Private Method

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
            NSLog(@"%@", [error localizedDescription]);
        } else if (viewController) {
            [self.delegate showAuthenticateViewController:viewController];
        } else {
            self.gameCenterEnabled = YES;
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
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
}

@end
