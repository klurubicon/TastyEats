//
//  TEFindFriendsViewController.m
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TEFindFriendsViewController.h"
#import "TEProfileImageView.h"
#import "AppDelegate.h"
#import "TELoadMoreCell.h"
#import "TEAccountViewController.h"
#import "MBProgressHUD.h"

typedef enum {
    TEFindFriendsFollowingNone = 0,    // User isn't following anybody in Friends list
    TEFindFriendsFollowingAll,         // User is following all Friends
    TEFindFriendsFollowingSome         // User is following some of their Friends
} TEFindFriendsFollowStatus;

@interface TEFindFriendsViewController ()
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, assign) TEFindFriendsFollowStatus followStatus;
@property (nonatomic, strong) NSString *selectedEmailAddress;
@property (nonatomic, strong) NSMutableDictionary *outstandingFollowQueries;
@property (nonatomic, strong) NSMutableDictionary *outstandingCountQueries;
@end

@implementation TEFindFriendsViewController
@synthesize headerView;
@synthesize followStatus;
@synthesize selectedEmailAddress;
@synthesize outstandingFollowQueries;
@synthesize outstandingCountQueries;
#pragma mark - Initialization

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {

        self.outstandingFollowQueries = [NSMutableDictionary dictionary];
        self.outstandingCountQueries = [NSMutableDictionary dictionary];

        self.selectedEmailAddress = @"";

        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;

        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;

        // The number of objects to show per page
        self.objectsPerPage = 15;

        // Used to determine Follow/Unfollow All button status
        self.followStatus = TEFindFriendsFollowingSome;
    }
    return self;
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor blackColor];

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TitleFindFriends.png"]];
    
    if (self.navigationController.viewControllers[0] == self) {
        UIBarButtonItem *dismissLeftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                                     style:UIBarButtonItemStylePlain
                                                                                    target:self
                                                                                    action:@selector(dismissPresentingViewController)];
        
        self.navigationItem.leftBarButtonItem = dismissLeftBarButtonItem;
    }
    else {
        self.navigationItem.leftBarButtonItem = nil;
    }

    if ([MFMailComposeViewController canSendMail] || [MFMessageComposeViewController canSendText]) {
        self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 67)];
        [self.headerView setBackgroundColor:[UIColor blackColor]];
        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [clearButton setBackgroundColor:[UIColor clearColor]];
        [clearButton addTarget:self action:@selector(inviteFriendsButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [clearButton setFrame:self.headerView.frame];
        [self.headerView addSubview:clearButton];
        NSString *inviteString = NSLocalizedString(@"Invite friends", @"Invite friends");
        CGRect boundingRect = [inviteString boundingRectWithSize:CGSizeMake(310.0f, CGFLOAT_MAX)
                                                         options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:18.0f]}
                                                         context:nil];
        CGSize inviteStringSize = boundingRect.size;

        UILabel *inviteLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, (self.headerView.frame.size.height-inviteStringSize.height)/2, inviteStringSize.width, inviteStringSize.height)];
        [inviteLabel setText:inviteString];
        [inviteLabel setFont:[UIFont boldSystemFontOfSize:18]];
        [inviteLabel setTextColor:[UIColor whiteColor]];
        [inviteLabel setBackgroundColor:[UIColor clearColor]];
        [self.headerView addSubview:inviteLabel];
        [self.tableView setTableHeaderView:self.headerView];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.separatorColor = [UIColor colorWithRed:30.0f/255.0f green:30.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
}

- (void)dismissPresentingViewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) {
        return [TEFindFriendsCell heightForCell];
    } else {
        return 44.0f;
    }
}


