//
//  BABURLHelper.h
//  Babel
//
//  Created by Renzo Crisostomo on 27/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BABLanguage;
@class BABRepository;
@class BABFile;

extern NSString *const BABGitHubAPIBaseURL;
extern NSString *const BABGitHubClientID;
extern NSString *const BABGitHubClientSecret;

@interface BABURLHelper : NSObject

+ (NSURL *)URLForAuthorization;
+ (NSURL *)URLForAccessTokenWithCode:(NSString *)code;
+ (NSString *)URLStringForBlobWithRepository:(BABRepository *)repository
                                        file:(BABFile *)file;
+ (NSString *)URLStringForTokenValidityWithToken:(NSString *)token;

@end
