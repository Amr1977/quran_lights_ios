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

-(void)toast:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [hud.bezelView setBackgroundColor:[UIColor blackColor]];
        hud.contentColor = [UIColor whiteColor];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = message;
        hud.margin = 10.f;
        hud.removeFromSuperViewOnHide = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
        });
    });
}

@end
