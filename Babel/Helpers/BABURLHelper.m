//
//  BABURLHelper.m
//  Babel
//
//  Created by Renzo Crisostomo on 27/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABURLHelper.h"
#import "BABLanguage.h"
#import "BABRepository.h"
#import "BABFile.h"

@interface BABURLHelper ()

@end

@implementation BABURLHelper

NSString * const BABGitHubClientID = @"134fde19a1854aa20f4f";
NSString * const BABGitHubClientSecret = @"5aecca077a31c7f35af8a21146d7738ad47f1390";
NSString * const BABGitHubAPIBaseURL = @"https://api.github.com/";

+ (NSURL *)authorizeURL
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/login/oauth/authorize?client_id=%@",
                                 BABGitHubClientID]];
}

+ (NSURL *)accessTokenURLWithCode:(NSString *)code
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/login/oauth/access_token?client_id=%@&client_secret=%@&code=%@",
                                 BABGitHubClientID,
                                 BABGitHubClientSecret,
                                 code]];
}

+ (NSURL *)URLForRepositoryWithLanguage:(BABLanguage *)language
                                  token:(NSString *)token
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@search/repositories?q=%@&access_token=%@&per_page=5",
                                 BABGitHubAPIBaseURL,
                                 language.search,
                                 token]];
}

+ (NSURL *)URLForFileWithLanguage:(BABLanguage *)language
                       repository:(BABRepository *)repository
                            token:(NSString *)token
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@search/code?q=language:%@+repo:%@&access_token=%@",
                                 BABGitHubAPIBaseURL,
                                 language.search,
                                 repository.name,
                                 token]];
}

+ (NSURL *)URLForBlobWithRepository:(BABRepository *)repository
                               file:(BABFile *)file
                              token:(NSString *)token
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@repos/%@/git/blobs/%@?access_token=%@",
                                 BABGitHubAPIBaseURL,
                                 repository.name,
                                 file.sha,
                                 token]];
}

@end
