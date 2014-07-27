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
#import "NSMutableArray+BABShuffle.h"
#import "BABURLHelper.h"
#import "BABGitHubAPISessionManager.h"
#import "BABTranslatorHelper.h"

@interface BABBabelViewController () <UIWebViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *languages;
@property (nonatomic, strong) NSMutableArray *hintLanguages;
@property (nonatomic, strong) BABLanguage *currentLanguage;
@property (nonatomic, strong) BABRepository *currentRepository;
@property (nonatomic, strong) BABFile *currentFile;
@property (nonatomic, assign, getter = isPooling) BOOL pooling;
@property (nonatomic, strong) MSWeakTimer *timer;
@property (nonatomic, weak) IBOutlet UIToolbar *toolBar;
@property (nonatomic, weak) FBShimmeringView *titleShimmeringView;
@property (nonatomic, assign, getter = isHintEnabled) BOOL hintEnabled;
@property (nonatomic, assign) NSUInteger points;
@property (nonatomic, strong) BABGitHubAPISessionManager *gitHubAPISessionManager;
@property (nonatomic, strong) BABTranslatorHelper *translatorHelper;

- (void)setupInsets;
- (void)loadLanguages;
- (BABLanguage *)randomLanguage;
- (void)nextFile;
- (void)poolRate;
- (IBAction)skip:(id)sender;
- (IBAction)guess:(id)sender;
- (void)hint:(id)sender;
- (void)code:(id)sender;
- (void)setupLoadingIndicator;
- (void)setupGuess;

@end

@implementation BABBabelViewController

NSString * const BABLanguageTableViewCell = @"BABLanguageTableViewCell";
NSUInteger const BABMAX_HINT = 5;

#pragma mark - Properties

- (BABGitHubAPISessionManager *)gitHubAPISessionManager
{
    if (_gitHubAPISessionManager == nil) {
        _gitHubAPISessionManager = [[BABGitHubAPISessionManager alloc] init];
    }
    return _gitHubAPISessionManager;
}

- (BABTranslatorHelper *)translatorHelper
{
    if (_translatorHelper == nil) {
        _translatorHelper = [[BABTranslatorHelper alloc] init];
    }
    return _translatorHelper;
}

#pragma mark - View controller life cycle

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.hintLanguages = [[NSMutableArray alloc] init];
        self.pooling = false;
        self.points = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTitle];
    [self loadLanguages];
    [self setupInsets];
    [self setupLoadingIndicator];
    [self nextFile];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Private Methods

- (IBAction)skip:(id)sender
{
    [self setupLoadingIndicator];
    [UIView animateWithDuration:0.5f
                     animations:^{
                         self.webView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self nextFile];
                         }
                     }];
}

- (IBAction)guess:(id)sender
{
    UIBarButtonItem *code = [[UIBarButtonItem alloc] initWithTitle:@"Code"
                                                             style:UIBarButtonItemStyleBordered
                                                            target:self
                                                            action:@selector(code:)];
    [self.navigationItem setRightBarButtonItem:code
                                      animated:YES];
    if (!self.isHintEnabled) {
        UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
        UIBarButtonItem *hint = [[UIBarButtonItem alloc] initWithTitle:@"Hint"
                                                                 style:UIBarButtonItemStyleBordered
                                                                target:self
                                                                action:@selector(hint:)];
        [self.toolBar setItems:@[separator, hint]
                      animated:YES];
    }
    [UIView animateWithDuration:0.5f
                     animations:^{
                         self.webView.alpha = 0.0f;
                         self.tableView.alpha = 1.0f;
                     }];
}