#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    // Use cached facebook friend ids
    NSArray *facebookFriends = [[TECache sharedCache] facebookFriends];

    // Query for all friends you have on facebook and who are using the app
    PFQuery *friendsQuery = [PFUser query];
    [friendsQuery whereKey:kTEUserFacebookIDKey containedIn:facebookFriends];


    PFQuery *query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:friendsQuery, nil]];
    query.cachePolicy = kPFCachePolicyNetworkOnly;

    if (self.objects.count == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }

    [query orderByAscending:kTEUserDisplayNameKey];

    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];

    PFQuery *isFollowingQuery = [PFQuery queryWithClassName:kTEActivityClassKey];
    [isFollowingQuery whereKey:kTEActivityFromUserKey equalTo:[PFUser currentUser]];
    [isFollowingQuery whereKey:kTEActivityTypeKey equalTo:kTEActivityTypeFollow];
    [isFollowingQuery whereKey:kTEActivityToUserKey containedIn:self.objects];
    [isFollowingQuery setCachePolicy:kPFCachePolicyNetworkOnly];

    [isFollowingQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            if (number == self.objects.count) {
                self.followStatus = TEFindFriendsFollowingAll;
                [self configureUnfollowAllButton];
                for (PFUser *user in self.objects) {
                    [[TECache sharedCache] setFollowStatus:YES user:user];
                }
            } else if (number == 0) {
                self.followStatus = TEFindFriendsFollowingNone;
                [self configureFollowAllButton];
                for (PFUser *user in self.objects) {
                    [[TECache sharedCache] setFollowStatus:NO user:user];
                }
            } else {
                self.followStatus = TEFindFriendsFollowingSome;
                [self configureFollowAllButton];
            }
        }

        if (self.objects.count == 0) {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }];

    if (self.objects.count == 0) {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *FriendCellIdentifier = @"FriendCell";

    TEFindFriendsCell *cell = [tableView dequeueReusableCellWithIdentifier:FriendCellIdentifier];
    if (cell == nil) {
        cell = [[TEFindFriendsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FriendCellIdentifier];
        [cell setDelegate:self];
    }

    [cell setUser:(PFUser*)object];

    [cell.photoLabel setText:@"0 photos"];

    NSDictionary *attributes = [[TECache sharedCache] attributesForUser:(PFUser *)object];

    if (attributes) {
        // set them now
        NSNumber *number = [[TECache sharedCache] photoCountForUser:(PFUser *)object];
        [cell.photoLabel setText:[NSString stringWithFormat:@"%@ photo%@", number, [number intValue] == 1 ? @"": @"s"]];
    } else {
        @synchronized(self) {
            NSNumber *outstandingCountQueryStatus = [self.outstandingCountQueries objectForKey:indexPath];
            if (!outstandingCountQueryStatus) {
                [self.outstandingCountQueries setObject:[NSNumber numberWithBool:YES] forKey:indexPath];
                PFQuery *photoNumQuery = [PFQuery queryWithClassName:kTEPhotoClassKey];
                [photoNumQuery whereKey:kTEPhotoUserKey equalTo:object];
                [photoNumQuery setCachePolicy:kPFCachePolicyCacheThenNetwork];
                [photoNumQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                    @synchronized(self) {
                        [[TECache sharedCache] setPhotoCount:[NSNumber numberWithInt:number] user:(PFUser *)object];
                        [self.outstandingCountQueries removeObjectForKey:indexPath];
                    }
                    TEFindFriendsCell *actualCell = (TEFindFriendsCell*)[tableView cellForRowAtIndexPath:indexPath];
                    [actualCell.photoLabel setText:[NSString stringWithFormat:@"%d photo%@", number, number == 1 ? @"" : @"s"]];
                }];
            };
        }
    }

    cell.followButton.selected = NO;
    cell.tag = indexPath.row;

    if (self.followStatus == TEFindFriendsFollowingSome) {
        if (attributes) {
            [cell.followButton setSelected:[[TECache sharedCache] followStatusForUser:(PFUser *)object]];
        } else {
            @synchronized(self) {
                NSNumber *outstandingQuery = [self.outstandingFollowQueries objectForKey:indexPath];
                if (!outstandingQuery) {
                    [self.outstandingFollowQueries setObject:[NSNumber numberWithBool:YES] forKey:indexPath];
                    PFQuery *isFollowingQuery = [PFQuery queryWithClassName:kTEActivityClassKey];
                    [isFollowingQuery whereKey:kTEActivityFromUserKey equalTo:[PFUser currentUser]];
                    [isFollowingQuery whereKey:kTEActivityTypeKey equalTo:kTEActivityTypeFollow];
                    [isFollowingQuery whereKey:kTEActivityToUserKey equalTo:object];
                    [isFollowingQuery setCachePolicy:kPFCachePolicyCacheThenNetwork];

                    [isFollowingQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                        @synchronized(self) {
                            [self.outstandingFollowQueries removeObjectForKey:indexPath];
                            [[TECache sharedCache] setFollowStatus:(!error && number > 0) user:(PFUser *)object];
                        }
                        if (cell.tag == indexPath.row) {
                            [cell.followButton setSelected:(!error && number > 0)];
                        }
                    }];
                }
            }
        }
    } else {
        [cell.followButton setSelected:(self.followStatus == TEFindFriendsFollowingAll)];
    }

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *NextPageCellIdentifier = @"NextPageCell";

    TELoadMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:NextPageCellIdentifier];

    if (cell == nil) {
        cell = [[TELoadMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NextPageCellIdentifier];
        [cell.mainView setBackgroundColor:[UIColor blackColor]];
        cell.hideSeparatorBottom = YES;
        cell.hideSeparatorTop = YES;
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


#pragma mark - TEFindFriendsCellDelegate

- (void)cell:(TEFindFriendsCell *)cellView didTapUserButton:(PFUser *)aUser {
    // Push account view controller
    TEAccountViewController *accountViewController = [[TEAccountViewController alloc] initWithStyle:UITableViewStylePlain];
    NSLog(@"Presenting account view controller with user: %@", aUser);
    [accountViewController setUser:aUser];
    [self.navigationController pushViewController:accountViewController animated:YES];
}

- (void)cell:(TEFindFriendsCell *)cellView didTapFollowButton:(PFUser *)aUser {
    [self shouldToggleFollowFriendForCell:cellView];
}


#pragma mark - ABPeoplePickerDelegate

/* Called when the user cancels the address book view controller. We simply dismiss it. */
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/* Called when a member of the address book is selected, we return YES to display the member's details. */
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    return YES;
}

/* Called when the user selects a property of a person in their address book (ex. phone, email, location,...)
   This method will allow them to send a text or email inviting them to TastyEats.  */
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {

    if (property == kABPersonEmailProperty) {

        ABMultiValueRef emailProperty = ABRecordCopyValue(person,property);
        NSString *email = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emailProperty,identifier);
        self.selectedEmailAddress = email;

        if ([MFMailComposeViewController canSendMail] && [MFMessageComposeViewController canSendText]) {
            // ask user
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Invite %@",@""] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email", @"iMessage", nil];
            [actionSheet showFromTabBar:self.tabBarController.tabBar];
        } else if ([MFMailComposeViewController canSendMail]) {
            // go directly to mail
            [self presentMailComposeViewController:email];
        } else if ([MFMessageComposeViewController canSendText]) {
            // go directly to iMessage
            [self presentMessageComposeViewController:email];
        }

    } else if (property == kABPersonPhoneProperty) {
        ABMultiValueRef phoneProperty = ABRecordCopyValue(person,property);
        NSString *phone = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phoneProperty,identifier);

        if ([MFMessageComposeViewController canSendText]) {
            [self presentMessageComposeViewController:phone];
        }
    }

    return NO;
}

