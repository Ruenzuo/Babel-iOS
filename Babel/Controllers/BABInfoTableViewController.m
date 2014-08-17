//
//  BABInfoTableViewController.m
//  Babel
//
//  Created by Renzo Crisostomo on 17/08/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABInfoTableViewController.h"
#import "BABGameCenterManager.h"
#import "BABDifficultiesActionSheet.h"

@interface BABInfoTableViewController () <GKGameCenterControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblVersion;
@property (nonatomic, weak) IBOutlet UILabel *lblGameCenter;

- (void)setupVersionLabel;
- (void)setupGameCenterLabel;
- (void)leaderboards;
- (void)developer;
- (void)onGameCenterDidFinishAutenticationSuccessfully:(NSNotification *)notification;

@end

@implementation BABInfoTableViewController

#pragma mark - View controller life cycle

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onGameCenterDidFinishAutenticationSuccessfully:)
                                                     name:BABGameCenterManagerDidFinishAuthenticationSuccessfullyNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupVersionLabel];
    [self setupGameCenterLabel];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

- (void)setupVersionLabel
{
    self.lblVersion.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (void)setupGameCenterLabel
{
    if (self.gameCenterManager.isGameCenterEnabled) {
        self.lblGameCenter.text = @"Leaderboards";
    } else {
        self.lblGameCenter.text = @"Enable Game Center";
    }
}

- (void)leaderboards
{
    if (self.gameCenterManager.isGameCenterEnabled) {
        [BABDifficultiesActionSheet showDifficultiesActionSheetInViewController:self];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"gamecenter:"]];
    }
}

- (void)developer
{
    [self performSegueWithIdentifier:@"DeveloperSegue"
                              sender:self];
}

#pragma mark - GKGameCenterControllerDelegate

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    [tableView deselectRowAtIndexPath:indexPath
                                             animated:YES];
                    [self leaderboards];
                    break;
                }
            }
            break;
        }
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    [self developer];
                    break;
                }
            }
            break;
        }
    }
}

#pragma mark - NSNotificationCenter

- (void)onGameCenterDidFinishAutenticationSuccessfully:(NSNotification *)notification
{
    [self setupGameCenterLabel];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        BABDifficultyMode difficultyMode = buttonIndex;
        GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
        gameCenterController.gameCenterDelegate = self;
        gameCenterController.viewState = GKGameCenterViewControllerStateLeaderboards;
        gameCenterController.leaderboardIdentifier = [self.gameCenterManager identifierForDifficultyMode:difficultyMode];
        [self presentViewController:gameCenterController
                           animated:YES
                         completion:nil];
    }
}

@end
