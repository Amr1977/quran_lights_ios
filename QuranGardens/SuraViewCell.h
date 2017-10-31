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
@property (weak, nonatomic) IBOutlet UILabel *daysElapsed;
@property (weak, nonatomic) IBOutlet UIImageView *memorized;
@property (weak, nonatomic) IBOutlet UIView *content;

@property (weak, nonatomic) IBOutlet UILabel *score;

@property (weak, nonatomic) IBOutlet UILabel *verseCountLabel;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *suraNameTrailingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *suraNameLeadingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *suraNameBottomSpace;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *suraNameTopSpace;



@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;



@end
