//
//  SlideView.m
//  ABetterSlideViewer
//
//  Created by Al on 12/17/14.
//  Copyright (c) 2014 thatnamegroup. All rights reserved.
//

#import "SlideView.h"

@implementation SlideView

- (BOOL)acceptsFirstResponder
{
    
    NSLog(@"I accepted being a first responder! Yea!");
    return YES;
}

- (BOOL)resignFirstResponder
{
    [self setNeedsDisplay:YES];
    return YES;
}

- (BOOL)becomeFirstResponder
{
    [self setNeedsDisplay:YES];
    return YES;
    
}
- (IBAction)toolbarAction:(id)sender {
    NSLog(@"here");
}


@end
