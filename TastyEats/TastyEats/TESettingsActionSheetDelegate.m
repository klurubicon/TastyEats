//
//  TESettingsActionSheetDelegate.m
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TESettingsActionSheetDelegate.h"
#import "TEFindFriendsViewController.h"
#import "TEAccountViewController.h"
#import "AppDelegate.h"

// ActionSheet button indexes
typedef enum {
	kTESettingsProfile = 0,
	kTESettingsFindFriends,
	kTESettingsLogout,
    kTESettingsNumberOfButtons
} kTESettingsActionSheetButtons;
 
@implementation TESettingsActionSheetDelegate

@synthesize navController;

#pragma mark - Initialization

- (id)initWithNavigationController:(UINavigationController *)navigationController {
    self = [super init];
    if (self) {
        navController = navigationController;
    }
    return self;
}

- (id)init {
    return [self initWithNavigationController:nil];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (!self.navController) {
        [NSException raise:NSInvalidArgumentException format:@"navController cannot be nil"];
        return;
    }
    
    switch ((kTESettingsActionSheetButtons)buttonIndex) {
        case kTESettingsProfile:
        {
            TEAccountViewController *accountViewController = [[TEAccountViewController alloc] initWithUser:[PFUser currentUser]];
            [navController pushViewController:accountViewController animated:YES];
            break;
        }
        
        case kTESettingsFindFriends:
        {
            TEFindFriendsViewController *findFriendsVC = [[TEFindFriendsViewController alloc] init];
            [navController pushViewController:findFriendsVC animated:YES];
            break;
        }
         
        case kTESettingsLogout:
            // Log out user and present the login view controller
            [(AppDelegate *)[[UIApplication sharedApplication] delegate] logOut];
            break;
        default:
            break;
    }
}

@end
