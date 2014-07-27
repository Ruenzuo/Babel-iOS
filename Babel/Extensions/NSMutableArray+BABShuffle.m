//
//  NSMutableArray+BABShuffle.m
//  Babel
//
//  Created by Renzo Crisostomo on 25/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "NSMutableArray+BABShuffle.h"

@implementation NSMutableArray (BABShuffle)

- (void)bab_shuffle
{
    NSUInteger count = [self count];
    if (count > 1) {
        for (NSUInteger i = count - 1; i > 0; --i) {
            [self exchangeObjectAtIndex:i
                      withObjectAtIndex:arc4random_uniform((int32_t)(i + 1))];
        }
    }
}

@end
