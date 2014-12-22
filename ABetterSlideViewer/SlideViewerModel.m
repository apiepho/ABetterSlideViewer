//
//  SlideViewerModel.m
//  ABetterSlideViewer
//
//  Created by Al on 12/22/14.
//  Copyright (c) 2014 thatnamegroup. All rights reserved.
//

#import "SlideViewerModel.h"

@implementation SlideViewerModel

NSMutableArray *sourcePaths;
NSInteger currentIndex = -1;

float playInterval = PLAY_INTERVAL_2S;
NSTimer *playTimer = nil;
bool playRunning = false;

NSMutableArray *history;

- (instancetype)init {
    self = [super init];
    if (self) {
        // Get user preferences for source and destination
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *keyValue;
        keyValue = [prefs stringForKey:@"keyForSourceTopPath"];
        if (keyValue != nil) {
            _sourceTopPath = keyValue;
            [self loadPaths];
        }
        keyValue = [prefs stringForKey:@"keyForDestinationTopPath"];
        if (keyValue != nil) {
            _destinationTopPath = keyValue;
        }
        
        // Set default play interval
        playInterval = PLAY_INTERVAL_2S;
        _playIntervalTag = TAG_PLAYINTERVAL_2S;
        // Get user preferences for play interval
        keyValue = [prefs stringForKey:@"keyForPlayInterval"];
        if (keyValue != nil) {
            playInterval = [keyValue floatValue];
        }
        keyValue = [prefs stringForKey:@"keyForPlayIntervalTag"];
        if (keyValue != nil) {
            _playIntervalTag = [keyValue integerValue];
        }
        
        // Set default copy type
        _copyTypeTag = TAG_COPYTYPE_MIRROR;
        // Get user preferences for copy type
        keyValue = [prefs stringForKey:@"keyForCopyTypeTag"];
        if (keyValue != nil) {
            _copyTypeTag = [keyValue intValue];
        }
        
        // Set default date by
        _dateByTag = TAG_DATEBY_FOLDER;
        // Get user preferences for date by
        keyValue = [prefs stringForKey:@"keyForDateByTag"];
        if (keyValue != nil) {
            _dateByTag = [keyValue intValue];
        }
        
        history = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) loadPaths {
    
    if (_sourceTopPath != nil) {
        sourcePaths = [[NSMutableArray alloc] init];
        // Enumerators are recursive
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:_sourceTopPath] ;
        NSString *filePath;
        sourcePaths = [[NSMutableArray alloc] init];
        while ( (filePath = [enumerator nextObject] ) != nil ){
            // If we have the right type of file, add it to the list
            NSMutableArray *supported = [[NSMutableArray alloc] initWithObjects:@"jpg", @"JPG" , nil];
            if( [supported containsObject:[filePath pathExtension]]){
                [sourcePaths addObject:[_sourceTopPath stringByAppendingPathComponent: filePath]];
            }
        }
        //NSLog(@"source files: \n%@", sourcePaths);
        currentIndex = -1;
        [self nextImage];
    }
}

- (void) updateImage {
    if (currentIndex == -1) return;
    if (sourcePaths.count == 0) return;
    _sourcePath = sourcePaths[currentIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateSourceLabel" object:_sourcePath];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateImage" object:_sourcePath];
}

- (void) nextImage {
    currentIndex++;
    if (currentIndex >= sourcePaths.count)
        currentIndex = 0;
    [self updateImage];
}

- (void) previousImage {
    currentIndex--;
    if (currentIndex < 0)
        currentIndex = sourcePaths.count-1;
    [self updateImage];
}

- (void) nextDirectory {
    if (currentIndex == -1) return;
    if (sourcePaths.count < 2) return;
    
    NSString *thisDir;
    NSString *nextDir;
    NSInteger nextIndex;
    
    bool done = false;
    NSInteger thisIndex = currentIndex;
    // cycle forward until find different last directory
    while (!done) {
        // set next index
        nextIndex = thisIndex + 1;
        if (nextIndex >= sourcePaths.count)
            nextIndex = 0;
        
        // get base path
        thisDir = [sourcePaths[thisIndex] stringByDeletingLastPathComponent];
        nextDir = [sourcePaths[nextIndex] stringByDeletingLastPathComponent];
        
        if (![thisDir isEqualToString:nextDir]) {
            // found a different directory
            currentIndex = nextIndex;
            done = true;
        } else if (thisIndex == sourcePaths.count-1) {
            // have checked all paths
            done = true;
        } else {
            // move to next directory
            thisIndex++;
        }
    }
    [self updateImage];
}

