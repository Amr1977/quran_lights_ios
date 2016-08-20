//
//  SettingsViewController.h
//  QuranGardens
//
//  Created by Amr Lotfy on 8/19/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"

@interface SettingsViewController : UIViewController

@property (strong, nonatomic) Settings *settings;
@property (weak, nonatomic) id delegate;

@end

@protocol SettingsViewControllerDelegate <NSObject>

- (void)settingsViewController:(SettingsViewController *)settingsViewController didChangeSettings:(Settings *)settings;

@end

