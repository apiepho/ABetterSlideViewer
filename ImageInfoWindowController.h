//
//  ImageInfoWindowController.h
//  ABetterSlideViewer
//
//  Created by Al on 12/22/14.
//  Copyright (c) 2014 thatnamegroup. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ImageInfoWindowController : NSWindowController<NSWindowDelegate>
@property (strong) IBOutlet NSTextField *sourcePath;
@property (strong) IBOutlet NSTextField *destinationPath;
@property (strong) IBOutlet NSTextView *imageInformation;

@end
