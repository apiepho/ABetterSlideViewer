//
//  ImageInfoWindowController.m
//  ABetterSlideViewer
//
//  Created by Al on 12/22/14.
//  Copyright (c) 2014 thatnamegroup. All rights reserved.
//

#import "ImageInfoWindowController.h"

@interface ImageInfoWindowController ()

@end

@implementation ImageInfoWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void) windowWillClose:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ImageInformationClosed" object:nil];
}

@end
