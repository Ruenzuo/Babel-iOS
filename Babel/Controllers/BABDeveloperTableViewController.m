//
//  BABDeveloperTableViewController.m
//  Babel
//
//  Created by Renzo Crisostomo on 17/08/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import "BABDeveloperTableViewController.h"

@interface BABDeveloperTableViewController () <MFMailComposeViewControllerDelegate>

- (void)follow;
- (void)email;
- (void)setupInfoTableViewCell:(UITableViewCell *)tableViewCell
                  forIndexPath:(NSIndexPath *)indexPath;

@end

@implementation BABDeveloperTableViewController

static NSString * const BABDeveloperTableViewCell = @"BABDeveloperTableViewCell";
static NSString * const BABBlogDeveloperTableViewCellTitle = @"Blog";
static NSString * const BABBlogDeveloperTableViewCellDetails = @"ruenzuo.github.io";
static NSString * const BABTwitterAccountDeveloperTableViewCellDetails = @"@Ruenzuo";
static NSString * const BABGitHubAccountDeveloperTableViewCellDetails = @"Ruenzuo";
static NSString * const BABNameDeveloperTableViewCellDetails = @"Renzo Crisóstomo";
static NSString * const BABEmailDeveloper = @"renzo.crisostomo@me.com";
static NSString * const BABURLBlogDeveloper = @"http://ruenzuo.github.io/";
static NSString * const BABURLGitHubProfileDeveloper = @"https://github.com/ruenzuo";

#pragma mark - Private Methods

- (void)follow
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore
     requestAccessToAccountsWithType:accountType
     options:nil
     completion:^(BOOL granted, NSError *error) {
         if(granted) {
             NSArray *accounts = [accountStore accountsWithAccountType:accountType];
             if ([accounts count] > 0) {
                 ACAccount *twitterAccount = [accounts objectAtIndex:0];
                 NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
                 [parameters setValue:@"ruenzuo" forKey:@"screen_name"];
                 [parameters setValue:@"true" forKey:@"follow"];
                 SLRequest *postRequest = [SLRequest
                                           requestForServiceType:SLServiceTypeTwitter
                                           requestMethod:SLRequestMethodPOST
                                           URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"]
                                           parameters:parameters];
                 [postRequest setAccount:twitterAccount];
                 [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:true];
                 [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:false];
                     @weakify(self);
                     dispatch_async(dispatch_get_main_queue(), ^{
                         @strongify(self);
                         if ([urlResponse statusCode] == 200) {
                             [TSMessage
                              showNotificationInViewController:self
                              title:NSLocalizedString(@"everywhere.success.string", nil)
                              subtitle:NSLocalizedString(@"developer-view-controller.thanks.message.subtitle.when-follow-succeed", nil)
                              type:TSMessageNotificationTypeSuccess
                              duration:3.0f
                              canBeDismissedByUser:YES];
                         }
                         else {
                             [TSMessage
                              showNotificationInViewController:self
                              title:NSLocalizedString(@"everywhere.error.string", nil)
                              subtitle:NSLocalizedString(@"everywhere.retry-message.string", nil)
                              type:TSMessageNotificationTypeError
                              duration:3.0f
                              canBeDismissedByUser:YES];
                         }
                     });
                 }];
             }
             else {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [TSMessage
                      showNotificationInViewController:self.navigationController
                      title:NSLocalizedString(@"everywhere.error.string", nil)
                      subtitle:[NSString localizedStringWithFormat:NSLocalizedString(@"everywhere.error.message.subtitle.when-service-share-fails", nil), BABTwitterSevice]
                      type:TSMessageNotificationTypeError
                      duration:3.0f
                      canBeDismissedByUser:YES];
                 });
             }
         }
     }];
}

- (void)email
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
        [controller setToRecipients:@[BABEmailDeveloper]];
        [controller setMailComposeDelegate:self];
        [self presentViewController:controller
                           animated:true
                         completion:nil];
    }
    else {
        [TSMessage
         showNotificationInViewController:self
         title:NSLocalizedString(@"everywhere.error.string", nil)
         subtitle:[NSString localizedStringWithFormat:NSLocalizedString(@"everywhere.error.message.subtitle.when-service-share-fails", nil), NSLocalizedString(@"everywhere.email-service.string", nil)]
         type:TSMessageNotificationTypeError
         duration:3.0f
         canBeDismissedByUser:YES];
    }
}

- (void)setupInfoTableViewCell:(UITableViewCell *)tableViewCell
                  forIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0: {
            tableViewCell.textLabel.text = NSLocalizedString(@"developer-view-controller.name.table-view-cell.text-label.text", nil);
            tableViewCell.detailTextLabel.text = BABNameDeveloperTableViewCellDetails;
            break;
        }
        case 1: {
            tableViewCell.textLabel.text = BABTwitterSevice;
            tableViewCell.detailTextLabel.text = BABTwitterAccountDeveloperTableViewCellDetails;
            break;
        }
        case 2: {
            tableViewCell.textLabel.text = BABGitHubSevice;
            tableViewCell.detailTextLabel.text = BABGitHubAccountDeveloperTableViewCellDetails;
            break;
        }
        case 3: {
            tableViewCell.textLabel.text = BABBlogDeveloperTableViewCellTitle;
            tableViewCell.detailTextLabel.text = BABBlogDeveloperTableViewCellDetails;
            break;
        }
        case 4: {
            tableViewCell.textLabel.text = NSLocalizedString(@"developer-view-controller.contact.table-view-cell.text-label.text", nil);
            tableViewCell.detailTextLabel.text = BABEmailDeveloper;
            break;
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:BABDeveloperTableViewCell
                                                                     forIndexPath:indexPath];
    [self setupInfoTableViewCell:tableViewCell
                    forIndexPath:indexPath];
    return tableViewCell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath
                                  animated:YES];
    switch (indexPath.row) {
        case 1:
            [self follow];
            break;
        case 2:
            [[UIApplication sharedApplication]
             openURL:[NSURL URLWithString:BABURLGitHubProfileDeveloper]];
            break;
        case 3:
            [[UIApplication sharedApplication]
             openURL:[NSURL URLWithString:BABURLBlogDeveloper]];
            break;
        case 4:
            [self email];
            break;
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultSent) {
        [TSMessage
         showNotificationInViewController:self
         title:NSLocalizedString(@"everywhere.success.string", nil)
         subtitle:NSLocalizedString(@"developer-view-controller.thanks.message.subtitle.when-email-succeed", nil)
         type:TSMessageNotificationTypeSuccess
         duration:3.0f
         canBeDismissedByUser:YES];
    }
    else if (result == MFMailComposeResultFailed) {
        [TSMessage
         showNotificationInViewController:self
         title:NSLocalizedString(@"everywhere.error.string", nil)
         subtitle:NSLocalizedString(@"everywhere.retry-message.string", nil)
         type:TSMessageNotificationTypeError
         duration:3.0f
         canBeDismissedByUser:YES];
    }
    [self dismissViewControllerAnimated:true
                             completion:nil];
}

@end
