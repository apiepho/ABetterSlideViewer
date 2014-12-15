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

NSString *destinationTopPath;
NSString *sourceTopPath;
NSMutableArray *sourcePaths;
NSInteger currentIndex = -1;

float playInterval = 2.0f;
NSTimer *playTimer = nil;
bool playRunning = false;

NSMutableArray *history;


- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self.view setWantsLayer: YES];
    [self.view.layer setBackgroundColor: [NSColor blackColor].CGColor];
    [self.sourcePath setTextColor:[NSColor whiteColor]];
    [self.destinationPath setTextColor:[NSColor whiteColor]];
    [self.imageView setWantsLayer: YES];
    [self.imageView.layer setBackgroundColor: [NSColor blackColor].CGColor];

    // HACK to get first responder actions so menu items are enable
    //      need to have a textField or something focusable to get menu and toolbar
    //      items to work.
    [self.focusTextField setAlphaValue:0.0];
    [self.focusTextField setFocusRingType:NSFocusRingTypeNone];

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
    
    history = [[NSMutableArray alloc] init];
}

- (void) viewWillAppear {
    // HACK to get first responder actions so menu items are enable
    //      need to delay when t is set as first responder
   [self.focusTextField.window makeFirstResponder:self.focusTextField];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

// HACK to get first responder actions so menu items are enable
//      since text area is in focus, it captures characters that should
//      be processed by menu item extended char
- (IBAction)keyUp:(NSEvent *)theEvent {
    NSInteger tag = 0;
    switch ([theEvent.characters characterAtIndex:0]) {
        case 's': tag = 1; break;
        case 'd': tag = 2; break;
        case 'c': tag = 8; break;
        case 'u': tag = 9; break;
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
    [self handleAction:[sender tag]];
}

- (IBAction) menuItemAction:(id)sender {
    [self handleAction:[sender tag]];
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

- (void) copyCurrent {
    if (self.destinationPath != nil) {
        NSError *error;;
        NSString *srcPath = sourcePaths[currentIndex];
        NSString *dstPath = [srcPath stringByReplacingOccurrencesOfString:sourceTopPath withString:destinationTopPath];
        NSString *dstPathBase = [dstPath stringByDeletingLastPathComponent];

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
            NSLog(@"UNDO: removing file: %@", fileToUndo);
            [[NSFileManager defaultManager] removeItemAtPath:fileToUndo error:&error];
            [history removeLastObject];
        }
    }
}

- (void)handleAction:(NSInteger)tag {
    switch (tag) {
        case 1: // source
            [self pickSource];
            break;
        case 2: // destination
            [self pickDestination];
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
            [self copyCurrent];
            break;
        case 9: // undo
            [self undoCopy];
            break;
        case 10: // help
            [self underConstruction];
            break;
        default:
            break;
    }
}

@end


// TODO - UI OP
// - key capture over other components
// - try first responder again??? ... works if I have textfield in focus

// TODO - FEATURES
// - destination
// - copy
// - undo
// - menu options for
//      type of copy (mirror vs by month)
//      speed of play
//      background colors


// TODO - UI LOOK
// - black behind image

// - installer
// - sign app



