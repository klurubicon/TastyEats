//
//  TEActivityFeedViewController.m
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TEActivityFeedViewController.h"
#import "TESettingsActionSheetDelegate.h"
#import "TEActivityCell.h"
#import "TEAccountViewController.h"
#import "TEPhotoDetailsViewController.h"
#import "TEBaseTextCell.h"
#import "TELoadMoreCell.h"
#import "TESettingsButtonItem.h"
#import "TEFindFriendsViewController.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"

@interface TEActivityFeedViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) TESettingsActionSheetDelegate *settingsActionSheetDelegate;
@property (nonatomic, strong) UINavigationController *presentingAccountNavController;
@property (nonatomic, strong) UINavigationController *presentingFriendNavController;
@property (nonatomic, strong) NSDate *lastRefresh;
@property (nonatomic, strong) UIView *blankTimelineView;
@end

@implementation TEActivityFeedViewController

@synthesize settingsActionSheetDelegate;
@synthesize lastRefresh;
@synthesize blankTimelineView;

#pragma mark - Initialization

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TEAppDelegateApplicationDidReceiveRemoteNotification object:nil];    
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // The className to query on
        self.parseClassName = kTEActivityClassKey;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;

        // The number of objects to show per page
        self.objectsPerPage = 15;

        // The Loading text clashes with the dark TastyEats design
        self.loadingViewEnabled = NO;
    }
    return self;
}


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
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];

    [super viewDidLoad];
    
    UIView *texturedBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    [texturedBackgroundView setBackgroundColor:[UIColor blackColor]];
    self.tableView.backgroundView = texturedBackgroundView;

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBar.png"]];

    // Add Settings button
    self.navigationItem.rightBarButtonItem = [[TESettingsButtonItem alloc] initWithTarget:self action:@selector(settingsButtonAction:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveRemoteNotification:) name:TEAppDelegateApplicationDidReceiveRemoteNotification object:nil];
    
    self.blankTimelineView = [[UIView alloc] initWithFrame:self.tableView.bounds];
    

    lastRefresh = [[NSUserDefaults standardUserDefaults] objectForKey:kTEUserDefaultsActivityFeedViewControllerLastRefreshKey];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.separatorColor = [UIColor colorWithRed:30.0f/255.0f green:30.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) {
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        NSString *activityString = [TEActivityFeedViewController stringForActivityType:(NSString*)[object objectForKey:kTEActivityTypeKey]];

        PFUser *user = (PFUser*)[object objectForKey:kTEActivityFromUserKey];
        NSString *nameString = NSLocalizedString(@"Someone", nil);
        if (user && [user objectForKey:kTEUserDisplayNameKey] && [[user objectForKey:kTEUserDisplayNameKey] length] > 0) {
            nameString = [user objectForKey:kTEUserDisplayNameKey];
        }
        
        return [TEActivityCell heightForCellWithName:nameString contentString:activityString];
    } else {
        return 44.0f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < self.objects.count) {
        PFObject *activity = [self.objects objectAtIndex:indexPath.row];
        if ([activity objectForKey:kTEActivityPhotoKey]) {
            TEPhotoDetailsViewController *detailViewController = [[TEPhotoDetailsViewController alloc] initWithPhoto:[activity objectForKey:kTEActivityPhotoKey]];
            [self.navigationController pushViewController:detailViewController animated:YES];
        } else if ([activity objectForKey:kTEActivityFromUserKey]) {
            TEAccountViewController *detailViewController = [[TEAccountViewController alloc] initWithStyle:UITableViewStylePlain];
            NSLog(@"Presenting account view controller with user: %@", [activity objectForKey:kTEActivityFromUserKey]);
            [detailViewController setUser:[activity objectForKey:kTEActivityFromUserKey]];
            [self.navigationController pushViewController:detailViewController animated:YES];
        }
    } else if (self.paginationEnabled) {
        // load more
        [self loadNextPage];
    }
}

