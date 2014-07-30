//
//  BABBabelManager.m
//  Babel
//
//  Created by Renzo Crisostomo on 30/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABBabelManager.h"
#import "BABGitHubAPISessionHelper.h"
#import "BABTranslatorHelper.h"
#import "BABLanguage.h"
#import "BABRepository.h"
#import "BABFile.h"
#import "NSError+BABError.h"
#import "NSMutableArray+BABShuffle.h"

@interface BABBabelManager ()

@property (nonatomic, strong) BABGitHubAPISessionHelper *gitHubAPISessionHelper;
@property (nonatomic, strong) BABTranslatorHelper *translatorHelper;
@property (nonatomic, strong) NSString *token;

- (BABLanguage *)randomLanguage;

@end

@implementation BABBabelManager

NSUInteger const BABMAX_HINT = 5;

- (id)initWithToken:(NSString *)token
{
    self = [super init];
    if (self) {
        _token = token;
        _hintLanguages = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - Properties

- (BABGitHubAPISessionHelper *)gitHubAPISessionHelper
{
    if (_gitHubAPISessionHelper == nil) {
        _gitHubAPISessionHelper = [[BABGitHubAPISessionHelper alloc] init];
    }
    return _gitHubAPISessionHelper;
}

- (BABTranslatorHelper *)translatorHelper
{
    if (_translatorHelper == nil) {
        _translatorHelper = [[BABTranslatorHelper alloc] init];
    }
    return _translatorHelper;
}

- (NSArray *)languages
{
    if (_languages == nil) {
        NSError *error;
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:[[NSBundle mainBundle] pathForResource:@"info"
                                                                                                      ofType:@"json"]];
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                       options:0
                                                                         error:&error];
        if (error) {
            //TODO: Handle error.
        }
        NSValueTransformer *valueTransformer = [MTLValueTransformer mtl_JSONArrayTransformerWithModelClass:[BABLanguage class]];
        NSArray *languages = [valueTransformer transformedValue:jsonDictionary];
        _languages = languages;
    }
    return _languages;
}

#pragma mark - Private Methods

- (NSString *)randomLanguage
{
    return self.languages[arc4random_uniform((int32_t)self.languages.count)];
}

- (BFTask *)randomRepositoryWithLanguage:(BABLanguage *)language
{
    BFTaskCompletionSource *completionSource = [BFTaskCompletionSource taskCompletionSource];
    [[self.gitHubAPISessionHelper
      repositoriesWithLanguage:language
      token:self.token]
     continueWithBlock:^id(BFTask *task) {
         if (task.error) {
             NSLog(@"%@", [task.error localizedDescription]);
             if (task.error.domain == AFURLResponseSerializationErrorDomain &&
                 task.error.code == -1011) {
                 [completionSource setError:[NSError bab_rateLimitReached]];
             } else {
                 [completionSource setError:task.error];
             }
         } else {
             NSDictionary *responseDictionary = task.result;
             NSArray *items = [responseDictionary objectForKey:@"items"];
             NSArray *repositories = [self.translatorHelper translateRepositoriesWithJSONArray:items];
             [completionSource setResult:repositories[arc4random_uniform((int32_t)5)]];
         }
         return nil;
     }];
    return completionSource.task;
}

- (BFTask *)randomFileWithLanguage:(BABLanguage *)language
                        repository:(BABRepository *)repository
{
    BFTaskCompletionSource *completionSource = [BFTaskCompletionSource taskCompletionSource];
    [[self.gitHubAPISessionHelper
      fileWithLanguage:language
      repository:repository
      token:self.token]
     continueWithBlock:^id(BFTask *task) {
         if (task.error) {
             NSLog(@"%@", [task.error localizedDescription]);
             if (task.error.domain == AFURLResponseSerializationErrorDomain &&
                 task.error.code == -1011) {
                 [completionSource setError:[NSError bab_rateLimitReached]];
             } else {
                 [completionSource setError:task.error];
             }
         } else {
             NSDictionary *responseDictionary = (NSDictionary *)task.result;
             NSArray *items = [responseDictionary objectForKey:@"items"];
             NSArray *files = [self.translatorHelper translateFilesWithJSONArray:items];
             if (files.count == 0) {
                 [completionSource setError:[NSError bab_fileNotFound]];
             } else {
                 [completionSource setResult:files[arc4random_uniform((int32_t)files.count)]];
             }
         }
         return nil;
     }];
    return completionSource.task;
}

- (BFTask *)HTMLStringWithLanguage:(BABLanguage *)language
                        repository:(BABRepository *)repository
                              file:(BABFile *)file
{
    BFTaskCompletionSource *completionSource = [BFTaskCompletionSource taskCompletionSource];
    [[self.gitHubAPISessionHelper
      blobWithRepository:repository
      file:file
      token:self.token]
     continueWithBlock:^id(BFTask *task) {
         if (task.error) {
             [completionSource setError:task.error];
         } else {
             NSDictionary *responseDictionary = (NSDictionary *)task.result;
             NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:responseDictionary[@"content"]
                                                                       options:NSDataBase64DecodingIgnoreUnknownCharacters];
             NSString *decodedString = [[NSString alloc] initWithData:decodedData
                                                             encoding:NSUTF8StringEncoding];
             NSString *htmlFilePath = [[NSBundle mainBundle] pathForResource:@"index"
                                                                      ofType:@"html"
                                                                 inDirectory:@"/WebRoot"];
             NSString* htmlString = [NSString stringWithContentsOfFile:htmlFilePath
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil];
             [completionSource setResult:[[htmlString stringByReplacingOccurrencesOfString:@"BABEL_CODE_PLACEHOLDER"
                                                                                withString:decodedString]
                                          stringByReplacingOccurrencesOfString:@"BABEL_LANGUAGE_PLACEHOLDER"
                                          withString:language.css]];
         }
         return nil;
     }];
    return completionSource.task;
}

#pragma mark - Public Methods

- (BFTask *)loadNext
{
    BFTaskCompletionSource *completionSource = [BFTaskCompletionSource taskCompletionSource];
    self.currentLanguage = [self randomLanguage];
    self.currentRepository = nil;
    self.currentFile = nil;
    [[[[self randomRepositoryWithLanguage:self.currentLanguage]
     continueWithBlock:^id(BFTask *task) {
         if (task.error) {
             [completionSource setError:task.error];
             return nil;
         } else {
             self.currentRepository = task.result;
             return [self randomFileWithLanguage:self.currentLanguage
                                      repository:self.currentRepository];
         }
     }] continueWithBlock:^id(BFTask *task) {
         if (task.error) {
             [completionSource setError:task.error];
             return nil;
         } else {
             self.currentFile = task.result;
             return [self HTMLStringWithLanguage:self.currentLanguage
                                      repository:self.currentRepository
                                            file:self.currentFile];
         }
     }] continueWithBlock:^id(BFTask *task) {
         if (task.error) {
             [completionSource setError:task.error];
             return nil;
         } else {
             [completionSource setResult:task.result];
             return nil;
         }
     }];
    return completionSource.task;
}

- (void)prepareHintLanguages
{
    [self.hintLanguages removeAllObjects];
    [self.hintLanguages addObject:self.currentLanguage];
    BOOL finished = NO;
    do {
        int randomIndex = arc4random_uniform((int32_t)self.languages.count);
        if (randomIndex != [self.currentLanguage.index intValue]) {
            [self.hintLanguages addObject:self.languages[randomIndex]];
        }
        if (self.hintLanguages.count >= BABMAX_HINT) {
            finished = YES;
        }
    } while (!finished);
    [self.hintLanguages bab_shuffle];
}

@end
