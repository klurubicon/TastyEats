//
//  TEImageView.h
//  TastyEats
//
//  Created by Kai Lu on 1/25/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

@interface TEImageView : UIImageView

@property (nonatomic, strong) UIImage *placeholderImage;

- (void) setFile:(PFFile *)file;

@end
