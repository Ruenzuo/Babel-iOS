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
#import "BABAuthorizationSessionManager.h"

@interface BABMenuViewController () <BABOAuthViewControllerDelegate>

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) IBOutlet UIButton *btnStart;
@property (nonatomic, strong) BABAuthorizationSessionManager *authorizationSessionManager;

- (void)checkTokenValidity;
- (IBAction)logIn:(id)sender;
- (void)logOut:(id)sender;
- (void)showLogInView;
- (void)showLogOutView;

@end

@implementation BABMenuViewController

#pragma mark - Properties

- (BABAuthorizationSessionManager *)authorizationSessionManager
{
    if (_authorizationSessionManager == nil) {
        _authorizationSessionManager = [[BABAuthorizationSessionManager alloc] init];
    }
    return _authorizationSessionManager;
}

#pragma mark - View controller life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self checkTokenValidity];
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
        babelViewController.token = self.token;
    }
}

#pragma mark - Private Methods

- (void)checkTokenValidity
{
    @weakify(self);
    
    NSError *error = nil;
    self.token = [BABKeychainHelper retrieveTokenWithError:&error];
    if (!error) {
        [SVProgressHUD showWithStatus:@"Checking session validity."
                             maskType:SVProgressHUDMaskTypeBlack];
        [[self.authorizationSessionManager checkTokenValidityWithToken:self.token] continueWithBlock:^id(BFTask *task) {
            
            @strongify(self);
            
            if (task.error) {
                [SVProgressHUD showErrorWithStatus:@"Session expired."];
                NSError *error = nil;
                [BABKeychainHelper deleteStoredTokenWithError:&error];
            } else {
                [SVProgressHUD dismiss];
                [self showLogOutView];
            }
            return nil;
        }];
    }
}

- (IBAction)logIn:(id)sender
{
    [self performSegueWithIdentifier:@"AuthSegue"
                              sender:self];
}

- (void)logOut:(id)sender
{
    @weakify(self);
    
    [SVProgressHUD showWithStatus:@"Logging out."
                         maskType:SVProgressHUDMaskTypeBlack];
    [[self.authorizationSessionManager revokeTokenWithToken:self.token] continueWithBlock:^id(BFTask *task) {
        
        @strongify(self);
        
        if (task.error) {
            [SVProgressHUD showErrorWithStatus:@"An error has occurred. Please try this again later."];
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
    UIBarButtonItem *logIn = [[UIBarButtonItem alloc] initWithTitle:@"Log In"
                                                              style:UIBarButtonItemStyleBordered
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
    UIBarButtonItem *logOut = [[UIBarButtonItem alloc] initWithTitle:@"Log Out"
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:@selector(logOut:)];
    [self.navigationItem setRightBarButtonItem:logOut
                                      animated:YES];
    [UIView animateWithDuration:0.5f
                     animations:^{
                         self.btnStart.alpha = 1.0f;
                     }];
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
        [SVProgressHUD showErrorWithStatus:@"An error has occurred. Please try this again later."];
    }
}

@end
