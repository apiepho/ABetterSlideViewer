//
//  ViewController.m
//  ABetterSlideViewer
//
//  Created by Al on 12/7/14.
//  Copyright (c) 2014 thatnamegroup. All rights reserved.
//

#import "ViewController.h"
#import "SlideViewerModel.h"
#import "ImageInfoWindowController.h"

@interface ViewController()
@property (strong) IBOutlet NSImageView *imageView;

// HACK to get first responder actions so menu items are enabledd
@property (strong) IBOutlet NSTextField *focusTextField;

@end


@implementation ViewController


SlideViewerModel *model;
ImageInfoWindowController *imageInfoWindowController;



- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    // Set text and all background colors
    [self.view setWantsLayer: YES];
    [self.view.layer setBackgroundColor: [NSColor blackColor].CGColor];
    [self.imageView setWantsLayer: YES];
    [self.imageView.layer setBackgroundColor: [NSColor blackColor].CGColor];

    // HACK to get first responder actions so menu items are enable
    //      need to have a textField or something focusable to get menu and toolbar
    //      items to work.
    [self.focusTextField setAlphaValue:1.0];
    [self.focusTextField setFocusRingType:NSFocusRingTypeNone];
    
    // register for notifications from model
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleModelNotification:) name:@"UpdateSourceLabel" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleModelNotification:) name:@"UpdateDestinationLabel" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleModelNotification:) name:@"UpdateImage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleModelNotification:) name:@"UpdatePlayIntervalTag" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleModelNotification:) name:@"UpdateCopyTypeTag" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleModelNotification:) name:@"UpdateDateByTag" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleModelNotification:) name:@"ImageInformation" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleModelNotification:) name:@"ImageInformationClosed" object:nil];
    
    model = [[SlideViewerModel alloc] init];
    [model finishInit];
    [self setSelectedInMenuRange: model.playIntervalTag tagStart:TAG_PLAYINTERVAL_START tagEnd:TAG_PLAYINTERVAL_END];
    [self setSelectedInMenuRange: model.copyTypeTag tagStart:TAG_COPYTYPE_START tagEnd:TAG_COPYTYPE_END];
    [self setSelectedInMenuRange: model.dateByTag tagStart:TAG_DATEBY_START tagEnd:TAG_DATEBY_END];
}

- (void) viewWillDisappear {
    if (imageInfoWindowController != nil) {
        [imageInfoWindowController.window orderOut:nil];
        imageInfoWindowController = nil;
    }
    [model savePreferences];
    [super viewWillDisappear];
    // close the app
    [[NSApplication sharedApplication] terminate:self];
}

- (void) updateImageInfoWindow {
    if (imageInfoWindowController != nil) {
        imageInfoWindowController.sourcePath.stringValue = model.sourcePath;
        imageInfoWindowController.destinationPath.stringValue = model.destinationTopPath;
        [imageInfoWindowController.imageInformation setString: [model getCurrentImageInfo]];
        [imageInfoWindowController.imageInformation scrollRangeToVisible:NSMakeRange([[imageInfoWindowController.imageInformation string] length], 0)];

    }
}

-(void)handleModelNotification:(NSNotification *)pNotification
{
    //NSLog(@"handleModelNotification: %@", [pNotification name]);
    if ([[pNotification name] isEqualToString:@"UpdateSourceLabel"]) {
        [self updateImageInfoWindow];
    }
    else if ([[pNotification name] isEqualToString:@"UpdateImage"]) {
        NSString *name = (NSString *)[pNotification object];
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:name];
        [self.imageView setImage: image];
    }
    else if ([[pNotification name] isEqualToString:@"UpdatePlayIntervalTag"]) {
        [self setSelectedInMenuRange: model.playIntervalTag tagStart:TAG_PLAYINTERVAL_START tagEnd:TAG_PLAYINTERVAL_END];
    }
    else if ([[pNotification name] isEqualToString:@"UpdateCopyTypeTag"]) {
        [self setSelectedInMenuRange: model.copyTypeTag tagStart:TAG_COPYTYPE_START tagEnd:TAG_COPYTYPE_END];
    }
    else if ([[pNotification name] isEqualToString:@"UpdateDateByTag"]) {
        [self setSelectedInMenuRange: model.dateByTag tagStart:TAG_DATEBY_START tagEnd:TAG_DATEBY_END];
    }
    else if ([[pNotification name] isEqualToString:@"ImageInformation"]) {
        model.imageInfoOpen = true;
        if (imageInfoWindowController == nil) {
            imageInfoWindowController = [[ImageInfoWindowController alloc] initWithWindowNibName:@"ImageInfoWindowController"];
            [imageInfoWindowController showWindow:self];
        }
        [self updateImageInfoWindow];
    }
    else if ([[pNotification name] isEqualToString:@"ImageInformationClosed"]) {
        model.imageInfoOpen = false;
        imageInfoWindowController = nil;
    }
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
    [model handleAction:tag];
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
            model.sourceTopPath = [selection.path stringByResolvingSymlinksInPath];
            [model savePreferences];
            [model loadPaths];
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
            model.destinationTopPath = [selection.path stringByResolvingSymlinksInPath];
            [model savePreferences];
        }
    }];
}

- (void)handleAction:(NSInteger)tag {
    switch (tag) {
        case TAG_SOURCE:
            [self pickSource];
            break;
        case TAG_DESTINATION:
            [self pickDestination];
            break;
        case TAG_HELP:
            [self underConstruction];
            break;
        default:
            [model handleAction:tag];
            break;
    }
}

@end



