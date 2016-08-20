//
//  Settings.m
//  QuranGardens
//
//  Created by Amr Lotfy on 8/19/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "Settings.h"

@implementation Settings

- (double)fadeTimeToSeconds{
    return [[self class] getTimeInSeconds:self.fadeTime];
}

- (void)setFadeTimeFromSeconds:(double)seconds{
    self.fadeTime = [[self class] getTimeStringFromSeconds:seconds];
}

+ (double)getTimeInSeconds:(NSString *)timeString{
    //TODO: Do it !
    return 0;
}
+ (NSString *)getTimeStringFromSeconds:(double)seconds{
    //TODO: Do it !
    return nil;
}


@end
