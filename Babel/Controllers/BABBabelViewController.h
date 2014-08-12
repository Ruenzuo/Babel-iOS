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

@interface BABBabelViewController : UIViewController

@property (nonatomic, strong) BABBabelManager *babelManager;
@property (nonatomic, strong) BABGameCenterManager *gameCenterManager;

@end
