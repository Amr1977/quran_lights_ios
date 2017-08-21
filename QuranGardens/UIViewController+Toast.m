//
//  UIViewController+Toast.m
//  
//
//  Created by Amr Lotfy on 8/21/17.
//
//

#import "UIViewController+Toast.h"
#import "MBProgressHUD.h"

@implementation UIViewController (Toast)

-(void)toast:(NSString *)message view:(UIView *)view {
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        //hud.bezelView.backgroundColor = [UIColor darkGrayColor];
        //hud.contentColor = [UIColor whiteColor];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = message;
        //hud.removeFromSuperViewOnHide = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [hud hideAnimated:NO];
        });
    });
}

-(void)toast:(NSString *)message {
    [self toast:message view:self.view];
}

@end
