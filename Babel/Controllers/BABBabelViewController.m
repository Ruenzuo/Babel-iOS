//
//  BABBabelViewController.m
//  Babel
//
//  Created by Renzo Crisostomo on 23/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABBabelViewController.h"
#import "BABLanguage.h"
#import "BABRepository.h"
#import "BABFile.h"
#import "NSError+BABError.h"

@interface BABBabelViewController ()

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSArray *languages;
@property (nonatomic, strong) NSMutableDictionary *paginationCache;
@property (nonatomic, strong) BABLanguage *currentLanguage;
@property (nonatomic, strong) BABRepository *currentRepository;
@property (nonatomic, assign, getter = isPooling) BOOL pooling;
@property (nonatomic, strong) MSWeakTimer *timer;

- (void)loadLanguages;
- (BABLanguage *)randomLanguage;
- (BFTask *)randomRepositoryWithLanguage:(BABLanguage *)language;
- (NSURL *)URLForRepositoryWithLanguage:(BABLanguage *)language;
- (NSURL *)URLForFileWithLanguage:(BABLanguage *)language
                       repository:(BABRepository *)repository;
- (BFTask *)randomFileWithLanguage:(BABLanguage *)language
                        repository:(BABRepository *)repository;
- (void)nextFile;
- (void)poolRate;

@end

@implementation BABBabelViewController

NSString * const BABGitHubAPIBaseURL = @"https://api.github.com/";

#pragma mark - View controller life cycle

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.paginationCache = [[NSMutableDictionary alloc] init];
        self.pooling = false;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadLanguages];
    [self nextFile];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Private Methods

- (void)nextFile
{
    self.currentLanguage = [self randomLanguage];
    [[[self randomRepositoryWithLanguage:self.currentLanguage] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            //TODO: Handle error;
            NSLog(@"%@", [task.error localizedDescription]);
            if (task.error.domain == AFURLResponseSerializationErrorDomain &&
                task.error.code == -1011) {
                if (!self.isPooling) {
                    [self poolRate];
                }
                return nil;
            }
        }
        self.currentRepository = task.result;
        return [self randomFileWithLanguage:self.currentLanguage
                                 repository:self.currentRepository];
    }] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            //TODO: Handle error;
            NSLog(@"%@", [task.error localizedDescription]);
            if (task.error.code == BABErrorCodeFileNotFound) {
                NSLog(@"Looping");
                [self nextFile];
            }
            if (task.error.domain == AFURLResponseSerializationErrorDomain &&
                task.error.code == -1011) {
                if (!self.isPooling) {
                    [self poolRate];
                }
            }
        } else {
            if (task.result != nil) {
                if (self.isPooling) {
                    [self stopPool];
                }
                BABFile *file = task.result;
                NSLog(@"SHA: %@", file.sha);
                NSLog(@"Repository: %@", self.currentRepository.name);
                NSLog(@"Language: %@", self.currentLanguage.name);
            }
        }
        return nil;
    }];
}

- (void)poolRate
{
    [SVProgressHUD showWithStatus:@"Pooling rate"
                         maskType:SVProgressHUDMaskTypeBlack];
    self.pooling = YES;
    self.timer = [MSWeakTimer scheduledTimerWithTimeInterval:5
                                                      target:self
                                                    selector:@selector(nextFile)
                                                    userInfo:nil
                                                     repeats:YES
                                               dispatchQueue:dispatch_get_main_queue()];
}

- (void)stopPool
{
    [SVProgressHUD dismiss];
    self.pooling = NO;
    [self.timer invalidate];
}

- (void)loadLanguages
{
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
    self.languages = languages;
}

- (NSString *)randomLanguage
{
    return self.languages[arc4random()%self.languages.count];
}

- (BFTask *)randomRepositoryWithLanguage:(BABLanguage *)language
{
    BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForRepositoryWithLanguage:language]];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.responseSerializer = [AFJSONResponseSerializer serializer];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSHTTPURLResponse *response = operation.response;
        NSDictionary *header = response.allHeaderFields;
        NSString *link = header[@"Link"];
        NSArray *components = [link componentsSeparatedByString:@","];
        for (NSString *component in components) {
            NSArray *subcomponets = [component componentsSeparatedByString:@"; rel="];
            NSString *rel = subcomponets[1];
            if ([rel rangeOfString:@"next"].location != NSNotFound) {
                NSString *url = [[subcomponets[0] stringByReplacingOccurrencesOfString:@"<"
                                                                           withString:@""]
                                 stringByReplacingOccurrencesOfString:@">"
                                 withString:@""];
                [self.paginationCache setObject:url
                                         forKey:language.name];
                break;
            }
        }
        NSDictionary *responseDictionary = (NSDictionary *)responseObject;
        NSArray *items = [responseDictionary objectForKey:@"items"];
        NSValueTransformer *valueTransformer = [MTLValueTransformer mtl_JSONArrayTransformerWithModelClass:[BABRepository class]];
        NSArray *repositories = [valueTransformer transformedValue:items];
        [task setResult:repositories[arc4random()%5]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [task setError:error];
    }];
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
    return task.task;
}

- (NSURL *)URLForRepositoryWithLanguage:(BABLanguage *)language
{
    NSString *cached = [self.paginationCache objectForKey:language.name];
    if (cached != nil) {
        return [NSURL URLWithString:cached];
    } else {
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@search/repositories?q=%@&access_token=%@&per_page=5",
                                     BABGitHubAPIBaseURL,
                                     language.name,
                                     self.token]];
    }
}

- (NSURL *)URLForFileWithLanguage:(BABLanguage *)language
                       repository:(BABRepository *)repository
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@search/code?q=language:%@+repo:%@&access_token=%@",
                                 BABGitHubAPIBaseURL,
                                 language.name,
                                 repository.name,
                                 self.token]];
}

- (BFTask *)randomFileWithLanguage:(BABLanguage *)language
                        repository:(BABRepository *)repository
{
    BFTaskCompletionSource *task = [BFTaskCompletionSource taskCompletionSource];
    NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForFileWithLanguage:language
                                                                           repository:repository]];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    requestOperation.responseSerializer = [AFJSONResponseSerializer serializer];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *responseDictionary = (NSDictionary *)responseObject;
        NSArray *items = [responseDictionary objectForKey:@"items"];
        NSValueTransformer *valueTransformer = [MTLValueTransformer mtl_JSONArrayTransformerWithModelClass:[BABFile class]];
        NSArray *files = [valueTransformer transformedValue:items];
        if (files.count == 0) {
            [task setError:[NSError bab_fileNotFound]];
        } else {
            [task setResult:files[arc4random()%files.count]];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [task setError:error];
    }];
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
    return task.task;
}

@end
