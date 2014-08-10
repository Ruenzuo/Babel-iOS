//
//  NSError+BABError.h
//  Babel
//
//  Created by Renzo Crisostomo on 21/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (BABError)

+ (NSError *)bab_authorizationError;
+ (NSError *)bab_requestError;
+ (NSError *)bab_fileNotFoundError;
+ (NSError *)bab_rateLimitReachedError;
+ (NSError *)bab_stringDecodingError;

@end