#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    
    if (![PFUser currentUser]) {
        PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
        [query setLimit:0];
        return query;
    }

    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:kTEActivityToUserKey equalTo:[PFUser currentUser]];
    [query whereKey:kTEActivityFromUserKey notEqualTo:[PFUser currentUser]];
    [query whereKeyExists:kTEActivityFromUserKey];
    [query includeKey:kTEActivityFromUserKey];
    [query includeKey:kTEActivityPhotoKey];
    [query orderByDescending:@"createdAt"];

    [query setCachePolicy:kPFCachePolicyNetworkOnly];

    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    //
    // If there is no network connection, we will hit the cache first.
    if (self.objects.count == 0 || ![[UIApplication sharedApplication].delegate performSelector:@selector(isParseReachable)]) {
        [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    }
    
    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];

    lastRefresh = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:lastRefresh forKey:kTEUserDefaultsActivityFeedViewControllerLastRefreshKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if (self.objects.count == 0 && ![[self queryForTable] hasCachedResult]) {
        self.tableView.scrollEnabled = NO;
        self.navigationController.tabBarItem.badgeValue = nil;

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
        
        NSUInteger unreadCount = 0;
        for (PFObject *activity in self.objects) {
            if ([lastRefresh compare:[activity createdAt]] == NSOrderedAscending && ![[activity objectForKey:kTEActivityTypeKey] isEqualToString:kTEActivityTypeJoined]) {
                unreadCount++;
            }
        }
        
        if (unreadCount > 0) {
            self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)unreadCount];
        } else {
            self.navigationController.tabBarItem.badgeValue = nil;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"ActivityCell";

    TEActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TEActivityCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell setDelegate:self];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    [cell setActivity:object];;

    if ([lastRefresh compare:[object createdAt]] == NSOrderedAscending) {
        [cell setIsNew:YES];
    } else {
        [cell setIsNew:NO];
    }

    [cell hideSeparator:(indexPath.row == self.objects.count - 1)];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *LoadMoreCellIdentifier = @"LoadMoreCell";
    
    TELoadMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:LoadMoreCellIdentifier];
    if (!cell) {
        cell = [[TELoadMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadMoreCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.hideSeparatorBottom = YES;
        cell.mainView.backgroundColor = [UIColor clearColor];
   }
    return cell;
}


#pragma mark - TEActivityCellDelegate Methods

- (void)cell:(TEActivityCell *)cellView didTapActivityButton:(PFObject *)activity {    
    // Get image associated with the activity
    PFObject *photo = [activity objectForKey:kTEActivityPhotoKey];
    
    // Push single photo view controller
    TEPhotoDetailsViewController *photoViewController = [[TEPhotoDetailsViewController alloc] initWithPhoto:photo];
    [self.navigationController pushViewController:photoViewController animated:YES];
}

- (void)cell:(TEBaseTextCell *)cellView didTapUserButton:(PFUser *)user {    
    // Push account view controller
    TEAccountViewController *accountViewController = [[TEAccountViewController alloc] initWithStyle:UITableViewStylePlain];
    NSLog(@"Presenting account view controller with user: %@", user);
    [accountViewController setUser:user];
    [self.navigationController pushViewController:accountViewController animated:YES];
}


#pragma mark - TEActivityFeedViewController

+ (NSString *)stringForActivityType:(NSString *)activityType {
    if ([activityType isEqualToString:kTEActivityTypeLike]) {
        return NSLocalizedString(@"liked your photo", nil);
    } else if ([activityType isEqualToString:kTEActivityTypeFollow]) {
        return NSLocalizedString(@"started following you", nil);
    } else if ([activityType isEqualToString:kTEActivityTypeComment]) {
        return NSLocalizedString(@"commented on your photo", nil);
    } else if ([activityType isEqualToString:kTEActivityTypeJoined]) {
        return NSLocalizedString(@"joined TastyEats", nil);
    } else {
        return nil;
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

- (void)applicationDidReceiveRemoteNotification:(NSNotification *)note {
    [self loadObjects];
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
