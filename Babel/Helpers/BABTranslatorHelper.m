//
//  BABTranslatorHelper.m
//  Babel
//
//  Created by Renzo Crisostomo on 27/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABTranslatorHelper.h"
#import "BABRepository.h"
#import "BABFile.h"

@interface BABTranslatorHelper ()

@property (nonatomic, strong) NSValueTransformer *repositoriesValueTransformer;
@property (nonatomic, strong) NSValueTransformer *filesValueTransformer;

@end

@implementation BABTranslatorHelper

#pragma mark - Properties

- (NSValueTransformer *)repositoriesValueTransformer
{
    if (_repositoriesValueTransformer == nil) {
        _repositoriesValueTransformer = [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[BABRepository class]];
    }
    return _repositoriesValueTransformer;
}

- (NSValueTransformer *)filesValueTransformer
{
    if (_filesValueTransformer == nil) {
        _filesValueTransformer = [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[BABFile class]];
    }
    return _filesValueTransformer;
}

#pragma mark - Public Methods

+ (NSDictionary *)translateDictionaryWithQuery:(NSString *)queryString
{
    NSArray *components = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:[components count]];
    for (NSString *component in components) {
        NSArray *pairComponents = [component componentsSeparatedByString:@"="];
        [dictionary setObject:pairComponents[1] forKey:pairComponents[0]];
    }
    return [dictionary copy];
}

- (NSArray *)translateRepositoriesWithJSONArray:(NSArray *)JSONArray
{
    return [self.repositoriesValueTransformer transformedValue:JSONArray];
}

- (NSArray *)translateFilesWithJSONArray:(NSArray *)JSONArray
{
    return [self.filesValueTransformer transformedValue:JSONArray];
}

@end
