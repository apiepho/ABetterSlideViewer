//
//  ViewController.m
//  ABetterSlideViewer
//
//  Created by Al on 12/7/14.
//  Copyright (c) 2014 thatnamegroup. All rights reserved.
//

#import "ViewController.h"

@interface ViewController()
@property (strong) IBOutlet NSTextField *sourcePath;
@property (strong) IBOutlet NSTextField *destinationPath;
@property (strong) IBOutlet NSImageView *imageView;

// HACK to get first responder actions so menu items are enabledd
@property (strong) IBOutlet NSTextField *focusTextField;

@end

@implementation ViewController

const float PLAY_INTERVAL_2S            = 2.0f;
const float PLAY_INTERVAL_10S           = 10.0f;
const float PLAY_INTERVAL_30S           = 30.0f;
const float PLAY_INTERVAL_1M            = 60.0f;

const NSInteger TAG_SOURCE              = 1;
const NSInteger TAG_DESTINATION         = 2;
const NSInteger TAG_PLAYPAUSE           = 3;
const NSInteger TAG_NEXT                = 4;
const NSInteger TAG_PREVIOUS            = 5;
const NSInteger TAG_NEXTFOLDER          = 7;
const NSInteger TAG_PREVFOLDER          = 6;
const NSInteger TAG_COPY                = 8;
const NSInteger TAG_UNDO                = 9;
const NSInteger TAG_HELP                = 10;
const NSInteger TAG_PLAYINTERVAL_START  = 21;
const NSInteger TAG_PLAYINTERVAL_2S     = 21;
const NSInteger TAG_PLAYINTERVAL_10S    = 22;
const NSInteger TAG_PLAYINTERVAL_30S    = 23;
const NSInteger TAG_PLAYINTERVAL_1M     = 24;
const NSInteger TAG_PLAYINTERVAL_END    = 24;
const NSInteger TAG_COPYTYPE_START      = 31;
const NSInteger TAG_COPYTYPE_MIRROR     = 31;
const NSInteger TAG_COPYTYPE_BYMONTH    = 32;
const NSInteger TAG_COPYTYPE_BYYEAR     = 33;
const NSInteger TAG_COPYTYPE_SINGLEFLDR = 34;
const NSInteger TAG_COPYTYPE_END        = 34;
const NSInteger TAG_DATEBY_START        = 41;
const NSInteger TAG_DATEBY_FOLDER       = 41;
const NSInteger TAG_DATEBY_META         = 42;
const NSInteger TAG_DATEBY_END          = 42;
const NSInteger TAG_IMAGE_INFO          = 51;


NSString *destinationTopPath;
NSString *sourceTopPath;
NSMutableArray *sourcePaths;
NSInteger currentIndex = -1;

float playInterval = PLAY_INTERVAL_2S;
NSTimer *playTimer = nil;
bool playRunning = false;

NSInteger copyType = TAG_COPYTYPE_MIRROR;
NSInteger dateBy = TAG_DATEBY_FOLDER;

NSMutableArray *history;


- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    // DEBUG: Use this to clear User defaults for program
    //NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    //[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    // Set text and all background colors
    [self.view setWantsLayer: YES];
    [self.view.layer setBackgroundColor: [NSColor blackColor].CGColor];
    [self.sourcePath setTextColor:[NSColor whiteColor]];
    [self.destinationPath setTextColor:[NSColor whiteColor]];
    [self.imageView setWantsLayer: YES];
    [self.imageView.layer setBackgroundColor: [NSColor blackColor].CGColor];

    // HACK to get first responder actions so menu items are enable
    //      need to have a textField or something focusable to get menu and toolbar
    //      items to work.
    [self.focusTextField setAlphaValue:1.0];
    [self.focusTextField setFocusRingType:NSFocusRingTypeNone];

    // Get user preferences for source and destination
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *keyValue;
    keyValue = [prefs stringForKey:@"keyForSourceTopPath"];
    if (keyValue != nil) {
        sourceTopPath = keyValue;
        [self loadPaths];
    }
    keyValue = [prefs stringForKey:@"keyForDestinationTopPath"];
    if (keyValue != nil) {
        destinationTopPath = keyValue;
        self.destinationPath.stringValue = destinationTopPath;
    }

    // Set default play interval
    playInterval = PLAY_INTERVAL_2S;
    [self setSelectedInMenuRange: PLAY_INTERVAL_2S tagStart:TAG_PLAYINTERVAL_START tagEnd:TAG_PLAYINTERVAL_END];
    // Get user preferences for play interval
    keyValue = [prefs stringForKey:@"keyForPlayInterval"];
    if (keyValue != nil) {
        playInterval = [keyValue floatValue];
     }
    keyValue = [prefs stringForKey:@"keyForPlayIntervalTag"];
    if (keyValue != nil) {
        [self setSelectedInMenuRange:[keyValue integerValue] tagStart:TAG_PLAYINTERVAL_START tagEnd:TAG_PLAYINTERVAL_END];
    }
 
    // Set default copy type
    copyType = TAG_COPYTYPE_MIRROR;
    [self setSelectedInMenuRange: TAG_COPYTYPE_MIRROR tagStart:TAG_COPYTYPE_START tagEnd:TAG_COPYTYPE_END];
    // Get user preferences for copy type
    keyValue = [prefs stringForKey:@"keyForCopyTypeTag"];
    if (keyValue != nil) {
        copyType = [keyValue intValue];
        [self setSelectedInMenuRange:copyType tagStart:TAG_COPYTYPE_START tagEnd:TAG_COPYTYPE_END];
    }

    // Set default date by
    dateBy = TAG_DATEBY_FOLDER;
    [self setSelectedInMenuRange: TAG_DATEBY_FOLDER tagStart:TAG_DATEBY_START tagEnd:TAG_DATEBY_END];
    // Get user preferences for date by
    keyValue = [prefs stringForKey:@"keyForDateByTag"];
    if (keyValue != nil) {
        dateBy = [keyValue intValue];
        [self setSelectedInMenuRange:dateBy tagStart:TAG_DATEBY_START tagEnd:TAG_DATEBY_END];
    }

    history = [[NSMutableArray alloc] init];
}


// HACK to get first responder actions so menu items are enable
//      since text area is in focus, it captures characters that should
//      be processed by menu item extended char
- (IBAction)keyUp:(NSEvent *)theEvent {
    [self.focusTextField setAlphaValue:0.0];
    NSInteger tag = 0;
    switch ([theEvent.characters characterAtIndex:0]) {
        case ' ': tag = TAG_PLAYPAUSE;  break;
        case 'c': tag = TAG_COPY;       break;
        case 'i': tag = TAG_IMAGE_INFO; break;
        case 'u': tag = TAG_UNDO;       break;
    }
    [self.focusTextField setStringValue:@""];
    [self handleAction:tag];
}

- (void) underConstruction {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Under Construction."];
    [alert runModal];
}

- (IBAction)toolbarAction:(id)sender {
    [self.focusTextField setAlphaValue:0.0];
    [self handleAction:[sender tag]];
}

- (IBAction) menuItemAction:(id)sender {
    [self.focusTextField setAlphaValue:0.0];
    [self handleAction:[sender tag]];
}

- (void) setSelectedInMenuRange:(NSInteger)tag tagStart:(NSInteger)tagStart tagEnd:(NSInteger)tagEnd
{
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    for (NSMenuItem *item in [mainMenu itemArray]) {
        if ([[item title] isEqualToString:@"Settings"]) {
            NSMenu *subMenu = [item submenu];
            for (NSMenuItem *subItem in [subMenu itemArray]) {
                //NSLog(@"%@", [subItem title]);
                if (tagStart <= subItem.tag && subItem.tag <= tagEnd) {
                    [subItem setState:0];
                }
                if (subItem.tag == tag) {
                    [subItem setState:1];
                }
            }
        }
    }
}




