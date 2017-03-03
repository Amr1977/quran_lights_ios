//
//  UIViewController+Gestures.h
//  QuranGardens
//
//  Created by Amr Lotfy on 3/3/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Gestures)

- (void)addSwipeHandlerToView:(UIView *)view direction:(NSString *)direction handler:(SEL)handler;

@end
