//
//  BABRepository.m
//  Babel
//
//  Created by Renzo Crisostomo on 23/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABRepository.h"

@implementation BABRepository

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"name" : @"full_name"
             };
}

@end
