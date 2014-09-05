//
//  BKHud.m
//  PaytotaP
//
//  Created by Bakuf on 8/27/14.
//  Copyright (c) 2014 Rodrigo Gálvez. All rights reserved.
//

#import "BKHud.h"

#define BKHudWidth 160

@interface BKHud (){
    UIView *hudView;
}

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIProgressView *progressBar;

@end

@implementation BKHud

+ (instancetype)showHUDanimated:(BOOL)animated {
	BKHud *hud = [[self alloc] init];
    UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
    UIView *theActualView = [[topWindow subviews] lastObject];
	[theActualView addSubview:hud];
	[hud show:animated];
	return hud;
}

+ (BOOL)hideHUDanimated:(BOOL)animated {
    UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
    UIView *theActualView = [[topWindow subviews] lastObject];
    for (BKHud *view in theActualView.subviews) {
        if ([view isKindOfClass:[self class]]) {
            [view hide:animated];
            return YES;
        }
    }
	return NO;
}

- (id)init{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        [self configure];
    }
    return self;
}

- (void)setText:(NSString*)text{
    self.textLabel.text = text;
}

- (void)configure{
    hudView = [[UIView alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width / 2) - (BKHudWidth/2), ([UIScreen mainScreen].bounds.size.height / 2) - (BKHudWidth/2), BKHudWidth, BKHudWidth)];
    
    hudView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    hudView.layer.cornerRadius = 10.0;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.frame = CGRectMake(hudView.frame.size.width/2 - 18, hudView.frame.size.height/2 - 18, 37, 37);
    [hudView addSubview:self.activityIndicator];
    
    self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, self.activityIndicator.frame.origin.y - 40, hudView.frame.size.width - 10, 21)];
    self.textLabel.textColor = [UIColor whiteColor];
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.numberOfLines = 1;
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    [hudView addSubview:self.textLabel];
    
    self.progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(hudView.frame.size.width/2 - 75, self.activityIndicator.frame.origin.y + 40, 150, 2)];
    [hudView addSubview:self.progressBar];
    self.progressBar.hidden = YES;
    
    [self addSubview:hudView];
}

- (void)setProgress:(float)progress{
    self.progressBar.hidden = NO;
    [self.progressBar setProgress:progress];
}

#pragma mark Show & hide

- (void)show:(BOOL)animated {
	if (animated) {
        hudView.transform = CGAffineTransformMakeScale(0.6, 0.6);
        hudView.hidden = NO;
        [UIView animateWithDuration: 0.2
                         animations: ^{
                             hudView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                         }
                         completion: ^(BOOL finished){
                             [UIView animateWithDuration:1.0/15.0
                                              animations: ^{
                                                  hudView.transform = CGAffineTransformMakeScale(0.9, 0.9);
                                              }
                                              completion: ^(BOOL finished){
                                                  [UIView animateWithDuration:1.0/7.5
                                                                   animations: ^{
                                                                       hudView.transform = CGAffineTransformIdentity;
                                                                   }];
                                              }];
                         }];
    }
    [self.activityIndicator startAnimating];
}

- (void)hide:(BOOL)animated {
	if (animated) {
        [UIView animateWithDuration: 0.3
                         animations: ^{
                             hudView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                         }
                         completion: ^(BOOL finished){
                             [UIView animateWithDuration:0.2
                                              animations: ^{
                                                  hudView.transform = CGAffineTransformMakeScale(0.0, 0.0);
                                              }
                                              completion: ^(BOOL finished){
                                                  hudView.hidden = YES;
                                                  [self removeFromSuperview];
                                              }];
                         }];
        
    }else{
        [self removeFromSuperview];
    }
}

@end
