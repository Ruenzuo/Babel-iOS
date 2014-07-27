//
//  BABNetworkingManager.h
//  Babel
//
//  Created by Renzo Crisostomo on 27/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BABAuthorizationSessionManager : NSObject

- (BFTask *)checkTokenValidityWithToken:(NSString *)token;
- (BFTask *)revokeTokenWithToken:(NSString *)token;

@end
