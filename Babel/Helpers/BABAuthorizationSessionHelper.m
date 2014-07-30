//
//  BABNetworkingManager.m
//  Babel
//
//  Created by Renzo Crisostomo on 27/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABAuthorizationSessionHelper.h"
#import "BABURLHelper.h"

@interface BABAuthorizationSessionHelper ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation BABAuthorizationSessionHelper

#pragma mark - Properties

- (AFHTTPSessionManager *)sessionManager
{
    if (_sessionManager == nil) {
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:BABGitHubAPIBaseURL]];
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer setAuthorizationHeaderFieldWithUsername:BABGitHubClientID
                                                          password:BABGitHubClientSecret];
        [_sessionManager setRequestSerializer:requestSerializer];
        [_sessionManager setResponseSerializer:[AFJSONResponseSerializer serializer]];
    }
    return _sessionManager;
}

#pragma mark - Public Methods

- (BFTask *)checkTokenValidityWithToken:(NSString *)token
{
    BFTaskCompletionSource *completionSource = [BFTaskCompletionSource taskCompletionSource];
    [self.sessionManager GET:[BABURLHelper URLStringForTokenValidityWithToken:token]
                  parameters:nil
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         [completionSource setResult:[NSNumber numberWithBool:YES]];
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         [completionSource setError:error];
                     }];
    return completionSource.task;
}

- (BFTask *)revokeTokenWithToken:(NSString *)token
{
    BFTaskCompletionSource *completionSource = [BFTaskCompletionSource taskCompletionSource];
    [self.sessionManager DELETE:[BABURLHelper URLStringForTokenValidityWithToken:token]
                     parameters:nil
                        success:^(NSURLSessionDataTask *task, id responseObject) {
                            [completionSource setResult:[NSNumber numberWithBool:YES]];
                        }
                        failure:^(NSURLSessionDataTask *task, NSError *error) {
                            [completionSource setError:error];
                        }];
    return completionSource.task;
}

@end
