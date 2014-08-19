//
//  BABOAuthViewController.m
//  Babel
//
//  Created by Renzo Crisostomo on 21/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABOAuthViewController.h"
#import "NSError+BABError.h"
#import "BABURLHelper.h"
#import "BABTranslatorHelper.h"

@interface BABOAuthViewController () <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;

- (void)getAccessTokenWithCode:(NSString *)code;

@end

@implementation BABOAuthViewController

#pragma mark - View controller life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSURLRequest *URLRequest = [NSURLRequest requestWithURL:[BABURLHelper URLForAuthorization]];
    [self.webView loadRequest:URLRequest];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.screenName = @"OAuth Screen";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Private Methods

- (void)getAccessTokenWithCode:(NSString *)code
{
    @weakify(self);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[BABURLHelper URLForAccessTokenWithCode:code]];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.responseSerializer = [AFHTTPResponseSerializer serializer];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @strongify(self);
        
        [SVProgressHUD dismiss];
        NSString *query = [[NSString alloc] initWithData:responseObject
                                                   encoding:NSUTF8StringEncoding];
        NSDictionary *dictionary = [BABTranslatorHelper translateDictionaryWithQuery:query];
        NSString *token = [dictionary objectForKey:@"access_token"];
        if (token != nil) {
            [self.delegate authViewControllerDidFinishAuthenticationWithToken:token
                                                                        error:nil];
        } else {
            [self.delegate authViewControllerDidFinishAuthenticationWithToken:nil
                                                                        error:[NSError bab_authorizationError]];
        }
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (error != nil) {
            [SVProgressHUD showErrorWithStatus:@"An error has occurred. Please try this again later."];
        }
    }];
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[[request URL] scheme] isEqualToString:@"babel"]) {
        NSString *query = [[request URL] query];
        NSDictionary *dictionary = [BABTranslatorHelper translateDictionaryWithQuery:query];
        NSString *code = dictionary[@"code"];
        if (code != nil) {
            [SVProgressHUD showWithStatus:@"Retrieving access token"
                                 maskType:SVProgressHUDMaskTypeBlack];
            [self getAccessTokenWithCode:code];
        } else {
            [SVProgressHUD showErrorWithStatus:@"An error has occurred. Please try this again later."];
        }
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (error != nil) {
        if ([[error domain] isEqualToString:@"WebKitErrorDomain"] &&
            error.code == 102) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
