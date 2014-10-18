//
//  BABDifficultyAlertControllerHelper.m
//  Babel
//
//  Created by Renzo Crisóstomo on 18/10/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABDifficultyAlertControllerHelper.h"

@implementation BABDifficultyAlertControllerHelper

- (void)presentAlertController:(id)sender
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:NSLocalizedString(@"difficulty-alert-controller.title", nil)
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction
                                actionWithTitle:NSLocalizedString(@"difficulty-alert-controller.actions.easy-action.title", nil)
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self.delegate helperDidFinishSelectionWithDifficulty:BABDifficultyModeEasy];
                                }]];
    [alertController addAction:[UIAlertAction
                                actionWithTitle:NSLocalizedString(@"difficulty-alert-controller.actions.normal-action.title", nil)
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self.delegate helperDidFinishSelectionWithDifficulty:BABDifficultyModeNormal];
                                }]];
    [alertController addAction:[UIAlertAction
                                actionWithTitle:NSLocalizedString(@"difficulty-alert-controller.actions.hard-action.title", nil)
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    [self.delegate helperDidFinishSelectionWithDifficulty:BABDifficultyModeHard];
                                }]];
    [alertController addAction:[UIAlertAction
                                actionWithTitle:NSLocalizedString(@"difficulty-alert-controller.actions.cancel-action.title", nil)
                                style:UIAlertActionStyleCancel
                                handler:^(UIAlertAction *action) {
                                    [self.delegate helperDidFinishSelectionWithDifficulty:BABDifficultyModeNone];
                                }]];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
        UIView *view = (UIView *)sender;
        popPresenter.sourceView = view;
        popPresenter.sourceRect = view.bounds;
    }
    [self.delegate presentViewController:alertController
                                animated:YES
                              completion:nil];
}

@end
