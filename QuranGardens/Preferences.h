//
//  Preferences.h
//  QuranGardens
//
//  Created by Amr Lotfy on 2/18/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <Realm/Realm.h>

@interface Preferences : RLMObject

@property (nonatomic) BOOL showHelpMessageAtStartup;

@end
