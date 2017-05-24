//
//  User.h
//  QuranGardens
//
//  Created by Amr Lotfy on 5/23/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *userId;

- (NSString *)nonEmptyId;

@end
