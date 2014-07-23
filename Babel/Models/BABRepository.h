//
//  BABRepository.h
//  Babel
//
//  Created by Renzo Crisostomo on 23/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BABRepository : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *name;

@end
