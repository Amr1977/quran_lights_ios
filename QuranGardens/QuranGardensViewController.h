//
//  QuranGardensViewController.h
//  QuranGardens
//
//  Created by Amr Lotfy on 1/29/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"

#define Demo NO

extern CGFloat const CellHeight;
extern CGFloat const CellWidth;

@protocol SettingsViewControllerDelegate <NSObject>

- (void)settingsViewController:(SettingsViewController *)settingsViewController didChangeSettings:(Settings *)settings;

@end

@interface QuranGardensViewController : UICollectionViewController <UICollectionViewDataSource,UICollectionViewDelegateFlowLayout, SettingsViewControllerDelegate>

@end