#pragma mark "Internal"
// TODO: split these out to another class?

- (void) pickSource {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.title                   = @"Choose a directory of pictures to show";
    panel.showsResizeIndicator    = YES;
    panel.showsHiddenFiles        = NO;
    panel.canChooseDirectories    = YES;
    panel.canChooseFiles          = NO;
    panel.allowsMultipleSelection = NO;
    
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *selection = panel.URLs[0];
            sourceTopPath = [selection.path stringByResolvingSymlinksInPath];
            //NSLog(@"soure TOP path: %@", sourceTopPath);
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:sourceTopPath forKey:@"keyForSourceTopPath"];
            [self loadPaths];
        }
    }];
}

- (void) pickDestination {
    NSSavePanel* panel = [NSSavePanel savePanel];
    panel.title                   = @"Choose a directory for copying pictures";
    panel.showsResizeIndicator    = YES;
    panel.showsHiddenFiles        = NO;
    panel.canCreateDirectories    = YES;
    
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *selection = [panel URL];
            destinationTopPath = [selection.path stringByResolvingSymlinksInPath];
            //NSLog(@"destination TOP path: %@", destinationTopPath);
            
            self.destinationPath.stringValue = destinationTopPath;

            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:destinationTopPath forKey:@"keyForDestinationTopPath"];
        }
    }];
}

