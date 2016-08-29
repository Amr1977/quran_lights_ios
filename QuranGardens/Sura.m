//
//  Sura.m
//  QuranGardens
//
//  Created by Amr Lotfy on 1/29/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "Sura.h"

@implementation Sura

+ (NSArray <NSNumber *> *)suraCharsCount{
    static NSArray *charsCount;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        charsCount = [Sura readNumbersFromFile:@"charcount"];
    } );
    
    return charsCount;
}

+ (NSArray <NSNumber *> *)suraVerseCount{
    static NSArray *verseCount;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        verseCount = [Sura readNumbersFromFile:@"versecount"];
    } );
    
    return verseCount;
}

+ (NSArray <NSNumber *> *)suraWordCount{
    static NSArray *wordCount;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wordCount = [Sura readNumbersFromFile:@"wordcount"];
    } );
    
    return wordCount;
}

+ (NSArray <NSNumber *> *)suraRevalOrder{
    static NSArray *revalOrder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        revalOrder = [Sura readNumbersFromFile:@"reval"];
    } );
    
    return revalOrder;
}


+ (NSArray <NSString *>*)suraNames{
    static NSArray *suraNames;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        suraNames = @[@"Al-Fatiha",
                      @"Al-Baqara",
                      @"Al Imran",
                      @"An-Nisa",
                      @"Al-Ma'ida",
                      @"Al-An'am",
                      @"Al-A'raf",
                      @"Al-Anfal",
                      @"At-Tawba",
                      @"Yunus",
                      @"Hud",
                      @"Yusuf",
                      @"Ar-Ra'd",
                      @"Ibrahim",
                      @"Al-Hijr",
                      @"An-Nahl",
                      @"Al-Isra",
                      @"Al-Kahf",
                      @"Maryam",
                      @"Ta-Ha",
                      @"Al-Anbiya",
                      @"Al-Hajj",
                      @"Al-Mu'minoon",
                      @"An-Nur",
                      @"Al-Furqan",
                      @"Ash-Shu'ara",
                      @"An-Naml",
                      @"Al-Qasas",
                      @"Al-Ankabut",
                      @"Ar-Rum",
                      @"Luqman",
                      @"As-Sajda",
                      @"Al-Ahzab",
                      @"Saba",
                      @"Fatir",
                      @"Ya Sin",
                      @"As-Saaffat",
                      @"Sad",
                      @"Az-Zumar",
                      @"Ghafir",
                      @"Fussilat",
                      @"Ash-Shura",
                      @"Az-Zukhruf",
                      @"Ad-Dukhan",
                      @"Al-Jathiya",
                      @"Al-Ahqaf",
                      @"Muhammad",
                      @"Al-Fath",
                      @"Al-Hujurat",
                      @"Qaf",
                      @"Adh-Dhariyat",
                      @"At-Tur",
                      @"An-Najm",
                      @"Al-Qamar",
                      @"Ar-Rahman",
                      @"Al-Waqi'a",
                      @"Al-Hadid",
                      @"Al-Mujadila",
                      @"Al-Hashr",
                      @"Al-Mumtahina",
                      @"As-Saff",
                      @"Al-Jumua",
                      @"Al-Munafiqun",
                      @"At-Taghabun",
                      @"At-Talaq",
                      @"At-Tahrim",
                      @"Al-Mulk",
                      @"Al-Qalam",
                      @"Al-Haaqqa",
                      @"Al-Maarij",
                      @"Nuh",
                      @"Al-Jinn",
                      @"Al-Muzzammil",
                      @"Al-Muddathir",
                      @"Al-Qiyama",
                      @"Al-Insan",
                      @"Al-Mursalat",
                      @"An-Naba",
                      @"An-Naziat",
                      @"Abasa",
                      @"At-Takwir",
                      @"Al-Infitar",
                      @"Al-Mutaffifin",
                      @"Al-Inshiqaq",
                      @"Al-Burooj",
                      @"At-Tariq",
                      @"Al-Ala",
                      @"Al-Ghashiya",
                      @"Al-Fajr",
                      @"Al-Balad",
                      @"Ash-Shams",
                      @"Al-Lail",
                      @"Ad-Dhuha",
                      @"Al-Inshirah",
                      @"At-Tin",
                      @"Al-Alaq",
                      @"Al-Qadr",
                      @"Al-Bayyina",
                      @"Az-Zalzala",
                      @"Al-Adiyat",
                      @"Al-Qaria",
                      @"At-Takathur",
                      @"Al-Asr",
                      @"Al-Humaza",
                      @"Al-Fil",
                      @"Quraysh",
                      @"Al-Ma'un",
                      @"Al-Kawthar",
                      @"Al-Kafirun",
                      @"An-Nasr",
                      @"Al-Masadd",
                      @"Al-Ikhlas",
                      @"Al-Falaq",
                      @"Al-Nas"
                      ];
    });
    
    return suraNames;
}

+ (NSArray<NSNumber *> *)readNumbersFromFile:(NSString *)fileName{
    NSArray<NSString *> *lines = [[self class] readLinesFromFile:fileName];
    NSMutableArray <NSNumber *> *numbers = @[].mutableCopy;
    
    for (NSString *line in lines) {
        NSNumber *number = [NSNumber numberWithDouble:[line doubleValue]];
        [numbers addObject:number];
        NSLog(@"Parsed number: %@\n", number);
    }
    
    return numbers.copy;
}


+ (NSArray<NSString *> *)readLinesFromFile:(NSString *)fileName{
    NSString* fileRoot = [[NSBundle mainBundle]
                          pathForResource:fileName ofType:@"txt"];
    if (!fileRoot) {
        NSLog(@"File not found: %@", fileName);
        return nil;
    }
    NSString* fileContents = [NSString stringWithContentsOfFile:fileRoot
                                                       encoding:NSUTF8StringEncoding error:nil];
    
    // first, separate by new line
    NSArray* allLinedStrings = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString *line in allLinedStrings) {
        NSLog(@"Read line: %@\n", line);
    }
    
    return allLinedStrings;
}

@end
