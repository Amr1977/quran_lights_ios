//
//  MembersManager.h
//  QuranGardens
//
//  Created by   Amr Lotfy on 10/10/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MembersManager : NSObject

+ (MembersManager *)shared;
- (void)addMemberWithId:(NSString *)memberId name:(NSString *)name;

@end
