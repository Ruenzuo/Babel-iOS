//
//  BABDifficultyAlertControllerHelper.h
//  Babel
//
//  Created by Renzo Crisóstomo on 18/10/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BABDifficultyAlertControllerHelperDelegate <NSObject>

- (void)helperDidFinishSelectionWithDifficulty:(BABDifficultyMode)difficulty;

@end

@interface BABDifficultyAlertControllerHelper : NSObject

@property (nonatomic, weak) UIViewController<BABDifficultyAlertControllerHelperDelegate> *delegate;

- (void)presentAlertController;

@end
