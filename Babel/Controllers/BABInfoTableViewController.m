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

@property (nonatomic, strong) BABDifficultyAlertControllerHelper *difficultyAlertControllerHelper;

- (void)setupInfoTableViewCell:(UITableViewCell *)tableViewCell
                  forIndexPath:(NSIndexPath *)indexPath;
- (void)leaderboards;
- (void)developer;
- (void)acknowledgements;
- (void)shareOnFacebook;
- (void)shareOnTwitter;
- (void)rateOnAppStore;
- (void)onGameCenterDidFinishAutenticationSuccessfully:(NSNotification *)notification;

@end

@implementation BABInfoTableViewController

static NSString * const BABGameCenterTableViewHeaderFooterViewText = @"Game Center";
static NSString * const BABInfoTableViewCell = @"BABInfoTableViewCell";
static NSString * const BABVersionTableViewCell = @"BABVersionTableViewCell";

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
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

- (void)setupInfoTableViewCell:(UITableViewCell *)tableViewCell
                  forIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0:
                    if (self.gameCenterManager.isGameCenterEnabled) {
                        tableViewCell.textLabel.text = NSLocalizedString(@"info-view-controller.leaderboards.table-view-cell.text-lable.text", nil);
                    } else {
                        tableViewCell.textLabel.text = NSLocalizedString(@"info-view-controller.enable-game-center.table-view-cell.text-lable.text", nil);
                    }
                    break;
            }
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    tableViewCell.textLabel.text = [NSString localizedStringWithFormat:NSLocalizedString(@"info-view-controller.share-service.table-view-cell.text-lable.text", nil), BABFacebookSevice];
                    break;
                }
                case 1: {
                    tableViewCell.textLabel.text = [NSString localizedStringWithFormat:NSLocalizedString(@"info-view-controller.share-service.table-view-cell.text-lable.text", nil), BABTwitterSevice];
                    break;
                }
                case 2: {
                    tableViewCell.textLabel.text = NSLocalizedString(@"info-view-controller.rate-app-store.table-view-cell.text-lable.text", nil);
                    break;
                }
            }
            break;
        }
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    tableViewCell.textLabel.text = NSLocalizedString(@"info-view-controller.developer.table-view-cell.text-lable.text", nil);
                    break;
                }
                case 1: {
                    tableViewCell.textLabel.text = NSLocalizedString(@"info-view-controller.acknowledgments.table-view-cell.text-lable.text", nil);
                    break;
                }
            }
        }
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
        [facebookStatus setInitialText:NSLocalizedString(@"info-view-controller.share-text.compose-view-controller.initial-text", nil)];
        [facebookStatus addURL:[[iLink sharedInstance] iLinkGetAppURLforSharing]];
        [self presentViewController:facebookStatus
                           animated:YES
                         completion:nil];
    } else {
        [TSMessage
         showNotificationInViewController:self
         title:NSLocalizedString(@"everywhere.error.title", nil)
         subtitle:[NSString localizedStringWithFormat:NSLocalizedString(@"everywhere.error.message.subtitle.when-service-share-fails", nil), BABFacebookSevice]
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
                 [tweetSheet setInitialText:NSLocalizedString(@"info-view-controller.share-text.compose-view-controller.initial-text", nil)];
                 [tweetSheet addURL:[[iLink sharedInstance] iLinkGetAppURLforSharing]];
                 [self presentViewController:tweetSheet
                                    animated:YES
                                  completion:nil];
             }
             else {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [TSMessage
                      showNotificationInViewController:self
                      title:NSLocalizedString(@"everywhere.error.title", nil)
                      subtitle:[NSString localizedStringWithFormat:NSLocalizedString(@"everywhere.error.message.subtitle.when-service-share-fails", nil), BABTwitterSevice]
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return BABGameCenterTableViewHeaderFooterViewText;
        case 1:
            return NSLocalizedString(@"info-view-controller.social.table-view-header-footer-view.text-lable.text", nil);
        case 2:
            return NSLocalizedString(@"info-view-controller.about.table-view-header-footer-view.text-lable.text", nil);
        default:
            return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 3;
        case 2:
            return 3;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tableViewCell;
    if (indexPath.section == 2 && indexPath.row == 2) {
        tableViewCell = [tableView dequeueReusableCellWithIdentifier:BABVersionTableViewCell
                                                        forIndexPath:indexPath];
        tableViewCell.textLabel.text = NSLocalizedString(@"info-view-controller.version.table-view-cell.text-lable.text", nil);
        tableViewCell.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    } else {
        tableViewCell = [tableView dequeueReusableCellWithIdentifier:BABInfoTableViewCell
                                                        forIndexPath:indexPath];
        [self setupInfoTableViewCell:tableViewCell
                        forIndexPath:indexPath];
    }
    return tableViewCell;
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
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0
                                                                inSection:0]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
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