- (void) loadPaths {
    
    if (sourceTopPath != nil) {
        sourcePaths = [[NSMutableArray alloc] init];
        // Enumerators are recursive
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:sourceTopPath] ;
        NSString *filePath;
        sourcePaths = [[NSMutableArray alloc] init];
        while ( (filePath = [enumerator nextObject] ) != nil ){
            // If we have the right type of file, add it to the list
            NSMutableArray *supported = [[NSMutableArray alloc] initWithObjects:@"jpg", @"JPG" , nil];
            if( [supported containsObject:[filePath pathExtension]]){
                [sourcePaths addObject:[sourceTopPath stringByAppendingPathComponent: filePath]];
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
    NSString *name = sourcePaths[currentIndex];
    self.sourcePath.stringValue = name;
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:name];
    [self.imageView setImage: image];
}

- (void) nextImage {
    currentIndex++;
    if (currentIndex >= sourcePaths.count)
        currentIndex = 0;
    [self updateImage];
}

- (void) previousImage {
    NSString *name = sourcePaths[currentIndex];
    self.sourcePath.stringValue = name;
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

- (NSString *) getDestinationPath:(NSString *) srcPath {
    NSString *result;
    NSString *temp1;
    NSString *temp2;

    // use mirror form as default
    result = [srcPath stringByReplacingOccurrencesOfString:sourceTopPath withString:destinationTopPath];

    switch (copyType) {
        case TAG_COPYTYPE_MIRROR:
            // use default
            break;
        case TAG_COPYTYPE_BYMONTH:
            {
                // assume last folder is named with a date like 2014-01(Jan)...
                // will copy to <dest>/<yyyy>/<mm>
                // grab string for last
                temp1 = [result stringByDeletingLastPathComponent];
                temp2 = [temp1 lastPathComponent];
                // parse for year and month
                NSScanner *parser = [NSScanner scannerWithString:temp2];
                int year;
                int month;
                [parser scanInt:&year];
                [parser scanString:@"-" intoString:nil];
                [parser scanInt:&month];
                // build new dest path from year and month
                temp1 = [@"" stringByAppendingFormat:@"%04d", year];
                temp2 = [@"" stringByAppendingFormat:@"%02d", month];
                result = [destinationTopPath stringByAppendingPathComponent:temp1];
                result = [result stringByAppendingPathComponent:temp2];
                // append actual filename
                result = [result stringByAppendingPathComponent:[srcPath lastPathComponent]];
            }
            break;
        case TAG_COPYTYPE_BYYEAR:
            {
                // assume last folder is named with a date like 2014-01(Jan)...
                // will copy to <dest>/<yyyy>
                // grab string for last
                temp1 = [result stringByDeletingLastPathComponent];
                temp2 = [temp1 lastPathComponent];
                // parse for year and month
                NSScanner *parser = [NSScanner scannerWithString:temp2];
                int year;
                [parser scanInt:&year];
                // build new dest path from year and month
                temp1 = [@"" stringByAppendingFormat:@"%04d", year];
                result = [destinationTopPath stringByAppendingPathComponent:temp1];
                // append actual filename
                result = [result stringByAppendingPathComponent:[srcPath lastPathComponent]];
            }
            break;
        case TAG_COPYTYPE_SINGLEFLDR:
            {
                // copy all images to single file, change img.jpg to img-1.jpg if neccessary
                temp1 = [srcPath lastPathComponent];
                result = [destinationTopPath stringByAppendingPathComponent:temp1];
           }
            break;
    }

    result = [self getUniquePathname: result];
    return result;
}

- (void) copyCurrent {
    if (self.destinationPath != nil) {
        NSError *error;;
        NSString *srcPath = sourcePaths[currentIndex];
        NSString *dstPath = [self getDestinationPath: srcPath];
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
    [self setSelectedInMenuRange: tag tagStart:TAG_PLAYINTERVAL_START tagEnd:TAG_PLAYINTERVAL_END];

    NSString *str;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    str = [NSString stringWithFormat:@"%f", playInterval];
    [prefs setObject:str forKey:@"keyForPlayInterval"];
    str = [NSString stringWithFormat:@"%ld", tag];
    [prefs setObject:str forKey:@"keyForPlayIntervalTag"];
    
    [self play];
}

- (void) setCopyType:(NSInteger) tag {
    copyType = tag;
    [self setSelectedInMenuRange: tag tagStart:TAG_COPYTYPE_START tagEnd:TAG_COPYTYPE_END];
    
    NSString *str;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    str = [NSString stringWithFormat:@"%ld", tag];
    [prefs setObject:str forKey:@"keyForCopyTypeTag"];
}

- (void) setDateBy:(NSInteger) tag {
    dateBy = tag;
    [self setSelectedInMenuRange: tag tagStart:TAG_DATEBY_START tagEnd:TAG_DATEBY_END];
    
    NSString *str;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    str = [NSString stringWithFormat:@"%ld", tag];
    [prefs setObject:str forKey:@"keyForDateByTag"];
}


- (void) currentImageInfo {
    // TODO create image info window that can be reused for each image
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
    NSLog(@"%@", exif);
    // example of parsing exif dictionary
    // using photo frm Lumina 928, the values are reversed
    float latitude = [[[exif objectForKey:@"{GPS}"] valueForKey:@"Latitude"] floatValue];
    float longitude = [[[exif objectForKey:@"{GPS}"] valueForKey:@"Longitude"] floatValue];
    NSLog(@"GPS Longitude, Latitude:  %f, %f", longitude, latitude);

}

- (void)handleAction:(NSInteger)tag {
    switch (tag) {
        case TAG_SOURCE:
            [self pickSource];
            break;
        case TAG_DESTINATION:
            [self pickDestination];
            break;
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
        case TAG_HELP:
            [self underConstruction];
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
            [self setCopyType: tag];
            break;

        case TAG_DATEBY_FOLDER:
        case TAG_DATEBY_META:
            [self setDateBy: tag];
            break;

        case TAG_IMAGE_INFO:
            [self currentImageInfo];
            break;
            
        default:
            break;
    }
}

@end


// TODO - FEATURES
// - menu options for
//      type of copy (mirror vs by month)
//      background colors
//      add option to enter folder date pattern
// - implement date by
// - refactor copy type

// TODO - UI
// - fix first responder for toolbar and menubar someday
// - black behind image
// - better images for toolbar buttons
// - image for app

// TODO - CODE
// - refactor this file into controller and model, seperate files (this getting to long)

// - installer
// - sign app




