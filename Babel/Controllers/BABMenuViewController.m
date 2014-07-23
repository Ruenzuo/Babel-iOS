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

@interface BABMenuViewController () <BABOAuthViewControllerDelegate>

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) IBOutlet UIButton *btnStart;

- (NSString *)retrieveToken;
- (void)storeToken:(NSString *)token;
- (IBAction)start:(id)sender;
- (void)updateUI;

@end

@implementation BABMenuViewController

NSString * const BABBabelService = @"BABBabelService";
NSString * const BABBabelAccount = @"BABBabelAccount";

#pragma mark - View controller life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.token = [self retrieveToken];
    [self updateUI];
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

- (void)updateUI
{
    if (self.token != nil) {
        self.navigationItem.rightBarButtonItem = nil;
        [UIView animateWithDuration:0.5f
                         animations:^{
                             self.btnStart.alpha = 1.0f;
                         }];
    }
}

- (IBAction)start:(id)sender
{
    
}

- (NSString *)retrieveToken
{
    NSError *error;
    NSString *token = [SSKeychain passwordForService:BABBabelService
                                             account:BABBabelAccount
                                               error:&error];
    if (error) {
        //TODO: Handle error.
    }
    return token;
}

- (void)storeToken:(NSString *)token
{
    NSError *error;
    [SSKeychain setPassword:token
                 forService:BABBabelService
                    account:BABBabelAccount
                      error:&error];
    if (error) {
        //TODO: Handle error.
    }
}

#pragma mark - BABOAuthViewControllerDelegate

- (void)authViewControllerDidFinishAuthenticationWithToken:(NSString *)token
                                                     error:(NSError *)error
{
    if (!error) {
        [self storeToken:token];
        self.token = token;
        [self updateUI];
    } else {
        //TODO: Handle error.
    }
}

@end
