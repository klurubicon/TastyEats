//
//  TEFindFriendsCell.h
//  TastyEats
//
//  Created by Kai Lu on 1/25/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

@class TEProfileImageView;
@protocol TEFindFriendsCellDelegate;

@interface TEFindFriendsCell : UITableViewCell {
    id _delegate;
}

@property (nonatomic, strong) id<TEFindFriendsCellDelegate> delegate;

/*! The user represented in the cell */
@property (nonatomic, strong) PFUser *user;
@property (nonatomic, strong) UILabel *photoLabel;
@property (nonatomic, strong) UIButton *followButton;

/*! Setters for the cell's content */
- (void)setUser:(PFUser *)user;

- (void)didTapUserButtonAction:(id)sender;
- (void)didTapFollowButtonAction:(id)sender;

/*! Static Helper methods */
+ (CGFloat)heightForCell;

@end

/*!
 The protocol defines methods a delegate of a TEFindFriendsCell should implement.
 */
@protocol TEFindFriendsCellDelegate <NSObject>
@optional

/*!
 Sent to the delegate when a user button is tapped
 @param aUser the PFUser of the user that was tapped
 */
- (void)cell:(TEFindFriendsCell *)cellView didTapUserButton:(PFUser *)aUser;
- (void)cell:(TEFindFriendsCell *)cellView didTapFollowButton:(PFUser *)aUser;

@end
