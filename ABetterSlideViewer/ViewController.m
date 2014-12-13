//
//  ViewController.m
//  ABetterSlideViewer
//
//  Created by Al on 12/7/14.
//  Copyright (c) 2014 thatnamegroup. All rights reserved.
//

#import "ViewController.h"

@interface ViewController()
@property (strong) IBOutlet NSTextField *keyCaptureTextField;
@property (strong) IBOutlet NSTextField *sourcePath;
@property (strong) IBOutlet NSTextField *destinationPath;
@property (strong) IBOutlet NSImageView *imageView;

@end

@implementation ViewController

NSString *sourceTopPath;
NSMutableArray *sourcePaths;
NSInteger currentIndex = -1;

float playInterval = 2.0f;
NSTimer *playTimer = nil;
bool playRunning = false;


- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self.view setWantsLayer: YES];
    [self.view.layer setBackgroundColor: [NSColor blackColor].CGColor];
    [self.sourcePath setBackgroundColor:[NSColor blackColor]];
    [self.sourcePath setTextColor:[NSColor grayColor]];
    [self.destinationPath setBackgroundColor:[NSColor blackColor]];
    [self.destinationPath setTextColor:[NSColor grayColor]];
    [self.imageView setWantsLayer: YES];
    [self.imageView.layer setBackgroundColor: [NSColor blackColor].CGColor];
 

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *keyValue = [prefs stringForKey:@"keyForSourceTopPath"];
    if (keyValue != nil) {
        sourceTopPath = keyValue;
        [self loadPaths];
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

// Capture any keyUp events and interpret as view options
- (void)keyUp:(NSEvent *)theEvent {
    // TODO: should use some #define for keycodes instead of magic numbers
    NSLog(@"%d",[theEvent keyCode]);
    switch ([theEvent keyCode]) {
        case 1: // s, source
            [self pickSource];
            break;
        case 2: // d, destination
            NSLog(@"d");
            break;
        case 125: // v, play/pause
            [self playPause];
            break;
        case 124: // > next
            // pause, op, play to keep timing of play in sync
            [self pause];
            [self nextImage];
            [self play];
            break;
        case 123: // < prev
            // pause, op, play to keep timing of play in sync
            [self pause];
            [self previousImage];
            [self play];
            break;
        case 45: // n, next folder
            // pause, op, play to keep timing of play in sync
            [self pause];
            [self nextDirectory];
            [self play];
            break;
        case 35: // p, previous folder
            // pause, op, play to keep timing of play in sync
            [self pause];
            [self previousDirectory];
            [self play];
            break;
        case 49: // space, copy
            NSLog(@"space");
            break;
        case 8: // c, copy
            NSLog(@"c");
            break;
        case 32: // u, undo
            NSLog(@"u");
            break;
        case 4: // h, help
            NSLog(@"h");
            break;
        case 44: // / or ?, help
            NSLog(@"?");
            break;
        
        default:
            break;
    }
    [self.keyCaptureTextField setStringValue:@""]; // clear
}

- (void) underConstruction {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Under Construction."];
    [alert runModal];
}

- (IBAction)toolbarAction:(id)sender {
    //NSLog(@"%@",[sender label]);
    switch ([sender tag]) {
        case 1: // source
            [self pickSource];
            break;
        case 2: // destination
            NSLog(@"d");
            break;
        case 3: // play
            [self playPause];
            break;
        case 4: // next
            // pause, op, play to keep timing of play in sync
            [self pause];
            [self nextImage];
            [self play];
            break;
        case 5: // prev
            // pause, op, play to keep timing of play in sync
            [self pause];
            [self previousImage];
            [self play];
            break;
        case 7: // next folder
            // pause, op, play to keep timing of play in sync
            [self pause];
            [self nextDirectory];
            [self play];
            break;
        case 6: // previous folder
            // pause, op, play to keep timing of play in sync
            [self pause];
            [self previousDirectory];
            [self play];
            break;
        case 8: // copy
            [self underConstruction];
           break;
        case 9: // undo
            [self underConstruction];
            break;
        case 10: // help
            [self underConstruction];
            break;
            
        default:
            break;
    }
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

- (void) loadPaths {
    
    if (sourceTopPath != nil) {
        sourcePaths = [[NSMutableArray alloc] init];
        // Enumerators are recursive
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:sourceTopPath] ;
        NSString *filePath;
        sourcePaths = [[NSMutableArray alloc] init];
        while ( (filePath = [enumerator nextObject] ) != nil ){
            // If we have the right type of file, add it to the list
            // Make sure to prepend the directory path
            //if( [[filePath pathExtension] isEqualToString:@"jpg"] || [[filePath pathExtension] isEqualToString:@"JPG"] ){
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
// TODO: doesn't seem to change things    [image setBackgroundColor:[NSColor blackColor]];
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

    bool done = false;
    NSInteger thisIndex = currentIndex;
    while (!done) {
        // set next index
        NSInteger nextIndex = thisIndex + 1;
        if (nextIndex >= sourcePaths.count)
            nextIndex = 0;
        
        // get base path
        NSString *thisDir = [sourcePaths[thisIndex] stringByDeletingLastPathComponent];
        NSString *nextDir = [sourcePaths[nextIndex] stringByDeletingLastPathComponent];
        
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
    
    bool done = false;
    NSInteger thisIndex = currentIndex;
    while (!done) {
        // set next index
        NSInteger nextIndex = thisIndex - 1;
        if (nextIndex < 0)
            nextIndex = sourcePaths.count-1;
       
        // get base path
        NSString *thisDir = [sourcePaths[thisIndex] stringByDeletingLastPathComponent];
        NSString *nextDir = [sourcePaths[nextIndex] stringByDeletingLastPathComponent];
        
        if (![thisDir isEqualToString:nextDir]) {
            // found a different directory
            currentIndex = nextIndex;
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

@end


// TODO - UI OP
// - key capture over other components
// - try first responder again???
// - try menu items again???
// - fix stretch
// - use cocoa toolbar for buttons

// TODO - FEATURES
// - destination
// - copy
// - undo

// TODO - UI LOOK
// - black behind image
// - images for buttons
// - icons for app

// - installer
// - sign app



