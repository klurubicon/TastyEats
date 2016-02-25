//
//  TEConstants.m
//  TastyEats
//
//  Created by Kai Lu on 2/08/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TEConstants.h"

NSString *const kTEUserDefaultsActivityFeedViewControllerLastRefreshKey    = @"com.parse.TastyEats.userDefaults.activityFeedViewController.lastRefresh";
NSString *const kTEUserDefaultsCacheFacebookFriendsKey                     = @"com.parse.TastyEats.userDefaults.cache.facebookFriends";


#pragma mark - Launch URLs

NSString *const kTELaunchURLHostTakePicture = @"camera";


#pragma mark - NSNotification

NSString *const TEAppDelegateApplicationDidReceiveRemoteNotification           = @"com.parse.TastyEats.appDelegate.applicationDidReceiveRemoteNotification";
NSString *const TEUtilityUserFollowingChangedNotification                      = @"com.parse.TastyEats.utility.userFollowingChanged";
NSString *const TEUtilityUserLikedUnlikedPhotoCallbackFinishedNotification     = @"com.parse.TastyEats.utility.userLikedUnlikedPhotoCallbackFinished";
NSString *const TEUtilityDidFinishProcessingProfilePictureNotification         = @"com.parse.TastyEats.utility.didFinishProcessingProfilePictureNotification";
NSString *const TETabBarControllerDidFinishEditingPhotoNotification            = @"com.parse.TastyEats.tabBarController.didFinishEditingPhoto";
NSString *const TETabBarControllerDidFinishImageFileUploadNotification         = @"com.parse.TastyEats.tabBarController.didFinishImageFileUploadNotification";
NSString *const TEPhotoDetailsViewControllerUserDeletedPhotoNotification       = @"com.parse.TastyEats.photoDetailsViewController.userDeletedPhoto";
NSString *const TEPhotoDetailsViewControllerUserLikedUnlikedPhotoNotification  = @"com.parse.TastyEats.photoDetailsViewController.userLikedUnlikedPhotoInDetailsViewNotification";
NSString *const TEPhotoDetailsViewControllerUserCommentedOnPhotoNotification   = @"com.parse.TastyEats.photoDetailsViewController.userCommentedOnPhotoInDetailsViewNotification";


#pragma mark - User Info Keys
NSString *const TEPhotoDetailsViewControllerUserLikedUnlikedPhotoNotificationUserInfoLikedKey = @"liked";
NSString *const kTEEditPhotoViewControllerUserInfoCommentKey = @"comment";

#pragma mark - Installation Class

// Field keys
NSString *const kTEInstallationUserKey = @"user";

#pragma mark - Activity Class
// Class key
NSString *const kTEActivityClassKey = @"Activity";

// Field keys
NSString *const kTEActivityTypeKey        = @"type";
NSString *const kTEActivityFromUserKey    = @"fromUser";
NSString *const kTEActivityToUserKey      = @"toUser";
NSString *const kTEActivityContentKey     = @"content";
NSString *const kTEActivityPhotoKey       = @"photo";

// Type values
NSString *const kTEActivityTypeLike       = @"like";
NSString *const kTEActivityTypeFollow     = @"follow";
NSString *const kTEActivityTypeComment    = @"comment";
NSString *const kTEActivityTypeJoined     = @"joined";

#pragma mark - User Class
// Field keys
NSString *const kTEUserDisplayNameKey                          = @"displayName";
NSString *const kTEUserFacebookIDKey                           = @"facebookId";
NSString *const kTEUserPhotoIDKey                              = @"photoId";
NSString *const kTEUserProfilePicSmallKey                      = @"profilePictureSmall";
NSString *const kTEUserProfilePicMediumKey                     = @"profilePictureMedium";
NSString *const kTEUserFacebookFriendsKey                      = @"facebookFriends";
NSString *const kTEUserAlreadyAutoFollowedFacebookFriendsKey   = @"userAlreadyAutoFollowedFacebookFriends";
NSString *const kTEUserEmailKey                                = @"email";
NSString *const kTEUserAutoFollowKey                           = @"autoFollow";

#pragma mark - Photo Class
// Class key
NSString *const kTEPhotoClassKey = @"Photo";

// Field keys
NSString *const kTEPhotoPictureKey         = @"image";
NSString *const kTEPhotoThumbnailKey       = @"thumbnail";
NSString *const kTEPhotoUserKey            = @"user";
NSString *const kTEPhotoOpenGraphIDKey    = @"fbOpenGraphID";


#pragma mark - Cached Photo Attributes
// keys
NSString *const kTEPhotoAttributesIsLikedByCurrentUserKey = @"isLikedByCurrentUser";
NSString *const kTEPhotoAttributesLikeCountKey            = @"likeCount";
NSString *const kTEPhotoAttributesLikersKey               = @"likers";
NSString *const kTEPhotoAttributesCommentCountKey         = @"commentCount";
NSString *const kTEPhotoAttributesCommentersKey           = @"commenters";


#pragma mark - Cached User Attributes
// keys
NSString *const kTEUserAttributesPhotoCountKey                 = @"photoCount";
NSString *const kTEUserAttributesIsFollowedByCurrentUserKey    = @"isFollowedByCurrentUser";


#pragma mark - Push Notification Payload Keys

NSString *const kAPNSAlertKey = @"alert";
NSString *const kAPNSBadgeKey = @"badge";
NSString *const kAPNSSoundKey = @"sound";

// the following keys are intentionally kept short, APNS has a maximum payload limit
NSString *const kTEPushPayloadPayloadTypeKey          = @"p";
NSString *const kTEPushPayloadPayloadTypeActivityKey  = @"a";

NSString *const kTEPushPayloadActivityTypeKey     = @"t";
NSString *const kTEPushPayloadActivityLikeKey     = @"l";
NSString *const kTEPushPayloadActivityCommentKey  = @"c";
NSString *const kTEPushPayloadActivityFollowKey   = @"f";

NSString *const kTEPushPayloadFromUserObjectIdKey = @"fu";
NSString *const kTEPushPayloadToUserObjectIdKey   = @"tu";
NSString *const kTEPushPayloadPhotoObjectIdKey    = @"pid";