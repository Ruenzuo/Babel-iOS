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

@interface BABURLHelper : NSObject

+ (NSURL *)authorizeURL;
+ (NSURL *)accessTokenURLWithCode:(NSString *)code;
+ (NSURL *)URLForRepositoryWithLanguage:(BABLanguage *)language
                                  token:(NSString *)token;
+ (NSURL *)URLForFileWithLanguage:(BABLanguage *)language
                       repository:(BABRepository *)repository
                            token:(NSString *)token;
+ (NSURL *)URLForBlobWithRepository:(BABRepository *)repository
                               file:(BABFile *)file
                              token:(NSString *)token;

@end
