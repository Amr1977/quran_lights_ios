//
//  SettingsViewController.h
//  QuranGardens
//
//  Created by Amr Lotfy on 8/19/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"

@interface SettingsViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) Settings *settings;
@property (weak, nonatomic) id delegate;

-(void)hideKeyBoard;

@end

@protocol SettingsViewControllerDelegate <NSObject>

- (void)settingsViewController:(SettingsViewController *)settingsViewController didChangeSettings:(Settings *)settings;

- (void)showCharts;
-(void)showMembersView;
-(void)showLoginView;

@end

