//
//  Statistics.h
//  QuranGardens
//
//  Created by Amr Lotfy on 10/20/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataSource.h"

static NSString *const score_key = @"score_key";

@interface Statistics : NSObject

@property(nonatomic) NSInteger score;
@property(weak, nonatomic) DataSource* dataSource;

- (instancetype)initWithDataSource:(DataSource *)dataSource;

- (void)increaseScore:(NSInteger)delta;

@end
