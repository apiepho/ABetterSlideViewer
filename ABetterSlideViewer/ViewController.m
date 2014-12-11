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

// TODO: should add these to a panel or another view so who set can be hidden
@property (strong) IBOutlet NSButton *sourceButton;
@property (strong) IBOutlet NSButton *destinationButton;
@property (strong) IBOutlet NSButton *playPauseButton;
@property (strong) IBOutlet NSButton *nextButton;
@property (strong) IBOutlet NSButton *previousButton;
@property (strong) IBOutlet NSButton *nextFolderButton;
@property (strong) IBOutlet NSButton *previousFolderButton;
@property (strong) IBOutlet NSButton *moveItButton;
@property (strong) IBOutlet NSButton *undoImageButton;
@property (strong) IBOutlet NSButton *toggleButton;
@property (strong) IBOutlet NSButton *helpButton;
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
    // TODO: should use some #define for keycodes instead of magic numbers
    NSLog(@"%d",[theEvent keyCode]);
    switch ([theEvent keyCode]) {
        case 1: // s, source
            [self pickSource];
            break;
        case 2: // d, destination
            NSLog(@"d");
            break;
        case 124: // > next
            [self nextImage];
            break;
        case 123: // < prev
            [self previousImage];
            break;
        case 45: // n, next folder
            NSLog(@"n");
            break;
        case 35: // p, previous folder
            NSLog(@"p");
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
        case 17: // t, toggle buttons
            [self hideShowButtons];
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

- (IBAction)sourceButton:(id)sender {
    [self pickSource];
}

- (IBAction)destinationButton:(id)sender {
    // TODO
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
    // TODO
    [self underConstruction];
}

- (IBAction)previousDirectoryButton:(id)sender {
    // TODO
    [self underConstruction];
}

- (IBAction)copyButton:(id)sender {
    // TODO
    [self underConstruction];
}

- (IBAction)undoButton:(id)sender {
    // TODO
    [self underConstruction];
}

- (IBAction)toggleButtonsButton:(id)sender {
    [self hideShowButtons];
}

- (IBAction)helpButton:(id)sender {
    // TODO
    [self underConstruction];
}

- (void)hideShowButtons {
    bool state = !self.sourceButton.hidden;
    
    self.sourceButton.hidden            = state;
    self.destinationButton.hidden       = state;
    self.playPauseButton.hidden         = state;
    self.nextButton.hidden              = state;
    self.previousButton.hidden          = state;
    self.nextFolderButton.hidden        = state;
    self.previousFolderButton.hidden    = state;
    self.moveItButton.hidden            = state;
    self.undoImageButton.hidden         = state;
    self.toggleButton.hidden            = state;
    self.helpButton.hidden              = state;
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

@end


// TODO - UI OP
// - button tool tips
// - key capture over other components
// - try first responder again???
// - try menu items again???
// - fix stretch
// - use cocoa toolbar for buttons

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



