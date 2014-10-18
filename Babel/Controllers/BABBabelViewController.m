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
#import "BABConfigurationHelper.h"
#import "NSMutableArray+BABShuffle.h"
#import "BABGameCenterManager.h"

@interface BABBabelViewController () <UIWebViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, assign, getter = isPooling) BOOL pooling;
@property (nonatomic, strong) MSWeakTimer *timer;
@property (nonatomic, weak) IBOutlet UIToolbar *toolBar;
@property (nonatomic, weak) FBShimmeringView *titleShimmeringView;
@property (nonatomic, assign, getter = isHintEnabled) BOOL hintEnabled;
@property (nonatomic, assign) NSUInteger score;
@property (nonatomic, assign) NSUInteger remainingHints;
@property (nonatomic, assign) NSUInteger remainingSkips;
@property (nonatomic, strong) BABLanguage *currentLanguage;
@property (nonatomic, strong) BABRepository *currentRepository;
@property (nonatomic, strong) BABFile *currentFile;

- (void)nextFile;
- (void)skip:(id)sender;
- (void)guess:(id)sender;
- (void)code:(id)sender;
- (void)hint:(id)sender;
- (void)setupView;
- (void)setupLoadingIndicator;
- (void)setupGuess;
- (void)poolRate;
- (void)stopPool;
- (void)prepareHintLanguages;

@end

@implementation BABBabelViewController

static NSString * const BABLanguageTableViewCell = @"BABLanguageTableViewCell";

#pragma mark - View controller life cycle

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.pooling = false;
        self.score = 0;
        self.remainingHints = 5;
        self.remainingSkips = 5;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupView];
    [self setupLoadingIndicator];
    [self nextFile];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.screenName = @"Babel Screen";
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
             } else if (task.error.code == BABErrorCodeFileNotFound) {
                 DDLogInfo(@"Looping with file not found error.");
                 [self nextFile];
                 return nil;
             } else if (task.error.code == BABErrorCodeSringDecodingFailed) {
                 DDLogInfo(@"Looping with string decoding failed error.");
                 [self nextFile];
                 return nil;
             }else {
                 DDLogError(@"Looping with error: %@", [task.error description]);
                 [self nextFile];
             }
         } else {
             if (self.isPooling) {
                 [self stopPool];
             }
             NSDictionary *result = task.result;
             self.currentLanguage = result[@"Language"];
             self.currentRepository = result[@"Repository"];
             self.currentFile = result[@"File"];
             DDLogInfo(@"Loading file:");
             DDLogInfo(@"Current language: %@", self.currentLanguage.name);
             DDLogInfo(@"Current repository: %@", self.currentRepository.name);
             DDLogInfo(@"Current file: %@", self.currentFile.name);
             [self.webView loadHTMLString:result[@"HTML"]
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
    [TSMessage
     showNotificationInViewController:self
     title:NSLocalizedString(@"babel-view-controller.skipped.message.title", nil)
     subtitle:[NSString localizedStringWithFormat:NSLocalizedString(@"babel-view-controller.skipped.message.subtitle", nil),
               self.currentLanguage.name,
               self.currentFile.name,
               self.currentRepository.name]
     type:TSMessageNotificationTypeMessage
     duration:3.0f
     canBeDismissedByUser:YES];
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
    UIBarButtonItem *code = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"babel-view-controller.code.bar-button-item.title", nil)
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(code:)];
    [self.navigationItem setRightBarButtonItem:code
                                      animated:YES];
    if (!self.isHintEnabled && self.remainingHints > 0) {
        UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
        UIBarButtonItem *hint = [[UIBarButtonItem alloc] initWithTitle:[NSString localizedStringWithFormat:NSLocalizedString(@"babel-view-controller.hint.bar-button-item.title", nil), (unsigned long)self.remainingHints]
                                                                 style:UIBarButtonItemStylePlain
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
    UIBarButtonItem *guess = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"babel-view-controller.guess.bar-button-item.title", nil)
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(guess:)];
    [self.navigationItem setRightBarButtonItem:guess
                                      animated:YES];
    if (!self.isHintEnabled && self.remainingSkips > 0) {
        UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
        UIBarButtonItem *skip = [[UIBarButtonItem alloc] initWithTitle:[NSString localizedStringWithFormat:NSLocalizedString(@"babel-view-controller.skip.bar-button-item.title", nil), (unsigned long)self.remainingSkips]
                                                                 style:UIBarButtonItemStylePlain
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
    [self prepareHintLanguages];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationFade];
}

- (void)setupView
{
    FBShimmeringView *shimmeringView = [[FBShimmeringView alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
    [self.navigationItem setTitleView:shimmeringView];
    self.titleShimmeringView = shimmeringView;
    UILabel *loadingLabel = [[UILabel alloc] initWithFrame:shimmeringView.bounds];
    loadingLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    loadingLabel.textAlignment = NSTextAlignmentCenter;
    loadingLabel.text = @"Babel";
    shimmeringView.contentView = loadingLabel;
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
    UIBarButtonItem *guess = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"babel-view-controller.guess.bar-button-item.title", nil)
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(guess:)];
    [self.navigationItem setRightBarButtonItem:guess
                                      animated:YES];
    if (self.remainingSkips > 0) {
        UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
        UIBarButtonItem *skip = [[UIBarButtonItem alloc] initWithTitle:[NSString localizedStringWithFormat:NSLocalizedString(@"babel-view-controller.skip.bar-button-item.title", nil), (unsigned long)self.remainingSkips]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(skip:)];
        [self.toolBar setItems:@[separator, skip]
                      animated:YES];
    }
    self.titleShimmeringView.shimmering = NO;
}

- (void)poolRate
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"babel-view-controller.pooling.progress-hud.status", nil)
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

- (void)prepareHintLanguages
{
    [self.babelManager.hintLanguages removeAllObjects];
    [self.babelManager.hintLanguages addObject:self.currentLanguage];
    BOOL finished = NO;
    do {
        int randomIndex = arc4random_uniform((int32_t)self.babelManager.languages.count);
        if (randomIndex != [self.currentLanguage.index intValue]) {
            BOOL found = NO;
            for (BABLanguage *language in self.babelManager.hintLanguages) {
                if (randomIndex == [language.index intValue]) {
                    found = YES;
                }
            }
            if (!found) {
                [self.babelManager.hintLanguages addObject:self.babelManager.languages[randomIndex]];
            }
        }
        if (self.babelManager.hintLanguages.count >= [self.babelManager maxHintForCurrentDifficulty]) {
            finished = YES;
        }
    } while (!finished);
    [self.babelManager.hintLanguages bab_shuffle];
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
    if ([language.index unsignedIntegerValue] == [self.currentLanguage.index unsignedIntegerValue]) {
        self.score++;
        [TSMessage
         showNotificationInViewController:self
         title:NSLocalizedString(@"babel-view-controller.right.message.title", nil)
         subtitle:[NSString localizedStringWithFormat:NSLocalizedString(@"babel-view-controller.right.message.subtitle", nil),
                   self.currentFile.name,
                   self.currentRepository.name]
         type:TSMessageNotificationTypeSuccess
         duration:3.0f
         canBeDismissedByUser:YES];
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
        [self.delegate controllerDidFinishWithScore:self.score
                                  forDifficultyMode:self.babelManager.difficultyMode
                                           withInfo:[NSString localizedStringWithFormat:NSLocalizedString(@"babel-view-controller.wrong.message.subtitle", nil),
                                                     self.currentLanguage.name,
                                                     self.currentFile.name,
                                                     self.currentRepository.name]];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