- (void) previousDirectory {
    if (currentIndex == -1) return;
    if (sourcePaths.count < 2) return;
    
    NSString *thisDir;
    NSString *nextDir;
    NSInteger nextIndex;
    
    bool done = false;
    NSInteger thisIndex = currentIndex;
    // cycle backward until find different last directory
    while (!done) {
        // set next index
        nextIndex = thisIndex - 1;
        if (nextIndex < 0)
            nextIndex = sourcePaths.count-1;
        
        // get base path
        thisDir = [sourcePaths[thisIndex] stringByDeletingLastPathComponent];
        nextDir = [sourcePaths[nextIndex] stringByDeletingLastPathComponent];
        
        if (![thisDir isEqualToString:nextDir]) {
            // found a different directory
            currentIndex = nextIndex;
            
            // keep cyling to first image in this dir
            thisIndex = nextIndex;
            
            bool innerDone = false;
            // cycle backward until find different last directory
            while (!innerDone) {
                // set next index
                nextIndex = thisIndex - 1;
                if (nextIndex < 0)
                    nextIndex = sourcePaths.count-1;
                
                // get base path
                thisDir = [sourcePaths[thisIndex] stringByDeletingLastPathComponent];
                nextDir = [sourcePaths[nextIndex] stringByDeletingLastPathComponent];
                
                if (![thisDir isEqualToString:nextDir]) {
                    // found a different directory
                    currentIndex = thisIndex;
                    
                    innerDone = true;
                } else if (thisIndex == 0) {
                    // have checked all paths
                    innerDone = true;
                } else {
                    // move to next directory
                    thisIndex--;
                }
            }
            
            done = true;
        } else if (thisIndex == 0) {
            // have checked all paths
            done = true;
        } else {
            // move to next directory
            thisIndex--;
        }
    }
    [self updateImage];
}

- (void) play {
    if (playRunning && playTimer == nil) {
        playTimer = [NSTimer scheduledTimerWithTimeInterval:playInterval
                                                     target:self
                                                   selector:@selector(nextImage)
                                                   userInfo:nil
                                                    repeats:YES];
    }
}

- (void) pause {
    if (playRunning && playTimer != nil) {
        [playTimer invalidate];
        playTimer = nil;
    }
}

- (void) playPause {
    if (playTimer == nil) {
        playRunning = true;
        [self play];
    } else {
        [self pause];
        playRunning = false;
    }
}

- (NSString *) getUniquePathname:(NSString *) given {
    NSString *temp;
    NSString *working;
    NSString *result;
    
    working = [given stringByAppendingString:@""];
    int count = 1;
    while ([[NSFileManager defaultManager] fileExistsAtPath:working]) {
        // start with given
        working = [given stringByAppendingString:@""];
        // get extension
        temp = [@"." stringByAppendingString:[working pathExtension]];
        // remove extension
        working = [working stringByReplacingOccurrencesOfString:temp withString:@""];
        // add -<count>
        working = [working stringByAppendingFormat:@"-%d", count];
        // add back extension
        working = [working stringByAppendingString:temp];
        count++;
    }
    result = [working stringByAppendingString:@""];
    return result;
}

- (void) getCopyDateInfo:(NSString *)srcPath year:(int *)year month:(int *)month {
    NSString *temp1;
    NSString *temp2;
    
    *year = 2000;
    *month = 1;

    switch (_dateByTag) {
        case TAG_DATEBY_META:
            {
                NSDictionary* exif = nil;
                NSURL* url = [NSURL fileURLWithPath: srcPath];
                CGImageSourceRef source = CGImageSourceCreateWithURL ( (__bridge CFURLRef) url, NULL);
                if (source) {
                    // get image properties
                    CFDictionaryRef metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
                    if (metadata) {
                        // cast to NSDictionary
                        exif = [NSDictionary dictionaryWithDictionary : (__bridge NSDictionary *)metadata];
                        CFRelease (metadata);
                    }
                    CFRelease(source);
                    source = nil;
                }
                temp1 = [[exif objectForKey:@"{Exif}"] valueForKey:@"DateTimeOriginal"];
                if (temp1 != nil) {
                    NSScanner *parser = [NSScanner scannerWithString:temp1];
                    [parser scanInt:year];
                    [parser scanString:@":" intoString:nil];
                    [parser scanInt:month];
                    return;
                }
            }
            // intentionally fall thru if exif date not found
            //break;
        case TAG_DATEBY_FOLDER:
            {
                // assume last folder is named with a date like 2014-01(Jan)...
                // will copy to <dest>/<yyyy>/<mm>
                // grab string for last
                temp1 = [srcPath stringByDeletingLastPathComponent];
                temp2 = [temp1 lastPathComponent];
                // parse for year and month
                NSScanner *parser = [NSScanner scannerWithString:temp2];
                [parser scanInt:year];
                [parser scanString:@"-" intoString:nil];
                [parser scanInt:month];
            }
            break;
    }
}


