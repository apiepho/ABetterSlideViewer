//
//  SlideImageView.m
//  ABetterSlideViewer
//
//  Created by Al on 1/5/15.
//  Copyright (c) 2015 thatnamegroup. All rights reserved.
//

#import "SlideImageView.h"

@implementation SlideImageView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (BOOL) wantsUpdateLayer {
    return true;
}

- (void) updateLayer {
    [self.layer setBackgroundColor: [NSColor blackColor].CGColor];
}

@end
