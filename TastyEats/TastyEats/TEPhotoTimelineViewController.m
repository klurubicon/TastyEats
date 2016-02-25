//
//  TEPhotoTimelineViewController.m
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2014 Parse. All rights reserved.
//

#import "TEPhotoTimelineViewController.h"
#import "TEPhotoCell.h"
#import "TEAccountViewController.h"
#import "TEPhotoDetailsViewController.h"
#import "TEUtility.h"
#import "TELoadMoreCell.h"
#import "AppDelegate.h"

@interface TEPhotoTimelineViewController ()
@property (nonatomic, assign) BOOL shouldReloadOnAppear;
@property (nonatomic, strong) NSMutableSet *reusableSectionHeaderViews;
@property (nonatomic, strong) NSMutableDictionary *outstandingSectionHeaderQueries;
@end

@implementation TEPhotoTimelineViewController
@synthesize reusableSectionHeaderViews;
@synthesize shouldReloadOnAppear;
@synthesize outstandingSectionHeaderQueries;

#pragma mark - Initialization

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TETabBarControllerDidFinishEditingPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TEUtilityUserFollowingChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TEPhotoDetailsViewControllerUserLikedUnlikedPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TEUtilityUserLikedUnlikedPhotoCallbackFinishedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TEPhotoDetailsViewControllerUserCommentedOnPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TEPhotoDetailsViewControllerUserDeletedPhotoNotification object:nil];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        
        self.outstandingSectionHeaderQueries = [NSMutableDictionary dictionary];
        
        // The className to query on
        self.parseClassName = kTEPhotoClassKey;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;

        // Whether the built-in pagination is enabled
        self.paginationEnabled = NO;
        
        // The number of objects to show per page
        // self.objectsPerPage = 10;
        
        // Improve scrolling performance by reusing UITableView section headers
        self.reusableSectionHeaderViews = [NSMutableSet setWithCapacity:3];
        
        // The Loading text clashes with the dark TastyEats design
        self.loadingViewEnabled = NO;

        self.shouldReloadOnAppear = NO;
    }
    return self;
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [super viewDidLoad];
    
    UIView *texturedBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    texturedBackgroundView.backgroundColor = [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
    self.tableView.backgroundView = texturedBackgroundView;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidPublishPhoto:) name:TETabBarControllerDidFinishEditingPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userFollowingChanged:) name:TEUtilityUserFollowingChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidDeletePhoto:) name:TEPhotoDetailsViewControllerUserDeletedPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLikeOrUnlikePhoto:) name:TEPhotoDetailsViewControllerUserLikedUnlikedPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLikeOrUnlikePhoto:) name:TEUtilityUserLikedUnlikedPhotoCallbackFinishedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidCommentOnPhoto:) name:TEPhotoDetailsViewControllerUserCommentedOnPhotoNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.shouldReloadOnAppear) {
        self.shouldReloadOnAppear = NO;
        [self loadObjects];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count * 2 + (self.paginationEnabled ? 1 : 0);
}