- (NSString *) getCopyDestinationPath:(NSString *) srcPath {
    NSString *result;
    NSString *temp1;
    NSString *temp2;
    int year;
    int month;
    
    // use mirror form as default
    result = [srcPath stringByReplacingOccurrencesOfString:_sourceTopPath withString:_destinationTopPath];
    
    switch (_copyTypeTag) {
        case TAG_COPYTYPE_MIRROR:
            // use default
            break;
        case TAG_COPYTYPE_BYMONTH:
        {
            [self getCopyDateInfo:srcPath year: &year month: &month];
            // build new dest path from year and month
            temp1 = [@"" stringByAppendingFormat:@"%04d", year];
            temp2 = [@"" stringByAppendingFormat:@"%02d", month];
            result = [_destinationTopPath stringByAppendingPathComponent:temp1];
            result = [result stringByAppendingPathComponent:temp2];
            // append actual filename
            result = [result stringByAppendingPathComponent:[srcPath lastPathComponent]];
        }
            break;
        case TAG_COPYTYPE_BYYEAR:
        {
            [self getCopyDateInfo:srcPath year: &year month: &month];
            // build new dest path from year and month
            temp1 = [@"" stringByAppendingFormat:@"%04d", year];
            result = [_destinationTopPath stringByAppendingPathComponent:temp1];
            // append actual filename
            result = [result stringByAppendingPathComponent:[srcPath lastPathComponent]];
        }
            break;
        case TAG_COPYTYPE_SINGLEFLDR:
        {
            // copy all images to single file, change img.jpg to img-1.jpg if neccessary
            temp1 = [srcPath lastPathComponent];
            result = [_destinationTopPath stringByAppendingPathComponent:temp1];
        }
            break;
    }
    
    result = [self getUniquePathname: result];
    return result;
}

- (void) copyCurrent {
    if (self.destinationTopPath != nil) {
        NSError *error;;
        NSString *srcPath = sourcePaths[currentIndex];
        NSString *dstPath = [self getCopyDestinationPath: srcPath];
        NSString *dstPathBase = [dstPath stringByDeletingLastPathComponent];
        
        if (dstPath == nil) {
            NSLog(@"ERROR: COPY: dstPath is nil");
            return;
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:dstPath]) {
            BOOL success;
            success = [[NSFileManager defaultManager] createDirectoryAtPath:dstPathBase withIntermediateDirectories:YES attributes:nil error:&error];
            if (success) {
                success = [[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:dstPath error:&error];
                if (success) {
                    NSLog(@"COPY: source      file: %@", srcPath);
                    NSLog(@"COPY: destination file: %@", dstPath);
                    [history addObject:dstPath];
                }
            }
        }
    }
}

- (void) undoCopy {
    if (history.count > 0) {
        NSError *error;
        NSString *fileToUndo = [history lastObject];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileToUndo]) {
            //NSLog(@"UNDO: removing file: %@", fileToUndo);
            [[NSFileManager defaultManager] removeItemAtPath:fileToUndo error:&error];
            [history removeLastObject];
        }
    }
}

