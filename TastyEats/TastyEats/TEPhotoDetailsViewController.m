//
//  TEPhotoDetailViewController.m
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TEPhotoDetailsViewController.h"
#import "TEBaseTextCell.h"
#import "TEActivityCell.h"
#import "TEPhotoDetailsFooterView.h"
#import "TEConstants.h"
#import "TEAccountViewController.h"
#import "TELoadMoreCell.h"
#import "TEUtility.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"

enum ActionSheetTags {
    MainActionSheetTag = 0,
    ConfirmDeleteActionSheetTag = 1
};

@interface TEPhotoDetailsViewController ()
@property (nonatomic, strong) UITextField *commentTextField;
@property (nonatomic, strong) TEPhotoDetailsHeaderView *headerView;
@property (nonatomic, assign) BOOL likersQueryInProgress;
@end

static const CGFloat kTECellInsetWidth = 0.0f;

@implementation TEPhotoDetailsViewController

@synthesize commentTextField;
@synthesize photo, headerView;

#pragma mark - Initialization

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TEUtilityUserLikedUnlikedPhotoCallbackFinishedNotification object:self.photo];
}

- (id)initWithPhoto:(PFObject *)aPhoto {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // The className to query on
        self.parseClassName = kTEActivityClassKey;

        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;

        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of comments to show per page
        self.objectsPerPage = 30;
        
        self.photo = aPhoto;
        
        self.likersQueryInProgress = NO;
    }
    return self;
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    [super viewDidLoad];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBar.png"]];
    
    // Set table view properties
    UIView *texturedBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    texturedBackgroundView.backgroundColor = [UIColor blackColor];
    self.tableView.backgroundView = texturedBackgroundView;
    
    // Set table header
    self.headerView = [[TEPhotoDetailsHeaderView alloc] initWithFrame:[TEPhotoDetailsHeaderView rectForView] photo:self.photo];
    self.headerView.delegate = self;
    
    self.tableView.tableHeaderView = self.headerView;
    
    // Set table footer
    TEPhotoDetailsFooterView *footerView = [[TEPhotoDetailsFooterView alloc] initWithFrame:[TEPhotoDetailsFooterView rectForView]];
    commentTextField = footerView.commentField;
    commentTextField.delegate = self;
    self.tableView.tableFooterView = footerView;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(activityButtonAction:)];
    
    // Register to be notified when the keyboard will be shown to scroll the view
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLikedOrUnlikedPhoto:) name:TEUtilityUserLikedUnlikedPhotoCallbackFinishedNotification object:self.photo];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.headerView reloadLikeBar];
    
    // we will only hit the network if we have no cached data for this photo
    BOOL hasCachedLikers = [[TECache sharedCache] attributesForPhoto:self.photo] != nil;
    if (!hasCachedLikers) {
        [self loadLikers];
    }
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) { // A comment row
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        
        if (object) {
            NSString *commentString = [self.objects[indexPath.row] objectForKey:kTEActivityContentKey];
            
            PFUser *commentAuthor = (PFUser *)[object objectForKey:kTEActivityFromUserKey];
            
            NSString *nameString = @"";
            if (commentAuthor) {
                nameString = [commentAuthor objectForKey:kTEUserDisplayNameKey];
            }
            
            return [TEActivityCell heightForCellWithName:nameString contentString:commentString cellInsetWidth:kTECellInsetWidth];
        }
    }
    
    // The pagination row
    return 44.0f;
}


#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:kTEActivityPhotoKey equalTo:self.photo];
    [query includeKey:kTEActivityFromUserKey];
    [query whereKey:kTEActivityTypeKey equalTo:kTEActivityTypeComment];
    [query orderByAscending:@"createdAt"]; 

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

    [self.headerView reloadLikeBar];
    [self loadLikers];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *cellID = @"CommentCell";

    // Try to dequeue a cell and create one if necessary
    TEBaseTextCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[TEBaseTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.cellInsetWidth = kTECellInsetWidth;
        cell.delegate = self;
    }
    
    [cell setUser:[object objectForKey:kTEActivityFromUserKey]];
    [cell setContentText:[object objectForKey:kTEActivityContentKey]];
    [cell setDate:[object createdAt]];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"NextPageDetails";
    
    TELoadMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[TELoadMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.cellInsetWidth = kTECellInsetWidth;
        cell.hideSeparatorTop = YES;
    }
    
    return cell;
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *trimmedComment = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (trimmedComment.length != 0 && [self.photo objectForKey:kTEPhotoUserKey]) {
        PFObject *comment = [PFObject objectWithClassName:kTEActivityClassKey];
        [comment setObject:trimmedComment forKey:kTEActivityContentKey]; // Set comment text
        [comment setObject:[self.photo objectForKey:kTEPhotoUserKey] forKey:kTEActivityToUserKey]; // Set toUser
        [comment setObject:[PFUser currentUser] forKey:kTEActivityFromUserKey]; // Set fromUser
        [comment setObject:kTEActivityTypeComment forKey:kTEActivityTypeKey];
        [comment setObject:self.photo forKey:kTEActivityPhotoKey];
        
        PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
        [ACL setPublicReadAccess:YES];
        [ACL setWriteAccess:YES forUser:[self.photo objectForKey:kTEPhotoUserKey]];
        comment.ACL = ACL;

        [[TECache sharedCache] incrementCommentCountForPhoto:self.photo];
        
        // Show HUD view
        [MBProgressHUD showHUDAddedTo:self.view.superview animated:YES];
        
        // If more than 5 seconds pass since we post a comment, stop waiting for the server to respond
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(handleCommentTimeout:) userInfo:@{@"comment": comment} repeats:NO];

        [comment saveEventually:^(BOOL succeeded, NSError *error) {
            [timer invalidate];
            
            if (error && error.code == kPFErrorObjectNotFound) {
                [[TECache sharedCache] decrementCommentCountForPhoto:self.photo];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could not post comment", nil) message:NSLocalizedString(@"This photo is no longer available", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];
                [self.navigationController popViewControllerAnimated:YES];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:TEPhotoDetailsViewControllerUserCommentedOnPhotoNotification object:self.photo userInfo:@{@"comments": @(self.objects.count + 1)}];
            
            [MBProgressHUD hideHUDForView:self.view.superview animated:YES];
            [self loadObjects];
        }];
    }
    
    [textField setText:@""];
    return [textField resignFirstResponder];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == MainActionSheetTag) {
        if ([actionSheet destructiveButtonIndex] == buttonIndex) {
            // prompt to delete
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete this photo?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Yes, delete photo", nil) otherButtonTitles:nil];
            actionSheet.tag = ConfirmDeleteActionSheetTag;
            [actionSheet showFromTabBar:self.tabBarController.tabBar];
        } else {
            [self activityButtonAction:actionSheet];
        }
    } else if (actionSheet.tag == ConfirmDeleteActionSheetTag) {
        if ([actionSheet destructiveButtonIndex] == buttonIndex) {
            
            [self shouldDeletePhoto];
        }
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [commentTextField resignFirstResponder];
}


