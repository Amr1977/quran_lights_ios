//
//  SuraView.h
//  QuranGardens
//
//  Created by Amr Lotfy on 1/29/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SuraViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *suraName;
//amount of time left for next due review time
@property (weak, nonatomic) IBOutlet UIProgressView *timeProgressView;

@end
