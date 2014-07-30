//
//  BABBabelManager.h
//  Babel
//
//  Created by Renzo Crisostomo on 30/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BABLanguage;
@class BABRepository;
@class BABFile;

@interface BABBabelManager : NSObject

@property (nonatomic, strong) BABLanguage *currentLanguage;
@property (nonatomic, strong) BABRepository *currentRepository;
@property (nonatomic, strong) BABFile *currentFile;
@property (nonatomic, strong) NSMutableArray *hintLanguages;
@property (nonatomic, strong) NSArray *languages;

- (id)initWithToken:(NSString *)token;
- (BFTask *)loadNext;
- (void)prepareHintLanguages;

@end
