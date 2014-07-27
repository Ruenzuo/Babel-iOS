//
//  BABKeychainHelper.h
//  Babel
//
//  Created by Renzo Crisostomo on 27/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BABKeychainHelper : NSObject

+ (NSString *)retrieveTokenWithError:(NSError *__autoreleasing *)error;
+ (void)storeToken:(NSString *)token
             error:(NSError *__autoreleasing *)error;

@end
