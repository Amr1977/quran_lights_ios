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

#define Demo NO
#define MEMORIZED 2
#define BEING_MEMORIZED 3
#define WAS_MEMORIZED 1
#define NOT_MEMORIZED 0

extern CGFloat const CellHeight;
extern CGFloat const CellWidth;

@interface QuranGardensViewController : UICollectionViewController <UICollectionViewDataSource,UICollectionViewDelegateFlowLayout, SettingsViewControllerDelegate>

@end


