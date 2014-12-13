//
//  ViewController.h
//  ABetterSlideViewer
//
//  Created by Al on 12/7/14.
//  Copyright (c) 2014 thatnamegroup. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

// capture the keyup
- (void)keyUp:(NSEvent *)theEvent;

// capture toolbar actions
- (IBAction)toolbarAction:(id)sender;
@end

