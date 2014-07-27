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

NSString * const BABGitHubAPIBaseURL = @"https://api.github.com/";
NSString * const BABGitHubClientID = @"134fde19a1854aa20f4f";
NSString * const BABGitHubClientSecret = @"5aecca077a31c7f35af8a21146d7738ad47f1390";

@interface BABURLHelper ()

@end

@implementation BABURLHelper

#pragma mark - Public Methods

+ (NSURL *)URLForAuthorization
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/login/oauth/authorize?client_id=%@",
                                 BABGitHubClientID]];
}

+ (NSURL *)URLForAccessTokenWithCode:(NSString *)code
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/login/oauth/access_token?client_id=%@&client_secret=%@&code=%@",
                                 BABGitHubClientID,
                                 BABGitHubClientSecret,
                                 code]];
}

+ (NSString *)URLStringForBlobWithRepository:(BABRepository *)repository
                                        file:(BABFile *)file
{
    return [NSString stringWithFormat:@"repos/%@/git/blobs/%@",
            repository.name,
            file.sha];
}

+ (NSString *)URLStringForTokenValidityWithToken:(NSString *)token
{
    return [NSString stringWithFormat:@"applications/%@/tokens/%@",
            BABGitHubClientID,
            token];
}

@end
