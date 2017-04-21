//
//  NSString+Localization.m
//  QuranGardens
//
//  Created by Amr Lotfy on 4/21/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "NSString+Localization.h"

@implementation NSString (Localization)

- (NSString *)localize {
    return NSLocalizedString(self, @"");
}

@end
