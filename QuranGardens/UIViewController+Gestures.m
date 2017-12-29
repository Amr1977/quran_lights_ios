//
//  UIViewController+Gestures.m
//  QuranGardens
//
//  Created by Amr Lotfy on 3/3/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "UIViewController+Gestures.h"

@implementation UIViewController (Gestures)

- (void)addSwipeHandlerToView:(UIView *)view direction:(NSString *)direction handler:(SEL)handler{
    direction = [direction lowercaseString];
    if ([direction isEqualToString:@"right"]) {
        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:handler];
        [swipeRight setDirection: UISwipeGestureRecognizerDirectionRight];
        [view addGestureRecognizer:swipeRight];
    } else if ([direction isEqualToString:@"left"]) {
        UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:handler];
        [swipeLeft setDirection: UISwipeGestureRecognizerDirectionLeft];
        [view addGestureRecognizer:swipeLeft];
    } else if ([direction isEqualToString:@"up"]) {
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:handler];
        [swipe setDirection: UISwipeGestureRecognizerDirectionUp];
        [view addGestureRecognizer:swipe];
    } else if ([direction isEqualToString:@"down"]) {
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:handler];
        [swipe setDirection: UISwipeGestureRecognizerDirectionDown];
        [view addGestureRecognizer:swipe];
    }
}

@end
