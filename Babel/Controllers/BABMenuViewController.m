//
//  BABMenuViewController.m
//  Babel
//
//  Created by Renzo Crisostomo on 20/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABMenuViewController.h"
#import "BABOAuthViewController.h"
#import "BABBabelViewController.h"
#import "BABKeychainHelper.h"
#import "BABAuthorizationSessionHelper.h"
#import "BABBabelManager.h"
#import "BABGameCenterManager.h"
#import "BABInfoTableViewController.h"
#import "BABDifficultyAlertControllerHelper.h"

@interface BABMenuViewController () <BABOAuthViewControllerDelegate, UIActionSheetDelegate, BABGameCenterManagerDelegate, BABDifficultyAlertControllerHelperDelegate, BABBabelViewControllerDelegate>

@property (nonatomic, strong) NSString *token;
@property (nonatomic, weak) IBOutlet UIButton *btnStart;
@property (nonatomic, weak) IBOutlet UIImageView *imageViewIcon;
@property (nonatomic, strong) BABAuthorizationSessionHelper *authorizationSessionHelper;
@property (nonatomic, assign) BABDifficultyMode selectedDifficultyMode;
@property (nonatomic, strong) BABGameCenterManager *gameCenterManager;
@property (nonatomic, strong) BABDifficultyAlertControllerHelper *difficultyAlertControllerHelper;
@property (nonatomic, strong) BABNotificationManager *notificationManager;

- (void)checkTokenValidity;
- (IBAction)logIn:(id)sender;
- (IBAction)start:(id)sender;
- (IBAction)info:(id)sender;
- (void)logOut:(id)sender;
- (void)showLogInView;
- (void)showLogOutView;

@end

@implementation BABMenuViewController

#pragma mark - Properties

- (BABAuthorizationSessionHelper *)authorizationSessionHelper
{
    if (_authorizationSessionHelper == nil) {
        _authorizationSessionHelper = [[BABAuthorizationSessionHelper alloc] init];
    }
    return _authorizationSessionHelper;
}

- (BABGameCenterManager *)gameCenterManager
{
    if (_gameCenterManager == nil) {
        _gameCenterManager = [[BABGameCenterManager alloc] init];
        _gameCenterManager.delegate = self;
    }
    return _gameCenterManager;
}

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
        _selectedDifficultyMode = BABDifficultyModeNone;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self checkTokenValidity];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.screenName = @"Menu Screen";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"AuthSegue"]) {
        BABOAuthViewController *authViewController = (BABOAuthViewController *) [segue destinationViewController];
        authViewController.delegate = self;
    } else if ([[segue identifier] isEqualToString:@"BabelSegue"]) {
        BABBabelViewController *babelViewController = (BABBabelViewController *) [segue destinationViewController];
        BABBabelManager *babelManager = [[BABBabelManager alloc] initWithToken:self.token
                                                             andDifficultyMode:self.selectedDifficultyMode];
        [babelManager setupQueue];
        babelViewController.babelManager = babelManager;
        babelViewController.gameCenterManager = self.gameCenterManager;
        babelViewController.notificationManager = self.notificationManager;
        babelViewController.delegate = self;
    } else if ([[segue identifier] isEqualToString:@"InfoSegue"]) {
        BABInfoTableViewController *infoViewController = (BABInfoTableViewController *) [segue destinationViewController];
        infoViewController.gameCenterManager = self.gameCenterManager;
    }
}

- (void)viewDidLayoutSubviews
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        if (UIDeviceOrientationIsLandscape(orientation)) {
            if (self.imageViewIcon.alpha != 0.0f) {
                [UIView animateWithDuration:0.4
                                 animations:^{
                                     self.imageViewIcon.alpha = 0.0f;
                                 }];
            }
        } else {
            if (self.imageViewIcon.alpha == 0.0f) {
                [UIView animateWithDuration:0.4
                                 animations:^{
                                     self.imageViewIcon.alpha = 1.0f;
                                 }];
            }
        }
    }
}

#pragma mark - Private Methods

- (void)checkTokenValidity
{
    @weakify(self);
    
    NSError *error = nil;
    self.token = [BABKeychainHelper retrieveTokenWithError:&error];
    if (!error) {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"menu-view-controller.checking-session.progress-hud.status", nil)
                             maskType:SVProgressHUDMaskTypeBlack];
        [[self.authorizationSessionHelper checkTokenValidityWithToken:self.token]
         continueWithExecutor:[BFExecutor mainThreadExecutor]
         withBlock:^id(BFTask *task) {
             
             @strongify(self);
             
             if (task.error) {
                 if ([task.error.domain isEqualToString:NSURLErrorDomain] && task.error.code == NSURLErrorNotConnectedToInternet) {
                     [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"menu-view-controller.internet-error.progress-hud.status", nil)];
                 } else {
                     [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"menu-view-controller.sesion-expired.progress-hud.status", nil)];
                     NSError *error = nil;
                     [BABKeychainHelper deleteStoredTokenWithError:&error];
                     [self showLogInView];
                 }
             } else {
                 [SVProgressHUD dismiss];
                 [self showLogOutView];
             }
             return nil;
         }];
    } else {
        [self showLogInView];
    }
}

