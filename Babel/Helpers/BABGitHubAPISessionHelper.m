//
//  BABGitHubAPISessionManager.m
//  Babel
//
//  Created by Renzo Crisostomo on 27/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABGitHubAPISessionHelper.h"
#import "BABURLHelper.h"
#import "BABLanguage.h"
#import "BABRepository.h"
#import "BABFile.h"
#import "NSError+BABError.h"
#import "BABTranslatorHelper.h"

@interface BABGitHubAPISessionHelper ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) NSMutableDictionary *repositoriesPaginationCache;

- (NSDictionary *)cachedParametersForLanguage:(BABLanguage *)language
                                        token:(NSString *)token;
- (void)processForCacheWithResponse:(NSURLResponse *)URLResponse
                           language:(BABLanguage *)language;

@end

@implementation BABGitHubAPISessionHelper

static int const BABMaxBytesFileSize = 1 * 1024 * 1024;
static int const BABMinBytesFileSize = 10 * 1024;

- (id)init
{
    self = [super init];
    if (self) {
        self.repositoriesPaginationCache = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Properties

- (AFHTTPSessionManager *)sessionManager
{
    if (_sessionManager == nil) {
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:BABGitHubAPIBaseURL]];
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        [requestSerializer
         setQueryStringSerializationWithBlock:^NSString *(NSURLRequest *request,
                                                          NSDictionary *parameters,
                                                          NSError *__autoreleasing *error) {
             NSMutableArray *joinValues = [NSMutableArray array];
             for (NSString *key in parameters.allKeys) {
                 [joinValues addObject:[NSString stringWithFormat:@"%@=%@",
                                        key,
                                        [parameters objectForKey:key]]];
             }
             return [joinValues componentsJoinedByString:@"&"];
        }];
        [_sessionManager setRequestSerializer:requestSerializer];
        [_sessionManager setResponseSerializer:[AFJSONResponseSerializer serializer]];
    }
    return _sessionManager;
}

#pragma mark - Private Methods

- (NSDictionary *)cachedParametersForLanguage:(BABLanguage *)language
                                        token:(NSString *)token
{
    NSDictionary *cachedPaginationParameters = [self.repositoriesPaginationCache objectForKey:language.search];
    if (cachedPaginationParameters != nil) {
        return cachedPaginationParameters;
    } else {
        return @{@"q": [NSString stringWithFormat:@"language:%@", language.search],
                 @"access_token": token,
                 @"per_page": @5};
    }
}

- (void)processForCacheWithResponse:(NSURLResponse *)URLResponse
                           language:(BABLanguage *)language
{
    if ([URLResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *HTTPURLResponse = (NSHTTPURLResponse *)URLResponse;
        NSDictionary *header = HTTPURLResponse.allHeaderFields;
        NSString *link = header[@"Link"];
        NSArray *components = [link componentsSeparatedByString:@","];
        for (NSString *component in components) {
            NSArray *subcomponets = [component componentsSeparatedByString:@"; rel="];
            NSString *rel = subcomponets[1];
            if ([rel rangeOfString:@"next"].location != NSNotFound) {
                NSString *url = [[subcomponets[0] stringByReplacingOccurrencesOfString:@"<"
                                                                            withString:@""]
                                 stringByReplacingOccurrencesOfString:@">"
                                 withString:@""];
                NSArray *urlComponents = [url componentsSeparatedByString:@"?"];
                [self.repositoriesPaginationCache setObject:[BABTranslatorHelper translateDictionaryWithQuery:urlComponents[1]]
                                                     forKey:language.search];
                break;
            }
        }
    }
}

#pragma mark - Public Methods

- (BFTask *)repositoriesWithLanguage:(BABLanguage *)language
                               token:(NSString *)token
{
    @weakify(self);
    
    BFTaskCompletionSource *completionSource = [BFTaskCompletionSource taskCompletionSource];
    [self.sessionManager GET:@"search/repositories"
                  parameters:[self cachedParametersForLanguage:language
                                                         token:token]
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         
                         @strongify(self);
                         
                         [self processForCacheWithResponse:task.response
                                                  language:language];
                         [completionSource setResult:responseObject];
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         [completionSource setError:error];
                     }];
    return completionSource.task;
}

- (BFTask *)fileWithLanguage:(BABLanguage *)language
                  repository:(BABRepository *)repository
                       token:(NSString *)token
{
    BFTaskCompletionSource *completionSource = [BFTaskCompletionSource taskCompletionSource];
    [self.sessionManager GET:@"search/code"
                  parameters:@{@"q": [[NSString stringWithFormat:@"language:%@+repo:%@+size:<%d+size:>%d", language.search,
                                      repository.name, BABMaxBytesFileSize, BABMinBytesFileSize] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                               @"access_token": token}
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         [completionSource setResult:responseObject];
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         [completionSource setError:error];
                     }];
    return completionSource.task;
}

- (BFTask *)blobWithRepository:(BABRepository *)repository
                          file:(BABFile *)file
                         token:(NSString *)token
{
    BFTaskCompletionSource *completionSource = [BFTaskCompletionSource taskCompletionSource];
    [self.sessionManager GET:[BABURLHelper URLStringForBlobWithRepository:repository
                                                                     file:file]
                  parameters:@{@"access_token": token}
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         [completionSource setResult:responseObject];
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         [completionSource setError:error];
                     }];
    return completionSource.task;
}

@end
