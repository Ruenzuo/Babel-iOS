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
    for (NSUInteger i = 0; i < count; ++i) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform(remainingCount);
        [self exchangeObjectAtIndex:i
                  withObjectAtIndex:exchangeIndex];
    }
}

@end