- (void) setPlayInterval:(NSInteger) tag {
    [self pause];
    switch (tag) {
        case TAG_PLAYINTERVAL_2S:
            playInterval = PLAY_INTERVAL_2S;
            break;
        case TAG_PLAYINTERVAL_10S:
            playInterval = PLAY_INTERVAL_10S;
            break;
        case TAG_PLAYINTERVAL_30S:
            playInterval = PLAY_INTERVAL_30S;
            break;
        case TAG_PLAYINTERVAL_1M:
            playInterval = PLAY_INTERVAL_1M;
            break;
        default:
            break;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdatePlayIntervalTag" object:nil];
    
    NSString *str;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    str = [NSString stringWithFormat:@"%f", playInterval];
    [prefs setObject:str forKey:@"keyForPlayInterval"];
    str = [NSString stringWithFormat:@"%ld", tag];
    [prefs setObject:str forKey:@"keyForPlayIntervalTag"];
    
    [self play];
}

- (void) setCopyTypeTag:(NSInteger) tag {
    _copyTypeTag = tag;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateCopyTypeTag" object:nil];
   
    NSString *str;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    str = [NSString stringWithFormat:@"%ld", tag];
    [prefs setObject:str forKey:@"keyForCopyTypeTag"];
}

- (void) setDateByTag:(NSInteger) tag {
    _dateByTag = tag;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateDateByTag" object:nil];
    
    NSString *str;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    str = [NSString stringWithFormat:@"%ld", tag];
    [prefs setObject:str forKey:@"keyForDateByTag"];
}


//- (void) currentImageInfo {
//    // TODO create image info window that can be reused for each image
//    NSDictionary* exif = nil;
//    NSURL* url = [NSURL fileURLWithPath: sourcePaths[currentIndex]];
//    
//    // get handle
//    CGImageSourceRef source = CGImageSourceCreateWithURL ( (__bridge CFURLRef) url, NULL);
//    if (source) {
//        // get image properties
//        CFDictionaryRef metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
//        if (metadata) {
//            // cast to NSDictionary
//            exif = [NSDictionary dictionaryWithDictionary : (__bridge NSDictionary *)metadata];
//            CFRelease (metadata);
//        }
//        CFRelease(source);
//        source = nil;
//    }
//    NSLog(@"%@", exif);
//    // example of parsing exif dictionary
//    float latitude = [[[exif objectForKey:@"{GPS}"] valueForKey:@"Latitude"] floatValue];
//    float longitude = [[[exif objectForKey:@"{GPS}"] valueForKey:@"Longitude"] floatValue];
//    NSString *latitudeRef = [[exif objectForKey:@"{GPS}"] valueForKey:@"LatitudeRef"];
//    NSString *longitudeRef = [[exif objectForKey:@"{GPS}"] valueForKey:@"LongitudeRef"];
//    if ([latitudeRef isEqualToString:@"S"])
//        latitude *= -1;
//    if ([longitudeRef isEqualToString:@"W"])
//        longitude *= -1;
//    NSLog(@"GPS Latitude, Longitude:  %f, %f", latitude, longitude);
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"ImageInformation" object:nil];
//    
//}

- (NSString *) getCurrentImageInfo {
    NSString *result;
    
    NSDictionary* exif = nil;
    NSURL* url = [NSURL fileURLWithPath: sourcePaths[currentIndex]];
    
    // get handle
    CGImageSourceRef source = CGImageSourceCreateWithURL ( (__bridge CFURLRef) url, NULL);
    if (source) {
        // get image properties
        CFDictionaryRef metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
        if (metadata) {
            // cast to NSDictionary
            exif = [NSDictionary dictionaryWithDictionary : (__bridge NSDictionary *)metadata];
            CFRelease (metadata);
        }
        CFRelease(source);
        source = nil;
    }
    result = [NSString stringWithFormat:@"%@", exif];
    return result;
}

- (void)handleAction:(NSInteger)tag {
    switch (tag) {
        case TAG_PLAYPAUSE:
            [self playPause];
            break;
        case TAG_NEXT:
            // pause, op, play to keep timing of play in sync
            [self pause];
            [self nextImage];
            [self play];
            break;
        case TAG_PREVIOUS:
            // pause, op, play to keep timing of play in sync
            [self pause];
            [self previousImage];
            [self play];
            break;
        case TAG_NEXTFOLDER:
            // pause, op, play to keep timing of play in sync
            [self pause];
            [self nextDirectory];
            [self play];
            break;
        case TAG_PREVFOLDER:
            // pause, op, play to keep timing of play in sync
            [self pause];
            [self previousDirectory];
            [self play];
            break;
        case TAG_COPY:
            [self copyCurrent];
            break;
        case TAG_UNDO:
            [self undoCopy];
            break;
            
        case TAG_PLAYINTERVAL_2S:
        case TAG_PLAYINTERVAL_10S:
        case TAG_PLAYINTERVAL_30S:
        case TAG_PLAYINTERVAL_1M:
            [self setPlayInterval: tag];
            break;
            
        case TAG_COPYTYPE_MIRROR:
        case TAG_COPYTYPE_BYMONTH:
        case TAG_COPYTYPE_BYYEAR:
        case TAG_COPYTYPE_SINGLEFLDR:
            [self setCopyTypeTag: tag];
            break;
            
        case TAG_DATEBY_FOLDER:
        case TAG_DATEBY_META:
            [self setDateByTag: tag];
            break;
            
        case TAG_IMAGE_INFO:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ImageInformation" object:nil];
            break;
            
        default:
            break;
    }
}

@end


// TODO - FEATURES
// - menu options for
//      background colors
// - user image for app, for toobar buttons
// - image info as window,
// - move source and destination labels to window
// - close and reopen info window
// - src /dest labels for info window
// - scroll for info
// - save pref of window open
// - move pref from view controller to model?


// TODO - UI
// - fix first responder for toolbar and menubar someday
// - black behind image
// - better images for toolbar buttons
// - image for app

// - installer
// - sign app

// pay for private github
