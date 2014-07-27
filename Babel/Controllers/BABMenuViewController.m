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

@interface BABMenuViewController () <BABOAuthViewControllerDelegate>

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) IBOutlet UIButton *btnStart;

- (void)updateView;

@end

@implementation BABMenuViewController

#pragma mark - View controller life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSError *error;
    self.token = [BABKeychainHelper retrieveTokenWithError:&error];
    if (!error) {
        [self updateView];
    }
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

- (void)updateView
{
    [self.navigationItem setRightBarButtonItem:nil
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
        NSError *keychainError;
        [BABKeychainHelper storeToken:token
                                error:&keychainError];
        if (error) {
            //TODO: Handle error.
        }
        self.token = token;
        [self updateView];
    } else {
        //TODO: Handle error.
    }
}

@end
