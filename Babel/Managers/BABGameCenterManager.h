//
//  BABGameCenterManager.h
//  Babel
//
//  Created by Renzo Crisostomo on 12/08/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BABGameCenterManagerDelegate <NSObject>

- (void)showAuthenticateViewController:(UIViewController *)viewController;

@end

extern NSString * const BABGameCenterManagerDidFinishAuthenticationSuccessfullyNotification;

@interface BABGameCenterManager : NSObject

@property (nonatomic, weak) id<BABGameCenterManagerDelegate> delegate;
@property (nonatomic, assign, getter = isGameCenterEnabled) BOOL gameCenterEnabled;

- (void)authenticateLocalPlayer;
- (void)reportScore:(NSUInteger)score
  forDifficultyMode:(BABDifficultyMode)difficultyMode;
- (NSString *)identifierForDifficultyMode:(BABDifficultyMode)difficultyMode;
- (BOOL)score:(NSUInteger)score isHighScoreForDifficulty:(BABDifficultyMode)difficultyMode;

@end
