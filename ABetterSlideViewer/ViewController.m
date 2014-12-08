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
    // TODO: really should use some #define for keycodes instead of magic numbers
    NSLog(@"%d",[theEvent keyCode]);
    switch ([theEvent keyCode]) {
        case 1: // s, source
            [self pickSource];
            break;
        case 124: // > next
            [self nextImage];
            break;
        case 123: // < prev
            [self previousImage];
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

- (IBAction)sourceButton:(id)sender {
    [self pickSource];
}

- (IBAction)destinationButton:(id)sender {
    [self underConstruction];
}

- (IBAction)playPauseButton:(id)sender {
    [self underConstruction];
}

- (IBAction)nextButton:(id)sender {
    [self nextImage];
}

- (IBAction)previousButton:(id)sender {
    [self previousImage];
}

- (IBAction)nextDirectoryButton:(id)sender {
    [self underConstruction];
}

- (IBAction)previousDirectoryButton:(id)sender {
    [self underConstruction];
}

- (IBAction)copyButton:(id)sender {
    [self underConstruction];
}

- (IBAction)undoButton:(id)sender {
    [self underConstruction];
}

- (IBAction)toggleButtonsButton:(id)sender {
    [self underConstruction];
}

- (IBAction)helpButton:(id)sender {
    [self underConstruction];
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

@end


// TODO - UI OP
// - determine all keys and add to key capture
// - finish any buttons
// - toggle buttons feature
// - button tool tips
// - key capture over other components
// - try first responder again???
// - try menu items again???

// TODO - FEATURES
// - >>|
// - |<<
// - impelement play pause
// - destination
// - copy
// - undo

// TODO - UI LOOK
// - black behind image
// - images for buttons
// - icons for app

// - installer
// - sign app



