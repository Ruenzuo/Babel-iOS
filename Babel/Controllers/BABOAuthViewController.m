//
//  BABOAuthViewController.m
//  Babel
//
//  Created by Renzo Crisostomo on 21/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABOAuthViewController.h"
#import "NSError+BABError.h"

@interface BABOAuthViewController () <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;

- (NSURL *)authorizeURL;
- (NSURL *)accessTokenURLWithCode:(NSString *)codel;
- (void)getAccessTokenWithCode:(NSString *)code;
- (NSDictionary *)dictionaryWithQuery:(NSString *)queryString;

@end

@implementation BABOAuthViewController

NSString * const BABGitHubClientID = @"134fde19a1854aa20f4f";
NSString * const BABGitHubClientSecret = @"5aecca077a31c7f35af8a21146d7738ad47f1390";

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
    NSURLRequest *URLRequest = [NSURLRequest requestWithURL:[self authorizeURL]];
    [self.webView loadRequest:URLRequest];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Private Methods

- (NSDictionary *)dictionaryWithQuery:(NSString *)queryString
{
    NSArray *components = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:[components count]];
    for (NSString *component in components) {
        NSArray *pairComponents = [component componentsSeparatedByString:@"="];
        [dictionary setObject:pairComponents[1] forKey:pairComponents[0]];
    }
    return [dictionary copy];
}

- (NSURL *)authorizeURL
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/login/oauth/authorize?client_id=%@",
                                 BABGitHubClientID]];
}

- (NSURL *)accessTokenURLWithCode:(NSString *)code
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/login/oauth/access_token?client_id=%@&client_secret=%@&code=%@",
                                 BABGitHubClientID,
                                 BABGitHubClientSecret,
                                 code]];
}

- (void)getAccessTokenWithCode:(NSString *)code
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[self accessTokenURLWithCode:code]];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.responseSerializer = [AFHTTPResponseSerializer serializer];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        NSString *query = [[NSString alloc] initWithData:responseObject
                                                   encoding:NSUTF8StringEncoding];
        NSDictionary *dictionary = [self dictionaryWithQuery:query];
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
            [self.delegate authViewControllerDidFinishAuthenticationWithToken:nil
                                                                        error:[NSError bab_requestError]];
        }
    }];
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[[request URL] scheme] isEqualToString:@"babel"]) {
        [SVProgressHUD showWithStatus:@"Retrieving access token"
                             maskType:SVProgressHUDMaskTypeBlack];
        NSString *query = [[request URL] query];
        NSDictionary *dictionary = [self dictionaryWithQuery:query];
        NSString *code = dictionary[@"code"];
        [self getAccessTokenWithCode:code];
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (error != nil) {
        if ([error domain] == NSURLErrorDomain) {
            [SVProgressHUD showErrorWithStatus:@"An error has occurred. Please try this again later."];
        }
    }
}

@end
