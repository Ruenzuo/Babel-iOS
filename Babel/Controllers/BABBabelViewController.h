//
//  BABBabelViewController.h
//  Babel
//
//  Created by Renzo Crisostomo on 23/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BABBabelManager;
@class BABGameCenterManager;

@protocol BABBabelViewControllerDelegate <NSObject>

- (void)controllerDidFinishWithScore:(NSUInteger)score
                   forDifficultyMode:(BABDifficultyMode)difficultyMode
                            withInfo:(NSString *)info;

@end

@interface BABBabelViewController : GAITrackedViewController

@property (nonatomic, strong) BABBabelManager *babelManager;
@property (nonatomic, strong) BABGameCenterManager *gameCenterManager;
@property (nonatomic, weak) id<BABBabelViewControllerDelegate> delegate;

@end
