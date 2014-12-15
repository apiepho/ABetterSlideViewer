//
//  ViewController.h
//  ABetterSlideViewer
//
//  Created by Al on 12/7/14.
//  Copyright (c) 2014 thatnamegroup. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

- (IBAction)toolbarAction:(id)sender;
- (IBAction) menuItemAction:(id)sender;

- (IBAction)keyUp:(NSEvent *)theEvent;

@end

