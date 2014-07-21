//
//  BABOAuthViewController.h
//  Babel
//
//  Created by Renzo Crisostomo on 21/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BABOAuthViewControllerDelegate <NSObject>
@required
- (void)authViewControllerDidFinishAuthenticationWithToken:(NSString *)token
                                                     error:(NSError *)error;
@end

@interface BABOAuthViewController : UIViewController

@property (nonatomic, weak) id<BABOAuthViewControllerDelegate> delegate;

@end
