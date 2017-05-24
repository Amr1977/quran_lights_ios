//
//  User.m
//  QuranGardens
//
//  Created by Amr Lotfy on 5/23/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "User.h"

@implementation User

- (NSString *)nonEmptyId {
    NSString *userIdChild = self.userId;
    
    if ([userIdChild isEqualToString:@""]) {
        userIdChild = @"Master";
    }
    
    return userIdChild;

}

@end
