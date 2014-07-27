//
//  BABTranslatorHelper.h
//  Babel
//
//  Created by Renzo Crisostomo on 27/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BABTranslatorHelper : NSObject

+ (NSDictionary *)translateDictionaryWithQuery:(NSString *)queryString;
- (NSArray *)translateRepositoriesWithJSONArray:(NSArray *)JSONArray;
- (NSArray *)translateFilesWithJSONArray:(NSArray *)JSONArray;

@end