#pragma mark - MFMailComposeDelegate

/* Simply dismiss the MFMailComposeViewController when the user sends an email or cancels */
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - MFMessageComposeDelegate

/* Simply dismiss the MFMessageComposeViewController when the user sends a text or cancels */
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }

    if (buttonIndex == 0) {
        [self presentMailComposeViewController:self.selectedEmailAddress];
    } else if (buttonIndex == 1) {
        [self presentMessageComposeViewController:self.selectedEmailAddress];
    }
}

#pragma mark - ()

- (void)backButtonAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)inviteFriendsButtonAction:(id)sender {
    ABPeoplePickerNavigationController *addressBook = [[ABPeoplePickerNavigationController alloc] init];
    addressBook.peoplePickerDelegate = self;

    if ([MFMailComposeViewController canSendMail] && [MFMessageComposeViewController canSendText]) {
        addressBook.displayedProperties = [NSArray arrayWithObjects:[NSNumber numberWithInt:kABPersonEmailProperty], [NSNumber numberWithInt:kABPersonPhoneProperty], nil];
    } else if ([MFMailComposeViewController canSendMail]) {
        addressBook.displayedProperties = [NSArray arrayWithObject:[NSNumber numberWithInt:kABPersonEmailProperty]];
    } else if ([MFMessageComposeViewController canSendText]) {
        addressBook.displayedProperties = [NSArray arrayWithObject:[NSNumber numberWithInt:kABPersonPhoneProperty]];
    }

    [self presentViewController:addressBook animated:YES completion:nil];
}

