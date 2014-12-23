//
//  SlideViewerModel.h
//  ABetterSlideViewer
//
//  Created by Al on 12/22/14.
//  Copyright (c) 2014 thatnamegroup. All rights reserved.
//

#import <Foundation/Foundation.h>

static const float PLAY_INTERVAL_2S            = 2.0f;
static const float PLAY_INTERVAL_10S           = 10.0f;
static const float PLAY_INTERVAL_30S           = 30.0f;
static const float PLAY_INTERVAL_1M            = 60.0f;

static const NSInteger TAG_SOURCE              = 1;
static const NSInteger TAG_DESTINATION         = 2;
static const NSInteger TAG_PLAYPAUSE           = 3;
static const NSInteger TAG_NEXT                = 4;
static const NSInteger TAG_PREVIOUS            = 5;
static const NSInteger TAG_NEXTFOLDER          = 7;
static const NSInteger TAG_PREVFOLDER          = 6;
static const NSInteger TAG_COPY                = 8;
static const NSInteger TAG_UNDO                = 9;
static const NSInteger TAG_HELP                = 10;
static const NSInteger TAG_PLAYINTERVAL_START  = 21;
static const NSInteger TAG_PLAYINTERVAL_2S     = 21;
static const NSInteger TAG_PLAYINTERVAL_10S    = 22;
static const NSInteger TAG_PLAYINTERVAL_30S    = 23;
static const NSInteger TAG_PLAYINTERVAL_1M     = 24;
static const NSInteger TAG_PLAYINTERVAL_END    = 24;
static const NSInteger TAG_COPYTYPE_START      = 31;
static const NSInteger TAG_COPYTYPE_MIRROR     = 31;
static const NSInteger TAG_COPYTYPE_BYMONTH    = 32;
static const NSInteger TAG_COPYTYPE_BYYEAR     = 33;
static const NSInteger TAG_COPYTYPE_SINGLEFLDR = 34;
static const NSInteger TAG_COPYTYPE_END        = 34;
static const NSInteger TAG_DATEBY_START        = 41;
static const NSInteger TAG_DATEBY_FOLDER       = 41;
static const NSInteger TAG_DATEBY_META         = 42;
static const NSInteger TAG_DATEBY_END          = 42;
static const NSInteger TAG_IMAGE_INFO          = 51;


@interface SlideViewerModel : NSObject

@property (copy, readwrite) NSString *destinationTopPath;
@property (copy, readwrite) NSString *sourceTopPath;
@property (copy, readonly) NSString *sourcePath;
@property (readonly) NSInteger playIntervalTag;
@property (readonly) NSInteger copyTypeTag;
@property (readonly) NSInteger dateByTag;
@property (readwrite) bool imageInfoOpen;


- (void) finishInit;
- (void) loadPreferences;
- (void) savePreferences;
- (void) loadPaths;
- (NSString *) getCurrentImageInfo;
- (void)handleAction:(NSInteger)tag;

@end
