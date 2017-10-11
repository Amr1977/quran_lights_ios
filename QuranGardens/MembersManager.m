//
//  MembersManager.m
//  QuranGardens
//
//  Created by   Amr Lotfy on 10/10/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "MembersManager.h"
#import "FireBaseManager.h"

@implementation MembersManager

+ (MembersManager *)shared {
    static MembersManager *sharedInstance;
    if(sharedInstance == nil) {
        sharedInstance = [[MembersManager alloc] init];
    }
    
    return sharedInstance;
}

- (void)addMemberWithId:(NSString *)memberId name:(NSString *)name {
    if (![name isEqualToString:@"Master"]) {
        [[[[FireBaseManager shared] membersRef] child:memberId] setValue:name];
    }
}

@end
