//
//  TEAccountViewController.h
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TEPhotoTimelineViewController.h"

@interface TEAccountViewController : TEPhotoTimelineViewController

@property (nonatomic, strong) PFUser *user;

- (id)initWithUser:(PFUser *)aUser;

@end
