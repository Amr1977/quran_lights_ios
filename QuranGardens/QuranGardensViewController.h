//
//  QuranGardensViewController.h
//  QuranGardens
//
//  Created by Amr Lotfy on 1/29/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"
#import "UIViewController+Gestures.h"



extern CGFloat const CellHeight;
extern CGFloat const CellWidth;

@interface QuranGardensViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegateFlowLayout, SettingsViewControllerDelegate>

@end


