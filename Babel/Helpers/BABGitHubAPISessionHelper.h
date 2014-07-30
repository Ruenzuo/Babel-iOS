//
//  BABGitHubAPISessionManager.h
//  Babel
//
//  Created by Renzo Crisostomo on 27/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BABLanguage;
@class BABRepository;
@class BABFile;

@interface BABGitHubAPISessionHelper : NSObject

- (BFTask *)repositoriesWithLanguage:(BABLanguage *)language
                               token:(NSString *)token;
- (BFTask *)fileWithLanguage:(BABLanguage *)language
                  repository:(BABRepository *)repository
                       token:(NSString *)token;
- (BFTask *)blobWithRepository:(BABRepository *)repository
                          file:(BABFile *)file
                         token:(NSString *)token;

@end
