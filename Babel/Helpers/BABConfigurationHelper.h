//
//  BABConfigurationHelper.h
//  Babel
//
//  Created by Renzo Crisostomo on 03/08/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BABLanguage;

@interface BABConfigurationHelper : NSObject

- (BOOL)shouldFixRandomLanguage;
- (BABLanguage *)fixedRandomLanguage;
- (NSString *)fileNameForDifficultyMode:(BABDifficultyMode)difficultyMode;
- (NSUInteger)maxHintsForDifficultyMode:(BABDifficultyMode)difficultyMode;

@end