- (void)code:(id)sender
{
    UIBarButtonItem *guess = [[UIBarButtonItem alloc] initWithTitle:@"Guess"
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(guess:)];
    [self.navigationItem setRightBarButtonItem:guess
                                      animated:YES];
    if (!self.isHintEnabled) {
        UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
        UIBarButtonItem *skip = [[UIBarButtonItem alloc] initWithTitle:@"Skip"
                                                                 style:UIBarButtonItemStyleBordered
                                                                target:self
                                                                action:@selector(skip:)];
        [self.toolBar setItems:@[separator, skip]
                      animated:YES];
    }
    [UIView animateWithDuration:0.5f
                     animations:^{
                         self.webView.alpha = 1.0f;
                         self.tableView.alpha = 0.0f;
                     }];
}

- (void)hint:(id)sender
{
    self.hintEnabled = YES;
    [self.toolBar setItems:@[]
                  animated:YES];
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
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationFade];
}

- (void)setupTitle
{
    FBShimmeringView *shimmeringView = [[FBShimmeringView alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
    [self.navigationItem setTitleView:shimmeringView];
    self.titleShimmeringView = shimmeringView;
    UILabel *loadingLabel = [[UILabel alloc] initWithFrame:shimmeringView.bounds];
    loadingLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    loadingLabel.textAlignment = NSTextAlignmentCenter;
    loadingLabel.text = @"Babel";
    shimmeringView.contentView = loadingLabel;
}

- (void)setupLoadingIndicator
{
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityIndicatorView startAnimating];
    UIBarButtonItem *loadingIndicator = [[UIBarButtonItem alloc] initWithCustomView:activityIndicatorView];
    [self.navigationItem setRightBarButtonItem:loadingIndicator
                                      animated:YES];
    [self.toolBar setItems:@[]
                  animated:YES];
    self.titleShimmeringView.shimmering = YES;
}

- (void)setupGuess
{
    UIBarButtonItem *guess = [[UIBarButtonItem alloc] initWithTitle:@"Guess"
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(guess:)];
    [self.navigationItem setRightBarButtonItem:guess
                                      animated:YES];
    UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                               target:nil
                                                                               action:nil];
    UIBarButtonItem *skip = [[UIBarButtonItem alloc] initWithTitle:@"Skip"
                                                             style:UIBarButtonItemStyleBordered
                                                            target:self
                                                            action:@selector(skip:)];
    [self.toolBar setItems:@[separator, skip]
                  animated:YES];
    self.titleShimmeringView.shimmering = NO;
}

- (void)setupInsets
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake([UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height, 0, self.toolBar.frame.size.height, 0);
    self.webView.scrollView.contentInset = edgeInsets;
    self.webView.scrollView.scrollIndicatorInsets = edgeInsets;
    self.tableView.contentInset = edgeInsets;
    self.tableView.scrollIndicatorInsets = edgeInsets;
}

