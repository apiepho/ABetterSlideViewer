//
//  AppDelegate.m
//  ABetterSlideViewer
//
//  Created by Al on 12/7/14.
//  Copyright (c) 2014 thatnamegroup. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

//- (IBAction)toolbarAction:(id)sender {
//}
//- (IBAction)menuItemAction:(id)sender {
//}
//- (IBAction)keyUp:(NSEvent *)theEvent {
//}

@end

//@implementation NSApplication (NSResponderHandler)
//static NSSet* ignoreSelectors = nil;
//+ (void)load{
//    @autoreleasepool {
//        ignoreSelectors = [[NSSet alloc] initWithObjects:
//                           NSStringFromSelector(@selector(_finishedMakingConnections)),
//                           NSStringFromSelector(@selector(isTestingInterface)),
//                           NSStringFromSelector(@selector(_shouldApplyExclusiveTouch)),
//                           NSStringFromSelector(@selector(accessibilityInitialize)),
//                           NSStringFromSelector(@selector(applicationSuspend:settings:)),
//                           NSStringFromSelector(@selector(applicationResume:settings:)),
//                           nil];
//    }
//}
//- (NSArray*) responderChain{
//    NSMutableArray* chain = [NSMutableArray array];
//    for (NSResponder* responder = self; responder != nil; responder = [responder nextResponder]) {
//        [chain addObject: responder];
//    }
//    return chain;
//}
//- (BOOL)respondsToSelector:(SEL)selector {
//    BOOL responds = [super respondsToSelector:selector];
//    if (!responds && ![ignoreSelectors containsObject:NSStringFromSelector(selector)]) {
//        NSLog(@"UIApplication does not respond to selector %@. Usually this only happens, when dispatchEventSelector or targetAction was not caught!",
//              NSStringFromSelector(selector));
//    }
//    return responds;
//}
//@end
