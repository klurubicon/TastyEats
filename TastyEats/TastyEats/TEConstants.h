//
//  TEConstants.h
//  TastyEats
//
//  Created by Kai Lu on 2/08/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

typedef enum {
	TEHomeTabBarItemIndex = 0,
	TEEmptyTabBarItemIndex = 1,
	TEActivityTabBarItemIndex = 2
} TETabBarControllerViewControllerIndex;


#pragma mark - NSUserDefaults
extern NSString *const kTEUserDefaultsActivityFeedViewControllerLastRefreshKey;
extern NSString *const kTEUserDefaultsCacheFacebookFriendsKey;

#pragma mark - Launch URLs

extern NSString *const kTELaunchURLHostTakePicture;


#pragma mark - NSNotification
extern NSString *const TEAppDelegateApplicationDidReceiveRemoteNotification;
extern NSString *const TEUtilityUserFollowingChangedNotification;
extern NSString *const TEUtilityUserLikedUnlikedPhotoCallbackFinishedNotification;
extern NSString *const TEUtilityDidFinishProcessingProfilePictureNotification;
extern NSString *const TETabBarControllerDidFinishEditingPhotoNotification;
extern NSString *const TETabBarControllerDidFinishImageFileUploadNotification;
extern NSString *const TEPhotoDetailsViewControllerUserDeletedPhotoNotification;
extern NSString *const TEPhotoDetailsViewControllerUserLikedUnlikedPhotoNotification;
extern NSString *const TEPhotoDetailsViewControllerUserCommentedOnPhotoNotification;


#pragma mark - User Info Keys
extern NSString *const TEPhotoDetailsViewControllerUserLikedUnlikedPhotoNotificationUserInfoLikedKey;
extern NSString *const kTEEditPhotoViewControllerUserInfoCommentKey;


#pragma mark - Installation Class

// Field keys
extern NSString *const kTEInstallationUserKey;


#pragma mark - PFObject Activity Class
// Class key
extern NSString *const kTEActivityClassKey;

// Field keys
extern NSString *const kTEActivityTypeKey;
extern NSString *const kTEActivityFromUserKey;
extern NSString *const kTEActivityToUserKey;
extern NSString *const kTEActivityContentKey;
extern NSString *const kTEActivityPhotoKey;

// Type values
extern NSString *const kTEActivityTypeLike;
extern NSString *const kTEActivityTypeFollow;
extern NSString *const kTEActivityTypeComment;
extern NSString *const kTEActivityTypeJoined;


#pragma mark - PFObject User Class
// Field keys
extern NSString *const kTEUserDisplayNameKey;
extern NSString *const kTEUserFacebookIDKey;
extern NSString *const kTEUserPhotoIDKey;
extern NSString *const kTEUserProfilePicSmallKey;
extern NSString *const kTEUserProfilePicMediumKey;
extern NSString *const kTEUserFacebookFriendsKey;
extern NSString *const kTEUserAlreadyAutoFollowedFacebookFriendsKey;
extern NSString *const kTEUserEmailKey;
extern NSString *const kTEUserAutoFollowKey;

#pragma mark - PFObject Photo Class
// Class key
extern NSString *const kTEPhotoClassKey;

// Field keys
extern NSString *const kTEPhotoPictureKey;
extern NSString *const kTEPhotoThumbnailKey;
extern NSString *const kTEPhotoUserKey;
extern NSString *const kTEPhotoOpenGraphIDKey;


#pragma mark - Cached Photo Attributes
// keys
extern NSString *const kTEPhotoAttributesIsLikedByCurrentUserKey;
extern NSString *const kTEPhotoAttributesLikeCountKey;
extern NSString *const kTEPhotoAttributesLikersKey;
extern NSString *const kTEPhotoAttributesCommentCountKey;
extern NSString *const kTEPhotoAttributesCommentersKey;


#pragma mark - Cached User Attributes
// keys
extern NSString *const kTEUserAttributesPhotoCountKey;
extern NSString *const kTEUserAttributesIsFollowedByCurrentUserKey;


#pragma mark - PFPush Notification Payload Keys

extern NSString *const kAPNSAlertKey;
extern NSString *const kAPNSBadgeKey;
extern NSString *const kAPNSSoundKey;

extern NSString *const kTEPushPayloadPayloadTypeKey;
extern NSString *const kTEPushPayloadPayloadTypeActivityKey;

extern NSString *const kTEPushPayloadActivityTypeKey;
extern NSString *const kTEPushPayloadActivityLikeKey;
extern NSString *const kTEPushPayloadActivityCommentKey;
extern NSString *const kTEPushPayloadActivityFollowKey;

extern NSString *const kTEPushPayloadFromUserObjectIdKey;
extern NSString *const kTEPushPayloadToUserObjectIdKey;
extern NSString *const kTEPushPayloadPhotoObjectIdKey;