- (void)followAllFriendsButtonAction:(id)sender {
    [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];

    self.followStatus = TEFindFriendsFollowingAll;
    [self configureUnfollowAllButton];

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Unfollow All" style:UIBarButtonItemStylePlain target:self action:@selector(unfollowAllFriendsButtonAction:)];

        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.objects.count];
        for (int r = 0; r < self.objects.count; r++) {
            PFObject *user = [self.objects objectAtIndex:r];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:r inSection:0];
            TEFindFriendsCell *cell = (TEFindFriendsCell *)[self tableView:self.tableView cellForRowAtIndexPath:indexPath object:user];
            cell.followButton.selected = YES;
            [indexPaths addObject:indexPath];
        }

        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];

        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(followUsersTimerFired:) userInfo:nil repeats:NO];
        [TEUtility followUsersEventually:self.objects block:^(BOOL succeeded, NSError *error) {
            // note -- this block is called once for every user that is followed successfully. We use a timer to only execute the completion block once no more saveEventually blocks have been called in 2 seconds
            [timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:2.0f]];
        }];

    });
}

- (void)unfollowAllFriendsButtonAction:(id)sender {
    [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];

    self.followStatus = TEFindFriendsFollowingNone;
    [self configureFollowAllButton];

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Follow All" style:UIBarButtonItemStylePlain target:self action:@selector(followAllFriendsButtonAction:)];

        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.objects.count];
        for (int r = 0; r < self.objects.count; r++) {
            PFObject *user = [self.objects objectAtIndex:r];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:r inSection:0];
            TEFindFriendsCell *cell = (TEFindFriendsCell *)[self tableView:self.tableView cellForRowAtIndexPath:indexPath object:user];
            cell.followButton.selected = NO;
            [indexPaths addObject:indexPath];
        }

        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];

        [TEUtility unfollowUsersEventually:self.objects];

        [[NSNotificationCenter defaultCenter] postNotificationName:TEUtilityUserFollowingChangedNotification object:nil];
    });

}

- (void)shouldToggleFollowFriendForCell:(TEFindFriendsCell*)cell {
    PFUser *cellUser = cell.user;
    if ([cell.followButton isSelected]) {
        // Unfollow
        cell.followButton.selected = NO;
        [TEUtility unfollowUserEventually:cellUser];
        [[NSNotificationCenter defaultCenter] postNotificationName:TEUtilityUserFollowingChangedNotification object:nil];
    } else {
        // Follow
        cell.followButton.selected = YES;
        [TEUtility followUserEventually:cellUser block:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:TEUtilityUserFollowingChangedNotification object:nil];
            } else {
                cell.followButton.selected = NO;
            }
        }];
    }
}

- (void)configureUnfollowAllButton {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Unfollow All" style:UIBarButtonItemStylePlain target:self action:@selector(unfollowAllFriendsButtonAction:)];
}

- (void)configureFollowAllButton {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Follow All" style:UIBarButtonItemStylePlain target:self action:@selector(followAllFriendsButtonAction:)];
}

- (void)presentMailComposeViewController:(NSString *)recipient {
    // Create the compose email view controller
    MFMailComposeViewController *composeEmailViewController = [[MFMailComposeViewController alloc] init];

    // Set the recipient to the selected email and a default text
    [composeEmailViewController setMailComposeDelegate:self];
    [composeEmailViewController setSubject:@"Join me on TastyEats"];
    [composeEmailViewController setToRecipients:[NSArray arrayWithObjects:recipient, nil]];
    [composeEmailViewController setMessageBody:@"<h2>Share your food pictures.</h2>" isHTML:YES];

    // Dismiss the current modal view controller and display the compose email one.
    // Note that we do not animate them. Doing so would require us to present the compose
    // mail one only *after* the address book is dismissed.
    [self dismissViewControllerAnimated:NO completion:nil];
    [self presentViewController:composeEmailViewController animated:NO completion:nil];
}

- (void)presentMessageComposeViewController:(NSString *)recipient {
    // Create the compose text message view controller
    MFMessageComposeViewController *composeTextViewController = [[MFMessageComposeViewController alloc] init];

    // Send the destination phone number and a default text
    [composeTextViewController setMessageComposeDelegate:self];
    [composeTextViewController setRecipients:[NSArray arrayWithObjects:recipient, nil]];
    [composeTextViewController setBody:@"Check out TastyEats! "];

    // Dismiss the current modal view controller and display the compose text one.
    // See previous use for reason why these are not animated.
    [self dismissViewControllerAnimated:NO completion:nil];
    [self presentViewController:composeTextViewController animated:NO completion:nil];
}

- (void)followUsersTimerFired:(NSTimer *)timer {
    [self.tableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:TEUtilityUserFollowingChangedNotification object:nil];
}

@end
