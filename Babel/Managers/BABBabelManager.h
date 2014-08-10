//
//  BABBabelManager.h
//  Babel
//
//  Created by Renzo Crisostomo on 30/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BABConfigurationHelper;

@interface BABBabelManager : NSObject

@property (nonatomic, strong) NSMutableArray *hintLanguages;
@property (nonatomic, strong) NSArray *languages;

- (id)initWithToken:(NSString *)token
  andDifficultyMode:(BABDifficultyMode)difficultyMode;
- (BFTask *)loadNext;
- (void)setupQueue;
- (NSUInteger)maxHintForCurrentDifficulty;

@end
