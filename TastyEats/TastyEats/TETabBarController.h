//
//  TETabBarController.h
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TEEditPhotoViewController.h"

@protocol TETabBarControllerDelegate;

@interface TETabBarController : UITabBarController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate>

- (BOOL)shouldPresentPhotoCaptureController;

@end

@protocol TETabBarControllerDelegate <NSObject>

- (void)tabBarController:(UITabBarController *)tabBarController cameraButtonTouchUpInsideAction:(UIButton *)button;

@end