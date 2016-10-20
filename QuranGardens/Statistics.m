//
//  Statistics.m
//  QuranGardens
//
//  Created by Amr Lotfy on 10/20/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "Statistics.h"

@implementation Statistics

- (instancetype)initWithDataSource:(DataSource *)dataSource{
    self = [super init];
    if (self) {
        _dataSource = dataSource;
        _score = [self.dataSource getScore];
    }
    
    return self;
}

- (void)setScore:(NSInteger)score{
    _score = score;
    [self.dataSource saveScore:score];
}

- (void)increaseScore:(NSInteger)delta{
    self.score = self.score + delta;
}

@end
