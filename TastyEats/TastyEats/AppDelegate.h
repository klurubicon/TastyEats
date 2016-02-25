//
//  AppDelegate.h
//  TastyEats
//
//  Created by Kai Lu on 1/15/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TETabBarController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSURLConnectionDataDelegate, UITabBarControllerDelegate>

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, strong) TETabBarController *tabBarController;
@property (nonatomic, strong) UINavigationController *navController;

@property (nonatomic, readonly) int networkStatus;

- (BOOL)isParseReachable;

- (void)presentLoginViewController;
- (void)presentLoginViewController:(BOOL)animated;
- (void)presentTabBarController;

- (void)logOut;

- (void)autoFollowUsers;

@end