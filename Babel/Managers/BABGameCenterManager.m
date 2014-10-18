//
//  BABGameCenterManager.m
//  Babel
//
//  Created by Renzo Crisostomo on 12/08/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABGameCenterManager.h"

@interface BABGameCenterManager ()

@property (nonatomic, assign) int easyHighScore;
@property (nonatomic, assign) int normalHighScore;
@property (nonatomic, assign) int hardHighScore;

- (void)loadHighScores;

@end

NSString * const BABGameCenterManagerDidFinishAuthenticationSuccessfullyNotification = @"BABGameCenterManagerDidFinishAuthenticationSuccessfullyNotification";

@implementation BABGameCenterManager

static NSString * const BABEasyLeaderboardIdentifier = @"BAB_001_EASY_LEADERBOARD";
static NSString * const BABNormalLeaderboardIdentifier = @"BAB_001_NORMAL_LEADERBOARD";
static NSString * const BABHardLeaderboardIdentifier = @"BAB_001_HARD_LEADERBOARD";

#pragma mark - Private Methods

- (void)loadHighScores
{
    GKLeaderboard *easyLeaderboard = [[GKLeaderboard alloc] init];
    easyLeaderboard.identifier = BABEasyLeaderboardIdentifier;
    [easyLeaderboard loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
        if (error) {
            DDLogError(@"%@", [error localizedDescription]);
        } else {
            GKScore *localPlayerScore = easyLeaderboard.localPlayerScore;
            self.easyHighScore = (int) localPlayerScore.value;
            DDLogInfo(@"Current easy high score: %d", self.easyHighScore);
        }
    }];
    GKLeaderboard *normalLeaderboard = [[GKLeaderboard alloc] init];
    normalLeaderboard.identifier = BABNormalLeaderboardIdentifier;
    [normalLeaderboard loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
        if (error) {
            DDLogError(@"%@", [error localizedDescription]);
        } else {
            GKScore *localPlayerScore = normalLeaderboard.localPlayerScore;
            self.normalHighScore = (int) localPlayerScore.value;
            DDLogInfo(@"Current normal high score: %d", self.normalHighScore);
        }
    }];
    GKLeaderboard *hardLeaderboard = [[GKLeaderboard alloc] init];
    hardLeaderboard.identifier = BABHardLeaderboardIdentifier;
    [hardLeaderboard loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
        if (error) {
            DDLogError(@"%@", [error localizedDescription]);
        } else {
            GKScore *localPlayerScore = hardLeaderboard.localPlayerScore;
            self.hardHighScore = (int) localPlayerScore.value;
            DDLogInfo(@"Current hard high score: %d", self.hardHighScore);
        }
    }];
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
            DDLogError(@"%@", [error localizedDescription]);
        } else if (viewController) {
            [self.delegate showAuthenticateViewController:viewController];
        } else {
            self.gameCenterEnabled = YES;
            [self loadHighScores];
            [[NSNotificationCenter defaultCenter] postNotificationName:BABGameCenterManagerDidFinishAuthenticationSuccessfullyNotification
                                                                object:nil];
        }
    }];
}

- (void)reportScore:(NSUInteger)score
  forDifficultyMode:(BABDifficultyMode)difficultyMode
{
    if (!self.gameCenterEnabled) {
        return;
    }
    GKScore *gameScore = [[GKScore alloc] initWithLeaderboardIdentifier:[self identifierForDifficultyMode:difficultyMode]];
    gameScore.value = score;
    [GKScore reportScores:@[gameScore]
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

- (BOOL)score:(NSUInteger)score isHighScoreForDifficulty:(BABDifficultyMode)difficultyMode
{
    if (!self.isGameCenterEnabled) {
        return NO;
    }
    switch (difficultyMode) {
        case BABDifficultyModeEasy:
            return score > self.easyHighScore;
        case BABDifficultyModeNormal:
            return score > self.normalHighScore;
        case BABDifficultyModeHard:
            return score > self.hardHighScore;
        case BABDifficultyModeNone:
            return NO;
    }
}

@end