- (IBAction)logIn:(id)sender
{
    [self performSegueWithIdentifier:@"AuthSegue"
                              sender:self];
}

- (IBAction)start:(id)sender
{
    [self.difficultyAlertControllerHelper presentAlertController];
}

- (IBAction)info:(id)sender
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIBarButtonItem *barButtonItem = (UIBarButtonItem *)sender;
        BABInfoTableViewController *infoViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"InfoViewController"];
        infoViewController.gameCenterManager = self.gameCenterManager;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:infoViewController];
        [navigationController.navigationBar setTintColor:self.navigationController.navigationBar.tintColor];
        navigationController.preferredContentSize = CGSizeMake(320, 500);
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        [popoverController presentPopoverFromBarButtonItem:barButtonItem
                                  permittedArrowDirections:UIPopoverArrowDirectionUp
                                                  animated:YES];
    } else {
        [self performSegueWithIdentifier:@"InfoSegue"
                                  sender:self];
    }
}

- (void)logOut:(id)sender
{
    @weakify(self);
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"menu-view-controller.logging-out.progress-hud.status", nil)
                         maskType:SVProgressHUDMaskTypeBlack];
    [[self.authorizationSessionHelper revokeTokenWithToken:self.token]
     continueWithExecutor:[BFExecutor mainThreadExecutor]
     withBlock:^id(BFTask *task) {
         
         @strongify(self);
         
         if (task.error) {
             [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"everywhere.retry-message.string", nil)];
         } else {
             [SVProgressHUD dismiss];
             NSError *error = nil;
             [BABKeychainHelper deleteStoredTokenWithError:&error];
             [self showLogInView];
         }
         return nil;
     }];

}

- (void)showLogInView
{
    UIBarButtonItem *logIn = [[UIBarButtonItem alloc]
                              initWithTitle:NSLocalizedString(@"menu-view-controller.log-in.bar-button-item.title", nil)
                              style:UIBarButtonItemStylePlain
                              target:self
                              action:@selector(logIn:)];
    [self.navigationItem setRightBarButtonItem:logIn
                                      animated:YES];
    [UIView animateWithDuration:0.5f
                     animations:^{
                         self.btnStart.alpha = 0.0f;
                     }];
}

- (void)showLogOutView
{
    UIBarButtonItem *logOut = [[UIBarButtonItem alloc]
                               initWithTitle:NSLocalizedString(@"menu-view-controller.log-out.bar-button-item.title", nil)
                               style:UIBarButtonItemStylePlain
                               target:self
                               action:@selector(logOut:)];
    [self.navigationItem setRightBarButtonItem:logOut
                                      animated:YES];
    [UIView animateWithDuration:0.5f
                     animations:^{
                         self.btnStart.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self.gameCenterManager authenticateLocalPlayer];
                         }
                     }];
}

#pragma mark - BABGameCenterManagerDelegate

- (void)showAuthenticateViewController:(UIViewController *)viewController
{
    [self.navigationController presentViewController:viewController
                                            animated:YES
                                          completion:nil];
}

#pragma mark - BABOAuthViewControllerDelegate

- (void)authViewControllerDidFinishAuthenticationWithToken:(NSString *)token
                                                     error:(NSError *)error
{
    if (!error) {
        NSError *keychainError = nil;
        [BABKeychainHelper storeToken:token
                                error:&keychainError];
        self.token = token;
        [self showLogOutView];
    } else {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"everywhere.retry-message.string", nil)];
    }
}

#pragma mark - BABDifficultyAlertControllerHelperDelegate

- (void)helperDidFinishSelectionWithDifficulty:(BABDifficultyMode)difficulty
{
    self.selectedDifficultyMode = difficulty;
    if (self.selectedDifficultyMode != BABDifficultyModeNone) {
        [self performSegueWithIdentifier:@"BabelSegue"
                                  sender:self];
    }
}

#pragma mark - BABBabelViewControllerDelegate

- (void)controllerDidFinishWithScore:(NSUInteger)score
                   forDifficultyMode:(BABDifficultyMode)difficultyMode
                            withInfo:(NSString *)info
{
    
    [self.gameCenterManager reportScore:score
                      forDifficultyMode:difficultyMode];
    if ([self.gameCenterManager score:score
             isHighScoreForDifficulty:difficultyMode]) {
        [TSMessage
         showNotificationInViewController:self
         title:[NSString stringWithFormat:@"New High Score! Score: %lu", (unsigned long)score]
         subtitle:info
         type:TSMessageNotificationTypeSuccess
         duration:3.0f
         canBeDismissedByUser:YES];
    } else {
        [TSMessage
         showNotificationInViewController:self
         title:[NSString stringWithFormat:@"Wrong! Score: %lu", (unsigned long)score]
         subtitle:info
         type:TSMessageNotificationTypeError
         duration:3.0f
         canBeDismissedByUser:YES];
    }
}

@end
