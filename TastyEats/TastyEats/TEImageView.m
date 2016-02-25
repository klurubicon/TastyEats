//
//  TEImageView.m
//  TastyEats
//
//  Created by Kai Lu on 1/25/16.
//  Copyright (c) 2016 Rubicon Project. All rights reserved.
//

#import "TEImageView.h"

@interface TEImageView ()

@property (nonatomic, strong) PFFile *currentFile;
@property (nonatomic, strong) NSString *url;

@end

@implementation TEImageView

@synthesize currentFile,url;
@synthesize placeholderImage;

#pragma mark - TEImageView

- (void) setFile:(PFFile *)file {
    
    NSString *requestURL = file.url; // Save copy of url locally (will not change in block)
    [self setUrl:file.url]; // Save copy of url on the instance
    
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:data];
            if ([requestURL isEqualToString:self.url]) {
                [self setImage:image];
                [self setNeedsDisplay];
            }
        } else {
            NSLog(@"Error on fetching file");
        }
    }]; 
}

@end