#pragma mark - TEBaseTextCellDelegate

- (void)cell:(TEBaseTextCell *)cellView didTapUserButton:(PFUser *)aUser {
    [self shouldPresentAccountViewForUser:aUser];
}


#pragma mark - TEPhotoDetailsHeaderViewDelegate

-(void)photoDetailsHeaderView:(TEPhotoDetailsHeaderView *)headerView didTapUserButton:(UIButton *)button user:(PFUser *)user {
    [self shouldPresentAccountViewForUser:user];
}

- (void)actionButtonAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = self;
    actionSheet.tag = MainActionSheetTag;
    actionSheet.destructiveButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete Photo", nil)];
    if (NSClassFromString(@"UIActivityViewController")) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Share Photo", nil)];
    }
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)activityButtonAction:(id)sender {
    if ([[self.photo objectForKey:kTEPhotoPictureKey] isDataAvailable]) {
        [self showShareSheet];
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[self.photo objectForKey:kTEPhotoPictureKey] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (!error) {
                [self showShareSheet];
            }
        }];
    }
}


#pragma mark - ()

- (void)showShareSheet {
    [[self.photo objectForKey:kTEPhotoPictureKey] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            NSMutableArray *activityItems = [NSMutableArray arrayWithCapacity:3];
                        
            // Prefill caption if this is the original poster of the photo, and then only if they added a caption initially.
            if ([[[PFUser currentUser] objectId] isEqualToString:[[self.photo objectForKey:kTEPhotoUserKey] objectId]] && [self.objects count] > 0) {
                PFObject *firstActivity = self.objects[0];
                if ([[[firstActivity objectForKey:kTEActivityFromUserKey] objectId] isEqualToString:[[self.photo objectForKey:kTEPhotoUserKey] objectId]]) {
                    NSString *commentString = [firstActivity objectForKey:kTEActivityContentKey];
                    [activityItems addObject:commentString];
                }
            }
            
            [activityItems addObject:[UIImage imageWithData:data]];
            
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
            [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
        }
    }];
}

- (void)handleCommentTimeout:(NSTimer *)aTimer {
    [MBProgressHUD hideHUDForView:self.view.superview animated:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New Comment", nil) message:NSLocalizedString(@"Your comment will be posted next time there is an Internet connection.", nil)  delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Dismiss", nil), nil];
    [alert show];
}

- (void)shouldPresentAccountViewForUser:(PFUser *)user {
    TEAccountViewController *accountViewController = [[TEAccountViewController alloc] initWithStyle:UITableViewStylePlain];
    NSLog(@"Presenting account view controller with user: %@", user);
    [accountViewController setUser:user];
    [self.navigationController pushViewController:accountViewController animated:YES];
}

- (void)backButtonAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)userLikedOrUnlikedPhoto:(NSNotification *)note {
    [self.headerView reloadLikeBar];
}

- (void)keyboardWillShow:(NSNotification*)note {
    // Scroll the view to the comment text box
    NSDictionary* info = [note userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    [self.tableView setContentOffset:CGPointMake(0.0f, self.tableView.contentSize.height-kbSize.height) animated:YES];
}

- (void)loadLikers {
    if (self.likersQueryInProgress) {
        return;
    }

    self.likersQueryInProgress = YES;
    PFQuery *query = [TEUtility queryForActivitiesOnPhoto:photo cachePolicy:kPFCachePolicyNetworkOnly];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.likersQueryInProgress = NO;
        if (error) {
            [self.headerView reloadLikeBar];
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
        
        [[TECache sharedCache] setAttributesForPhoto:photo likers:likers commenters:commenters likedByCurrentUser:isLikedByCurrentUser];
        [self.headerView reloadLikeBar];
    }];
}

- (BOOL)currentUserOwnsPhoto {
    return [[[self.photo objectForKey:kTEPhotoUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]];
}

- (void)shouldDeletePhoto {
    // Delete all activites related to this photo
    PFQuery *query = [PFQuery queryWithClassName:kTEActivityClassKey];
    [query whereKey:kTEActivityPhotoKey equalTo:self.photo];
    [query findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {
        if (!error) {
            for (PFObject *activity in activities) {
                [activity deleteEventually];
            }
        }
        
        // Delete photo
        [self.photo deleteEventually];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:TEPhotoDetailsViewControllerUserDeletedPhotoNotification object:[self.photo objectId]];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
