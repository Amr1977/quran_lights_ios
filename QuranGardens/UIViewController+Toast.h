//
//  UIViewController+Toast.h
//  
//
//  Created by Amr Lotfy on 8/21/17.
//
//

#import <UIKit/UIKit.h>

@interface UIViewController (Toast)

-(void)toast:(NSString *)message;
-(void)toast:(NSString *)message view:(UIView *)view;


@end
