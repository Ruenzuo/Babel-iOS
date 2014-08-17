//
//  BABDifficultiesActionSheet.m
//  Babel
//
//  Created by Renzo Crisostomo on 17/08/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABDifficultiesActionSheet.h"

@implementation BABDifficultiesActionSheet

+ (void)showDifficultiesActionSheetInViewController:(UIViewController<UIActionSheetDelegate> *)controller
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Difficulty"
                                                             delegate:controller
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Easy", @"Normal", @"Hard", nil];
    [actionSheet showInView:controller.view];
}

@end
