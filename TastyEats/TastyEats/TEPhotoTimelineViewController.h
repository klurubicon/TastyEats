//
//  TEPhotoTimelineViewController.h
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TEPhotoHeaderView.h"

@interface TEPhotoTimelineViewController : PFQueryTableViewController <TEPhotoHeaderViewDelegate>

- (TEPhotoHeaderView *)dequeueReusableSectionHeaderView;

@end
