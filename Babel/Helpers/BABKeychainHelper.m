//
//  BABKeychainHelper.m
//  Babel
//
//  Created by Renzo Crisostomo on 27/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABKeychainHelper.h"

@interface BABKeychainHelper ()

@end

@implementation BABKeychainHelper

NSString * const BABBabelService = @"BABBabelService";
NSString * const BABBabelAccount = @"BABBabelAccount";

+ (NSString *)retrieveTokenWithError:(NSError *__autoreleasing *)error
{
    NSString *token = [SSKeychain passwordForService:BABBabelService
                                             account:BABBabelAccount
                                               error:error];
    if (error) {
        NSLog(@"BABKeychainHelper error: %@", [(*error) localizedDescription]);
    }
    return token;
}

+ (void)storeToken:(NSString *)token
             error:(NSError *__autoreleasing *)error
{
    [SSKeychain setPassword:token
                 forService:BABBabelService
                    account:BABBabelAccount
                      error:error];
    if (error) {
        NSLog(@"BABKeychainHelper error: %@", [(*error) localizedDescription]);
    }
}

@end
