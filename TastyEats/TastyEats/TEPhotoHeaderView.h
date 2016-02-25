//
//  TEPhotoHeaderView.h
//  TastyEats
//
//  Created by Kai Lu on 1/25/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

typedef enum {
    TEPhotoHeaderButtonsNone = 0,
    TEPhotoHeaderButtonsLike = 1 << 0,
    TEPhotoHeaderButtonsComment = 1 << 1,
    TEPhotoHeaderButtonsUser = 1 << 2,
    
    TEPhotoHeaderButtonsDefault = TEPhotoHeaderButtonsLike | TEPhotoHeaderButtonsComment | TEPhotoHeaderButtonsUser
} TEPhotoHeaderButtons;

@protocol TEPhotoHeaderViewDelegate;

@interface TEPhotoHeaderView : UITableViewCell

/* Creating Photo Header View */

- (id)initWithFrame:(CGRect)frame buttons:(TEPhotoHeaderButtons)otherButtons;

/// The photo associated with this view
@property (nonatomic,strong) PFObject *photo;

/// The bitmask which specifies the enabled interaction elements in the view
@property (nonatomic, readonly, assign) TEPhotoHeaderButtons buttons;


/* Accessing Interaction Elements */

/// The Like Photo button
@property (nonatomic,readonly) UIButton *likeButton;

/// The Comment On Photo button
@property (nonatomic,readonly) UIButton *commentButton;

@property (nonatomic,weak) id <TEPhotoHeaderViewDelegate> delegate;


/* Configures the Like Button to match the given like status. */
- (void)setLikeStatus:(BOOL)liked;

/*!
 Enable the like button to start receiving actions.
 */
- (void)shouldEnableLikeButton:(BOOL)enable;

@end



@protocol TEPhotoHeaderViewDelegate <NSObject>
@optional

/* Sent to the delegate when the user button is tapped */
- (void)photoHeaderView:(TEPhotoHeaderView *)photoHeaderView didTapUserButton:(UIButton *)button user:(PFUser *)user;

/* Sent to the delegate when the like photo button is tapped */
- (void)photoHeaderView:(TEPhotoHeaderView *)photoHeaderView didTapLikePhotoButton:(UIButton *)button photo:(PFObject *)photo;

/* Sent to the delegate when the comment on photo button is tapped */
- (void)photoHeaderView:(TEPhotoHeaderView *)photoHeaderView didTapCommentOnPhotoButton:(UIButton *)button photo:(PFObject *)photo;

@end