//
//  NSError+BABError.m
//  Babel
//
//  Created by Renzo Crisostomo on 21/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "NSError+BABError.h"

@implementation NSError (BABError)

NSString * const BABErrorDomain = @"BABErrorDomain";

+ (NSError *)bab_authorizationError
{
    return [NSError errorWithDomain:BABErrorDomain
                               code:BABErrorCodeFailedAuthorization
                           userInfo:nil];
}

+ (NSError *)bab_requestError
{
    return [NSError errorWithDomain:BABErrorDomain
                               code:BABErrorCodeFailedRequest
                           userInfo:nil];
}

+ (NSError *)bab_fileNotFound
{
    return [NSError errorWithDomain:BABErrorDomain
                               code:BABErrorCodeFileNotFound
                           userInfo:nil];
}

@end
