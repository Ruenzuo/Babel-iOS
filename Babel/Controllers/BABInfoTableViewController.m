//
//  BABInfoTableViewController.m
//  Babel
//
//  Created by Renzo Crisostomo on 17/08/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABInfoTableViewController.h"
#import "BABGameCenterManager.h"
#import "BABDifficultyAlertControllerHelper.h"

@interface BABInfoTableViewController () <GKGameCenterControllerDelegate, UIActionSheetDelegate, BABDifficultyAlertControllerHelperDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblVersion;
@property (nonatomic, weak) IBOutlet UILabel *lblGameCenter;
@property (nonatomic, strong) BABDifficultyAlertControllerHelper *difficultyAlertControllerHelper;

- (void)setupVersionLabel;
- (void)setupGameCenterLabel;
- (void)leaderboards;
- (void)developer;
- (void)acknowledgements;
- (void)shareOnFacebook;
- (void)shareOnTwitter;
- (void)rateOnAppStore;
- (void)onGameCenterDidFinishAutenticationSuccessfully:(NSNotification *)notification;

@end

@implementation BABInfoTableViewController

#pragma mark - Properties

- (BABDifficultyAlertControllerHelper *)difficultyAlertControllerHelper
{
    if (_difficultyAlertControllerHelper == nil) {
        _difficultyAlertControllerHelper = [[BABDifficultyAlertControllerHelper alloc] init];
        _difficultyAlertControllerHelper.delegate = self;
    }
    return _difficultyAlertControllerHelper;
}

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
        [self.difficultyAlertControllerHelper presentAlertController];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"gamecenter:"]];
    }
}

- (void)developer
{
    [self performSegueWithIdentifier:@"DeveloperSegue"
                              sender:self];
}

- (void)acknowledgements
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Pods-Babel-acknowledgements"
                                                     ofType:@"plist"];
    VTAcknowledgementsViewController *viewController = [[VTAcknowledgementsViewController alloc] initWithAcknowledgementsPlistPath:path];
    [self.navigationController pushViewController:viewController
                                         animated:YES];
}

- (void)shareOnFacebook
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        SLComposeViewController *facebookStatus = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [facebookStatus setInitialText:@"Check Babel on the AppStore!"];
        [facebookStatus addURL:[[iLink sharedInstance] iLinkGetAppURLforSharing]];
        [self presentViewController:facebookStatus
                           animated:YES
                         completion:nil];
    } else {
        [TSMessage
         showNotificationInViewController:self
         title:@"Error"
         subtitle:@"It seems that you don't have a Facebook account configured."
         type:TSMessageNotificationTypeError
         duration:3.0f
         canBeDismissedByUser:YES];
    }
}

- (void)shareOnTwitter
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore
     requestAccessToAccountsWithType:accountType
     options:nil
     completion:^(BOOL granted, NSError *error) {
         if(granted) {
             NSArray *accounts = [accountStore accountsWithAccountType:accountType];
             if ([accounts count] > 0) {
                 SLComposeViewController *tweetSheet = [SLComposeViewController
                                                        composeViewControllerForServiceType:SLServiceTypeTwitter];
                 [tweetSheet setInitialText:@"Check Babel on the AppStore!"];
                 [tweetSheet addURL:[[iLink sharedInstance] iLinkGetAppURLforSharing]];
                 [self presentViewController:tweetSheet
                                    animated:YES
                                  completion:nil];
             }
             else {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [TSMessage
                      showNotificationInViewController:self
                      title:@"Error"
                      subtitle:@"It seems that you don't have a Twitter account configured."
                      type:TSMessageNotificationTypeError
                      duration:3.0f
                      canBeDismissedByUser:YES];
                 });
             }
         }
     }];
}

- (void)rateOnAppStore
{
    [[iLink sharedInstance] iLinkOpenRatingsPageInAppStore];
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
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    [tableView deselectRowAtIndexPath:indexPath
                                             animated:YES];
                    [self shareOnFacebook];
                    break;
                }
                case 1: {
                    [tableView deselectRowAtIndexPath:indexPath
                                             animated:YES];
                    [self shareOnTwitter];
                    break;
                }
                case 2: {
                    [tableView deselectRowAtIndexPath:indexPath
                                             animated:YES];
                    [self rateOnAppStore];
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
                case 1: {
                    [self acknowledgements];
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

#pragma mark - BABDifficultyAlertControllerHelperDelegate

- (void)helperDidFinishSelectionWithDifficulty:(BABDifficultyMode)difficulty
{
    if (difficulty != BABDifficultyModeNone) {
        GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
        gameCenterController.gameCenterDelegate = self;
        gameCenterController.viewState = GKGameCenterViewControllerStateLeaderboards;
        gameCenterController.leaderboardIdentifier = [self.gameCenterManager identifierForDifficultyMode:difficulty];
        [self presentViewController:gameCenterController
                           animated:YES
                         completion:nil];
    }
}

@end
