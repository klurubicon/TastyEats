//
//  TEActivityFeedViewController.h
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TEActivityCell.h"

@interface TEActivityFeedViewController : PFQueryTableViewController <TEActivityCellDelegate>

+ (NSString *)stringForActivityType:(NSString *)activityType;

@end
