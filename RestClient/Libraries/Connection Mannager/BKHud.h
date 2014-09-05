//
//  BKHud.h
//  PaytotaP
//
//  Created by Bakuf on 8/27/14.
//  Copyright (c) 2014 Rodrigo Gálvez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BKHud : UIView

+ (instancetype)showHUDanimated:(BOOL)animated;
+ (BOOL)hideHUDanimated:(BOOL)animated;
- (void)setProgress:(float)progress;
- (void)setText:(NSString*)text;

@end
