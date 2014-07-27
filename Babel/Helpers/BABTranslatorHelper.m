//
//  BABTranslatorHelper.m
//  Babel
//
//  Created by Renzo Crisostomo on 27/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABTranslatorHelper.h"

@interface BABTranslatorHelper ()

@end

@implementation BABTranslatorHelper

#pragma mark - Public Methods

+ (NSDictionary *)dictionaryWithQuery:(NSString *)queryString
{
    NSArray *components = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:[components count]];
    for (NSString *component in components) {
        NSArray *pairComponents = [component componentsSeparatedByString:@"="];
        [dictionary setObject:pairComponents[1] forKey:pairComponents[0]];
    }
    return [dictionary copy];
}

@end
