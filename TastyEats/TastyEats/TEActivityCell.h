//
//  TEActivityCell.h
//  TastyEats
//
//  Created by Kai Lu on 1/25/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TEBaseTextCell.h"
@protocol TEActivityCellDelegate;

@interface TEActivityCell : TEBaseTextCell

@property (nonatomic, strong) PFObject *activity;

- (void)setIsNew:(BOOL)isNew;

@end



@protocol TEActivityCellDelegate <TEBaseTextCellDelegate>
@optional


- (void)cell:(TEActivityCell *)cellView didTapActivityButton:(PFObject *)activity;

@end