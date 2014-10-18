//
//  BABConfigurationHelper.m
//  Babel
//
//  Created by Renzo Crisostomo on 03/08/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABConfigurationHelper.h"
#import "BABLanguage.h"

@implementation BABConfigurationHelper

static NSUInteger const BABFixedRandomLanguage = -1;
static NSUInteger const BABMaxHintsEasy = 3;
static NSUInteger const BABMaxHintsNormal = 5;
static NSUInteger const BABMaxHintsHard = 7;

#pragma marl - Public Methods

- (BOOL)shouldFixRandomLanguage
{
    return BABFixedRandomLanguage != -1;
}

- (BABLanguage *)fixedRandomLanguage
{
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:[[NSBundle mainBundle] pathForResource:@"info-hard"
                                                                                                  ofType:@"json"]];
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:nil];
    NSValueTransformer *valueTransformer = [MTLValueTransformer mtl_JSONArrayTransformerWithModelClass:[BABLanguage class]];
    NSArray *languages = [valueTransformer transformedValue:jsonDictionary];
    return languages[BABFixedRandomLanguage];
}

- (NSString *)fileNameForDifficultyMode:(BABDifficultyMode)difficultyMode
{
    switch (difficultyMode) {
        case BABDifficultyModeNone:
            return @"";
        case BABDifficultyModeEasy:
            return @"info-easy";
        case BABDifficultyModeNormal:
            return @"info-normal";
        case BABDifficultyModeHard:
            return @"info-hard";
    }
}

- (NSUInteger)maxHintsForDifficultyMode:(BABDifficultyMode)difficultyMode
{
    switch (difficultyMode) {
        case BABDifficultyModeNone:
            return 0;
        case BABDifficultyModeEasy:
            return BABMaxHintsEasy;
        case BABDifficultyModeNormal:
            return BABMaxHintsNormal;
        case BABDifficultyModeHard:
            return BABMaxHintsHard;
    }
}

@end
