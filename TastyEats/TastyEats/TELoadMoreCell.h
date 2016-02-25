//
//  TELoadMoreCell.h
//  TastyEats
//
//  Created by Kai Lu on 1/25/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

@interface TELoadMoreCell : UITableViewCell

@property (nonatomic, strong) UIView *mainView;
@property (nonatomic, strong) UIImageView *separatorImageTop;
@property (nonatomic, strong) UIImageView *separatorImageBottom;
@property (nonatomic, strong) UIImageView *loadMoreImageView;

@property (nonatomic, assign) BOOL hideSeparatorTop;
@property (nonatomic, assign) BOOL hideSeparatorBottom;

@property (nonatomic) CGFloat cellInsetWidth;

@end