#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.paginationEnabled && (self.objects.count * 2) == indexPath.row) {
        // Load More Section
        return 44.0f;
    } else if (indexPath.row % 2 == 0) {
        return 44.0f;
    }
    
    return 320.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (![self objectAtIndexPath:indexPath]) {
        // Load More Cell
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
    
    PFQuery *followingActivitiesQuery = [PFQuery queryWithClassName:kTEActivityClassKey];
    [followingActivitiesQuery whereKey:kTEActivityTypeKey equalTo:kTEActivityTypeFollow];
    [followingActivitiesQuery whereKey:kTEActivityFromUserKey equalTo:[PFUser currentUser]];
    followingActivitiesQuery.cachePolicy = kPFCachePolicyNetworkOnly;
    followingActivitiesQuery.limit = 1000;

    PFQuery *autoFollowUsersQuery = [PFUser query];
    [autoFollowUsersQuery whereKey:kTEUserAutoFollowKey equalTo:@YES];

    PFQuery *photosFromFollowedUsersQuery = [PFQuery queryWithClassName:self.parseClassName];
    [photosFromFollowedUsersQuery whereKey:kTEPhotoUserKey matchesKey:kTEActivityToUserKey inQuery:followingActivitiesQuery];
    [photosFromFollowedUsersQuery whereKeyExists:kTEPhotoPictureKey];

    PFQuery *photosFromCurrentUserQuery = [PFQuery queryWithClassName:self.parseClassName];
    [photosFromCurrentUserQuery whereKey:kTEPhotoUserKey equalTo:[PFUser currentUser]];
    [photosFromCurrentUserQuery whereKeyExists:kTEPhotoPictureKey];

    PFQuery *query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:photosFromFollowedUsersQuery, photosFromCurrentUserQuery, nil]];
    [query setLimit:30];
    [query includeKey:kTEPhotoUserKey];
    [query orderByDescending:@"createdAt"];

    // A pull-to-refresh should always trigger a network request.
    [query setCachePolicy:kPFCachePolicyNetworkOnly];

    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    //
    // If there is no network connection, we will hit the cache first.
    if (self.objects.count == 0 || ![[UIApplication sharedApplication].delegate performSelector:@selector(isParseReachable)]) {
        [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    }

    /*
     This query will result in an error if the schema hasn't been set beforehand. While Parse usually handles this automatically, this is not the case for a compound query such as this one. The error thrown is:
     
     Error: bad special key: __type
     
     To set up your schema, you may post a photo with a caption. This will automatically set up the Photo and Activity classes needed by this query.
     
     You may also use the Data Browser at Parse.com to set up your classes in the following manner.
     
     Create a User class: "User" (if it does not exist)
     
     Create a Custom class: "Activity"
     - Add a column of type pointer to "User", named "fromUser"
     - Add a column of type pointer to "User", named "toUser"
     - Add a string column "type"
     
     Create a Custom class: "Photo"
     - Add a column of type pointer to "User", named "user"
     
     You'll notice that these correspond to each of the fields used by the preceding query.
     */

    return query;
}

- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger index = [self indexForObjectAtIndexPath:indexPath];
    if (index < self.objects.count) {
        return self.objects[index];
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"Cell";

    NSUInteger index = [self indexForObjectAtIndexPath:indexPath];

    if (indexPath.row % 2 == 0) {
        // Header
        return [self detailPhotoCellForRowAtIndexPath:indexPath];
    } else {
        // Photo
        TEPhotoCell *cell = (TEPhotoCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

        if (cell == nil) {
            cell = [[TEPhotoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            [cell.photoButton addTarget:self action:@selector(didTapOnPhotoAction:) forControlEvents:UIControlEventTouchUpInside];
        }

        cell.photoButton.tag = index;
        cell.imageView.image = [UIImage imageNamed:@"PlaceholderPhoto.png"];
        
        if (object) {
            cell.imageView.file = [object objectForKey:kTEPhotoPictureKey];
            
            // PFQTVC will take care of asynchronously downloading files, but will only load them when the tableview is not moving. If the data is there, let's load it right away.
            if ([cell.imageView.file isDataAvailable]) {
                [cell.imageView loadInBackground];
            }
        }

        return cell;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *LoadMoreCellIdentifier = @"LoadMoreCell";
    
    TELoadMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:LoadMoreCellIdentifier];
    if (!cell) {
        cell = [[TELoadMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadMoreCellIdentifier];
        cell.selectionStyle =UITableViewCellSelectionStyleNone;
        cell.hideSeparatorBottom = YES;
        cell.mainView.backgroundColor = [UIColor clearColor];
    }
    return cell;
}


#pragma mark - TEPhotoTimelineViewController

- (TEPhotoHeaderView *)dequeueReusableSectionHeaderView {
    for (TEPhotoHeaderView *sectionHeaderView in self.reusableSectionHeaderViews) {
        if (!sectionHeaderView.superview) {
            // we found a section header that is no longer visible
            return sectionHeaderView;
        }
    }
    
    return nil;
}


#pragma mark - TEPhotoHeaderViewDelegate

- (void)photoHeaderView:(TEPhotoHeaderView *)photoHeaderView didTapUserButton:(UIButton *)button user:(PFUser *)user {
    if ([self isKindOfClass:[TEAccountViewController class]]) {
        CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
        anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
        anim.autoreverses = YES ;
        anim.repeatCount = 2.0f ;
        anim.duration = 0.07f ;
        [self.view.layer addAnimation:anim forKey:nil];
    } else {
        TEAccountViewController *accountViewController = [[TEAccountViewController alloc] initWithUser:user];
        [accountViewController setUser:user];
        [self.navigationController pushViewController:accountViewController animated:YES];
    }
}

- (void)photoHeaderView:(TEPhotoHeaderView *)photoHeaderView didTapLikePhotoButton:(UIButton *)button photo:(PFObject *)photo {
    [photoHeaderView shouldEnableLikeButton:NO];
    
    BOOL liked = !button.selected;
    [photoHeaderView setLikeStatus:liked];
    
    NSString *originalButtonTitle = button.titleLabel.text;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    
    NSNumber *likeCount = [numberFormatter numberFromString:button.titleLabel.text];
    if (liked) {
        likeCount = [NSNumber numberWithInt:[likeCount intValue] + 1];
        [[TECache sharedCache] incrementLikerCountForPhoto:photo];
    } else {
        if ([likeCount intValue] > 0) {
            likeCount = [NSNumber numberWithInt:[likeCount intValue] - 1];
        }
        [[TECache sharedCache] decrementLikerCountForPhoto:photo];
    }
    
    [[TECache sharedCache] setPhotoIsLikedByCurrentUser:photo liked:liked];
    
    [button setTitle:[numberFormatter stringFromNumber:likeCount] forState:UIControlStateNormal];
    
    if (liked) {
        [TEUtility likePhotoInBackground:photo block:^(BOOL succeeded, NSError *error) {
            TEPhotoHeaderView *actualHeaderView = (TEPhotoHeaderView *)[self tableView:self.tableView viewForHeaderInSection:button.tag];
            [actualHeaderView shouldEnableLikeButton:YES];
            [actualHeaderView setLikeStatus:succeeded];
            
            if (!succeeded) {
                [actualHeaderView.likeButton setTitle:originalButtonTitle forState:UIControlStateNormal];
            }
        }];
    } else {
        [TEUtility unlikePhotoInBackground:photo block:^(BOOL succeeded, NSError *error) {
            TEPhotoHeaderView *actualHeaderView = (TEPhotoHeaderView *)[self tableView:self.tableView viewForHeaderInSection:button.tag];
            [actualHeaderView shouldEnableLikeButton:YES];
            [actualHeaderView setLikeStatus:!succeeded];
            
            if (!succeeded) {
                [actualHeaderView.likeButton setTitle:originalButtonTitle forState:UIControlStateNormal];
            }
        }];
    }
}

- (void)photoHeaderView:(TEPhotoHeaderView *)photoHeaderView didTapCommentOnPhotoButton:(UIButton *)button  photo:(PFObject *)photo {
    TEPhotoDetailsViewController *photoDetailsVC = [[TEPhotoDetailsViewController alloc] initWithPhoto:photo];
    [self.navigationController pushViewController:photoDetailsVC animated:YES];
}


#pragma mark - ()

- (UITableViewCell *)detailPhotoCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"DetailPhotoCell";

    if (self.paginationEnabled && indexPath.row == self.objects.count * 2) {
        // Load More section
        return nil;
    }
    
    NSUInteger index = [self indexForObjectAtIndexPath:indexPath];

    TEPhotoHeaderView *headerView = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!headerView) {
        headerView = [[TEPhotoHeaderView alloc] initWithFrame:CGRectMake( 0.0f, 0.0f, self.view.bounds.size.width, 44.0f) buttons:TEPhotoHeaderButtonsDefault];
        headerView.delegate = self;
        headerView.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    PFObject *object = [self objectAtIndexPath:indexPath];
    headerView.photo = object;
    headerView.tag = index;
    [headerView.likeButton setTag:index];

    NSDictionary *attributesForPhoto = [[TECache sharedCache] attributesForPhoto:object];
    
    if (attributesForPhoto) {
        [headerView setLikeStatus:[[TECache sharedCache] isPhotoLikedByCurrentUser:object]];
        [headerView.likeButton setTitle:[[[TECache sharedCache] likeCountForPhoto:object] description] forState:UIControlStateNormal];
        [headerView.commentButton setTitle:[[[TECache sharedCache] commentCountForPhoto:object] description] forState:UIControlStateNormal];
        
        if (headerView.likeButton.alpha < 1.0f || headerView.commentButton.alpha < 1.0f) {
            [UIView animateWithDuration:0.200f animations:^{
                headerView.likeButton.alpha = 1.0f;
                headerView.commentButton.alpha = 1.0f;
            }];
        }
    } else {
        headerView.likeButton.alpha = 0.0f;
        headerView.commentButton.alpha = 0.0f;
        
        @synchronized(self) {
            // check if we can update the cache
            NSNumber *outstandingSectionHeaderQueryStatus = [self.outstandingSectionHeaderQueries objectForKey:@(index)];
            if (!outstandingSectionHeaderQueryStatus) {
                PFQuery *query = [TEUtility queryForActivitiesOnPhoto:object cachePolicy:kPFCachePolicyNetworkOnly];
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    @synchronized(self) {
                        [self.outstandingSectionHeaderQueries removeObjectForKey:@(index)];
                        
                        if (error) {
                            return;
                        }
                        
                        NSMutableArray *likers = [NSMutableArray array];
                        NSMutableArray *commenters = [NSMutableArray array];
                        
                        BOOL isLikedByCurrentUser = NO;
                        
                        for (PFObject *activity in objects) {
                            if ([[activity objectForKey:kTEActivityTypeKey] isEqualToString:kTEActivityTypeLike] && [activity objectForKey:kTEActivityFromUserKey]) {
                                [likers addObject:[activity objectForKey:kTEActivityFromUserKey]];
                            } else if ([[activity objectForKey:kTEActivityTypeKey] isEqualToString:kTEActivityTypeComment] && [activity objectForKey:kTEActivityFromUserKey]) {
                                [commenters addObject:[activity objectForKey:kTEActivityFromUserKey]];
                            }
                            
                            if ([[[activity objectForKey:kTEActivityFromUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                                if ([[activity objectForKey:kTEActivityTypeKey] isEqualToString:kTEActivityTypeLike]) {
                                    isLikedByCurrentUser = YES;
                                }
                            }
                        }
                        
                        [[TECache sharedCache] setAttributesForPhoto:object likers:likers commenters:commenters likedByCurrentUser:isLikedByCurrentUser];
                        
                        if (headerView.tag != index) {
                            return;
                        }
                        
                        [headerView setLikeStatus:[[TECache sharedCache] isPhotoLikedByCurrentUser:object]];
                        [headerView.likeButton setTitle:[[[TECache sharedCache] likeCountForPhoto:object] description] forState:UIControlStateNormal];
                        [headerView.commentButton setTitle:[[[TECache sharedCache] commentCountForPhoto:object] description] forState:UIControlStateNormal];
                        
                        if (headerView.likeButton.alpha < 1.0f || headerView.commentButton.alpha < 1.0f) {
                            [UIView animateWithDuration:0.200f animations:^{
                                headerView.likeButton.alpha = 1.0f;
                                headerView.commentButton.alpha = 1.0f;
                            }];
                        }
                    }
                }];
            }
        }
    }
    
    return headerView;
}

- (NSIndexPath *)indexPathForObject:(PFObject *)targetObject {
    for (int i = 0; i < self.objects.count; i++) {
        PFObject *object = [self.objects objectAtIndex:i];
        if ([[object objectId] isEqualToString:[targetObject objectId]]) {
            return [NSIndexPath indexPathForRow:i*2+1 inSection:0];
        }
    }

    return nil;
}

- (void)userDidLikeOrUnlikePhoto:(NSNotification *)note {
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)userDidCommentOnPhoto:(NSNotification *)note {
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)userDidDeletePhoto:(NSNotification *)note {
    // refresh timeline after a delay
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_main_queue(), ^(void){
        [self loadObjects];
    });
}

- (void)userDidPublishPhoto:(NSNotification *)note {
    if (self.objects.count > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }

    [self loadObjects];
}

- (void)userFollowingChanged:(NSNotification *)note {
    NSLog(@"User following changed.");
    self.shouldReloadOnAppear = YES;
}


- (void)didTapOnPhotoAction:(UIButton *)sender {
    PFObject *photo = [self.objects objectAtIndex:sender.tag];
    if (photo) {
        TEPhotoDetailsViewController *photoDetailsVC = [[TEPhotoDetailsViewController alloc] initWithPhoto:photo];
        [self.navigationController pushViewController:photoDetailsVC animated:YES];
    }
}

/*
 For each object in self.objects, we display two cells. If pagination is enabled, there will be an extra cell at the end.
 NSIndexPath     index self.objects
 0 0 HEADER      0
 0 1 PHOTO       0
 0 2 HEADER      1
 0 3 PHOTO       1
 0 4 LOAD MORE
 */

- (NSIndexPath *)indexPathForObjectAtIndex:(NSUInteger)index header:(BOOL)header {
    return [NSIndexPath indexPathForItem:(index * 2 + (header ? 0 : 1)) inSection:0];
}

- (NSUInteger)indexForObjectAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row / 2;
}


@end
