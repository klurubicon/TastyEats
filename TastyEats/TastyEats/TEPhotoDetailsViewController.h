//
//  TEPhotoDetailViewController.h
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TEPhotoDetailsHeaderView.h"
#import "TEBaseTextCell.h"

@interface TEPhotoDetailsViewController : PFQueryTableViewController <UITextFieldDelegate, UIActionSheetDelegate, TEPhotoDetailsHeaderViewDelegate, TEBaseTextCellDelegate>

@property (nonatomic, strong) PFObject *photo;

- (id)initWithPhoto:(PFObject*)aPhoto;

@end
