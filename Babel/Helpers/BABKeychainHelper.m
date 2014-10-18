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

static NSString * const BABBabelService = @"BABBabelService";
static NSString * const BABBabelAccount = @"BABBabelAccount";

#pragma mark - Public Methods

+ (NSString *)retrieveTokenWithError:(NSError *__autoreleasing *)error
{
    NSError *keychainError = nil;
    NSString *token = [SSKeychain passwordForService:BABBabelService
                                             account:BABBabelAccount
                                               error:&keychainError];
    if (keychainError) {
        DDLogError(@"BABKeychainHelper error: %@", [keychainError localizedDescription]);
        *error = keychainError;
    }
    return token;
}

+ (void)storeToken:(NSString *)token
             error:(NSError *__autoreleasing *)error
{
    NSError *keychainError = nil;
    [SSKeychain setPassword:token
                 forService:BABBabelService
                    account:BABBabelAccount
                      error:&keychainError];
    if (keychainError) {
        DDLogError(@"BABKeychainHelper error: %@", [keychainError localizedDescription]);
        *error = keychainError;
    }
}

+ (void)deleteStoredTokenWithError:(NSError *__autoreleasing *)error
{
    NSError *keychainError = nil;
    [SSKeychain deletePasswordForService:BABBabelService
                                 account:BABBabelAccount
                                   error:&keychainError];
    if (keychainError) {
        DDLogError(@"BABKeychainHelper error: %@", [(*error) localizedDescription]);
        *error = keychainError;
    }
}

@end
