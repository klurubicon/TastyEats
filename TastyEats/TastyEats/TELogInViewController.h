//
//  TELogInViewController.h
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import <FBSDKLoginKit/FBSDKLoginKit.h>

@protocol TELogInViewControllerDelegate;

@interface TELogInViewController : UIViewController <FBSDKLoginButtonDelegate>

@property (nonatomic, assign) id<TELogInViewControllerDelegate> delegate;

@end

@protocol TELogInViewControllerDelegate <NSObject>

- (void)logInViewControllerDidLogUserIn:(TELogInViewController *)logInViewController;

@end