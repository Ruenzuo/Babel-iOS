//
//  BABBabelViewController.m
//  Babel
//
//  Created by Renzo Crisostomo on 23/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABBabelViewController.h"
#import "BABBabelManager.h"
#import "BABLanguage.h"
#import "BABRepository.h"
#import "BABFile.h"

@interface BABBabelViewController () <UIWebViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, assign, getter = isPooling) BOOL pooling;
@property (nonatomic, strong) MSWeakTimer *timer;
@property (nonatomic, weak) IBOutlet UIToolbar *toolBar;
@property (nonatomic, weak) FBShimmeringView *titleShimmeringView;
@property (nonatomic, assign, getter = isHintEnabled) BOOL hintEnabled;
@property (nonatomic, assign) NSUInteger points;
@property (nonatomic, assign) NSUInteger remainingHints;
@property (nonatomic, assign) NSUInteger remainingSkips;

- (void)nextFile;
- (IBAction)skip:(id)sender;
- (IBAction)guess:(id)sender;
- (void)code:(id)sender;
- (void)hint:(id)sender;
- (void)setupTitle;
- (void)setupInsets;
- (void)setupLoadingIndicator;
- (void)setupGuess;
- (void)poolRate;
- (void)stopPool;

@end

@implementation BABBabelViewController

NSString * const BABLanguageTableViewCell = @"BABLanguageTableViewCell";

#pragma mark - View controller life cycle

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.pooling = false;
        self.points = 0;
        self.remainingHints = 5;
        self.remainingSkips = 5;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTitle];
    [self setupInsets];
    [self setupLoadingIndicator];
    [self nextFile];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Private Methods

- (void)nextFile
{
    @weakify(self);
    
    DDLogDebug(@"Next file loading");
    [[self.babelManager loadNext]
     continueWithExecutor:[BFExecutor mainThreadExecutor]
     withBlock:^id(BFTask *task) {
         
         @strongify(self);
         
         DDLogDebug(@"Load next done.");
         if (task.error) {
             if (task.error.code == BABErrorCodeRateLimitReached) {
                 DDLogError(@"Rate limit reached");
                 if (!self.isPooling) {
                     [self poolRate];
                 }
             } else if (task.error.code == BABErrorCodeFileNotFound ||
                        task.error.code == BABErrorCodeSringDecodingFailed) {
                 DDLogInfo(@"Looping with:");
                 DDLogInfo(@"Current language: %@", self.babelManager.currentLanguage.name);
                 DDLogInfo(@"Current repository: %@", self.babelManager.currentRepository.name);
                 DDLogInfo(@"Current file: %@", self.babelManager.currentFile.name);
                 [self nextFile];
                 return nil;
             } else {
                 DDLogError(@"%@", [task.error description]);
                 DDLogInfo(@"Looping.");
                 [self nextFile];
             }
         } else {
             if (self.isPooling) {
                 [self stopPool];
             }
             DDLogInfo(@"Loading file:");
             DDLogInfo(@"Current language: %@", self.babelManager.currentLanguage.name);
             DDLogInfo(@"Current repository: %@", self.babelManager.currentRepository.name);
             DDLogInfo(@"Current file: %@", self.babelManager.currentFile.name);
             [self.webView loadHTMLString:task.result
                                  baseURL:[NSURL fileURLWithPath:
                                           [NSString stringWithFormat:@"%@/WebRoot/",
                                            [[NSBundle mainBundle] bundlePath]]]];
             
         }
         return nil;
     }];
}

- (IBAction)skip:(id)sender
{
    --self.remainingSkips;
    [self setupLoadingIndicator];
    [SVProgressHUD showImage:[UIImage imageNamed:@"Info"]
                      status:[NSString stringWithFormat:@"Skipped:\nLanguage:%@\nFile: %@\nRepository:%@",
                                        self.babelManager.currentLanguage.name,
                                        self.babelManager.currentFile.name,
                                        self.babelManager.currentRepository.name]];
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
    if (!self.isHintEnabled && self.remainingHints > 0) {
        UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
        UIBarButtonItem *hint = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Hint (%lu)", (unsigned long)self.remainingHints]
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
    if (!self.isHintEnabled && self.remainingSkips > 0) {
        UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
        UIBarButtonItem *skip = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Skip (%lu)", (unsigned long)self.remainingSkips]
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
    --self.remainingHints;
    [self.toolBar setItems:@[]
                  animated:YES];
    [self.babelManager prepareHintLanguages];
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

- (void)setupInsets
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake([UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height, 0, self.toolBar.frame.size.height, 0);
    self.webView.scrollView.contentInset = edgeInsets;
    self.webView.scrollView.scrollIndicatorInsets = edgeInsets;
    self.tableView.contentInset = edgeInsets;
    self.tableView.scrollIndicatorInsets = edgeInsets;
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
    if (self.remainingSkips > 0) {
        UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
        UIBarButtonItem *skip = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Skip (%lu)", (unsigned long)self.remainingSkips]
                                                                 style:UIBarButtonItemStyleBordered
                                                                target:self
                                                                action:@selector(skip:)];
        [self.toolBar setItems:@[separator, skip]
                      animated:YES];
    }
    self.titleShimmeringView.shimmering = NO;
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

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DDLogError(@"%@", [error localizedDescription]);
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isHintEnabled) {
        return self.babelManager.hintLanguages.count;
    } else {
        return self.babelManager.languages.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:BABLanguageTableViewCell
                                                                      forIndexPath:indexPath];
    BABLanguage *language;
    if (self.isHintEnabled) {
       language = self.babelManager.hintLanguages[indexPath.row];
    } else {
        language = self.babelManager.languages[indexPath.row];
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
        language = self.babelManager.hintLanguages[indexPath.row];
    } else {
        language = self.babelManager.languages[indexPath.row];
    }
    if ([language.index unsignedIntegerValue] == [self.babelManager.currentLanguage.index unsignedIntegerValue]) {
        self.points++;
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"Correct!\nFile: %@\nRepository:%@",
                                              self.babelManager.currentFile.name,
                                              self.babelManager.currentRepository.name]];
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
    } else {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Incorrect!\nLanguage:%@\nFile: %@\nRepository:%@\nTotal points: %lu",
                                            self.babelManager.currentLanguage.name,
                                            self.babelManager.currentFile.name,
                                            self.babelManager.currentRepository.name,
                                            (unsigned long)self.points]];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