- (void)nextFile
{
    self.currentLanguage = [self randomLanguage];
    [[[[[[[[self.gitHubAPISessionManager randomRepositoryWithLanguage:self.currentLanguage
                                                             token:self.token] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            return [BFTask cancelledTask];
        }
        NSDictionary *responseDictionary = task.result;
        NSArray *items = [responseDictionary objectForKey:@"items"];
        NSArray *repositories = [self.translatorHelper translateRepositoriesWithJSONArray:items];
        return [BFTask taskWithResult:repositories[arc4random_uniform((int32_t)5)]];
    }] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            //TODO: Handle error;
            NSLog(@"%@", [task.error localizedDescription]);
            if (task.error.domain == AFURLResponseSerializationErrorDomain &&
                task.error.code == -1011) {
                if (!self.isPooling) {
                    [self poolRate];
                }
            }
            return [BFTask cancelledTask];
        }
        self.currentRepository = task.result;
        return [self.gitHubAPISessionManager randomFileWithLanguage:self.currentLanguage
                                                         repository:self.currentRepository
                                                              token:self.token];
    }] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            return [BFTask cancelledTask];
        }
        NSDictionary *responseDictionary = (NSDictionary *)task.result;
        NSArray *items = [responseDictionary objectForKey:@"items"];
        NSArray *files = [self.translatorHelper translateFilesWithJSONArray:items];
        if (files.count == 0) {
            return [BFTask taskWithError:[NSError bab_fileNotFound]];
        } else {
            return [BFTask taskWithResult:files[arc4random_uniform((int32_t)files.count)]];
        }
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
            return [BFTask cancelledTask];
        }
        if (task.isCancelled) {
            return [BFTask cancelledTask];
        }
        self.currentFile = task.result;
        return [self.gitHubAPISessionManager blobWithRepository:self.currentRepository
                                                           file:self.currentFile
                                                          token:self.token];
    }] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            return [BFTask cancelledTask];
        }
        NSDictionary *responseDictionary = (NSDictionary *)task.result;
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:responseDictionary[@"content"]
                                                                  options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSString *decodedString = [[NSString alloc] initWithData:decodedData
                                                        encoding:NSUTF8StringEncoding];
        return [BFTask taskWithResult:decodedString];
    }] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            //TODO: Handle error;
            NSLog(@"%@", [task.error localizedDescription]);
            return [BFTask cancelledTask];
        }
        if (task.isCancelled) {
            return [BFTask cancelledTask];
        }
        NSString *htmlFilePath = [[NSBundle mainBundle] pathForResource:@"index"
                                                                 ofType:@"html"
                                                            inDirectory:@"/WebRoot"];
        NSString* htmlString = [NSString stringWithContentsOfFile:htmlFilePath
                                                         encoding:NSUTF8StringEncoding
                                                            error:nil];
        return [BFTask taskWithResult:[[htmlString stringByReplacingOccurrencesOfString:@"BABEL_CODE_PLACEHOLDER"
                                                                            withString:task.result]
                                       stringByReplacingOccurrencesOfString:@"BABEL_LANGUAGE_PLACEHOLDER"
                                       withString:self.currentLanguage.css]];
    }] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        if (task.error) {
            //TODO: Handle error;
            NSLog(@"%@", [task.error localizedDescription]);
        }
        if (!task.isCancelled) {
            [self.webView loadHTMLString:task.result
                                 baseURL:[NSURL fileURLWithPath:
                                          [NSString stringWithFormat:@"%@/WebRoot/",
                                           [[NSBundle mainBundle] bundlePath]]]];
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
    return self.languages[arc4random_uniform((int32_t)self.languages.count)];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.isPooling) {
        [self stopPool];
    }
    if (self.webView.alpha == 0.0f) {
        [self setupGuess];
        [UIView animateWithDuration:0.5f
                         animations:^{
                             self.webView.alpha = 1.0f;
                         }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isHintEnabled) {
        return self.hintLanguages.count;
    } else {
        return self.languages.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:BABLanguageTableViewCell
                                                                      forIndexPath:indexPath];
    BABLanguage *language;
    if (self.isHintEnabled) {
       language = self.hintLanguages[indexPath.row];
    } else {
        language = self.languages[indexPath.row];
    }
    tableViewCell.textLabel.text = language.name;
    return tableViewCell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath
                                  animated:YES];
    BABLanguage *language;
    if (self.isHintEnabled) {
        language = self.hintLanguages[indexPath.row];
    } else {
        language = self.languages[indexPath.row];
    }
    if ([language.index unsignedIntegerValue] == [self.currentLanguage.index unsignedIntegerValue]) {
        self.points++;
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"Correct!\nFile: %@\nRepository:%@",
                                              self.currentFile.name,
                                              self.currentRepository.name]];
    } else {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Incorrect!\nLanguage:%@\nFile: %@\nRepository:%@",
                                            self.currentLanguage.name,
                                            self.currentFile.name,
                                            self.currentRepository.name]];
    }
    self.hintEnabled = NO;
    [self setupLoadingIndicator];
    [UIView animateWithDuration:0.5f
                     animations:^{
                         self.tableView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self.tableView reloadData];
                             [self.tableView setContentOffset:CGPointMake(0, 0 - self.tableView.contentInset.top)
                                                     animated:NO];
                             [self nextFile];
                         }
                     }];
}

@end
