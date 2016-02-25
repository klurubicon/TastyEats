//
//  TEWelcomeViewController.h
//  TastyEats
//
//  Created by Kai Lu on 2/01/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#include "TELogInViewController.h"

@interface TEWelcomeViewController : UIViewController <TELogInViewControllerDelegate>

- (void)presentLoginViewController:(BOOL)animated;

@end
