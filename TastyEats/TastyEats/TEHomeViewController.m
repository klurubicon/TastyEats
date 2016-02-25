//
//  TEHomeViewController.m
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TEHomeViewController.h"
#import "TESettingsActionSheetDelegate.h"
#import "TESettingsButtonItem.h"
#import "TEFindFriendsViewController.h"
#import "TEAccountViewController.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"

@interface TEHomeViewController () <UIActionSheetDelegate>
@property (nonatomic, strong) TESettingsActionSheetDelegate *settingsActionSheetDelegate;
@property (nonatomic, strong) UINavigationController *presentingAccountNavController;
@property (nonatomic, strong) UINavigationController *presentingFriendNavController;
@property (nonatomic, strong) UIView *blankTimelineView;
@end

@implementation TEHomeViewController
@synthesize firstLaunch;
@synthesize settingsActionSheetDelegate;
@synthesize blankTimelineView;


#pragma mark - UIViewController

- (UINavigationController *)presentingAccountNavController {
    if (!_presentingAccountNavController) {
        
        TEAccountViewController *accountViewController = [[TEAccountViewController alloc] initWithUser:[PFUser currentUser]];
        _presentingAccountNavController = [[UINavigationController alloc] initWithRootViewController:accountViewController];
    }
    return _presentingAccountNavController;
}

- (UINavigationController *)presentingFriendNavController {
    if (!_presentingFriendNavController) {
        
        TEFindFriendsViewController *findFriendsVC = [[TEFindFriendsViewController alloc] init];
        _presentingFriendNavController = [[UINavigationController alloc] initWithRootViewController:findFriendsVC];
    }
    return _presentingFriendNavController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBar.png"]];

    self.navigationItem.rightBarButtonItem = [[TESettingsButtonItem alloc] initWithTarget:self action:@selector(settingsButtonAction:)];
    
    self.blankTimelineView = [[UIView alloc] initWithFrame:self.tableView.bounds];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake( 33.0f, 96.0f, 253.0f, 173.0f);
    [button setBackgroundImage:[UIImage imageNamed:@"HomeTimelineBlank.png"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(inviteFriendsButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.blankTimelineView addSubview:button];
}


#pragma mark - PFQueryTableViewController

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];

    if (self.objects.count == 0 && ![[self queryForTable] hasCachedResult] & !self.firstLaunch) {
        self.tableView.scrollEnabled = NO;
        
        if (!self.blankTimelineView.superview) {
            self.blankTimelineView.alpha = 0.0f;
            self.tableView.tableHeaderView = self.blankTimelineView;
            
            [UIView animateWithDuration:0.200f animations:^{
                self.blankTimelineView.alpha = 1.0f;
            }];
        }
    } else {
        self.tableView.tableHeaderView = nil;
        self.tableView.scrollEnabled = YES;
    }    
}


#pragma mark - ()

- (void)settingsButtonAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"My Profile",@"Log Out", nil];
    
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}


- (void)inviteFriendsButtonAction:(id)sender {
    TEFindFriendsViewController *detailViewController = [[TEFindFriendsViewController alloc] init];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0: {
            [self presentViewController:self.presentingAccountNavController animated:YES completion:nil];
            
            break;
        }
        
            
        case 1: {
            // Log out user and present the login view controller
            [(AppDelegate *)[[UIApplication sharedApplication] delegate] logOut];
            break;
        }
            
        default:
            break;
    }
}

@end
