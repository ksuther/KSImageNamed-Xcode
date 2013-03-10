//
//  KSImageNamed.h
//  KSImageNamed
//
//  Created by Kent Sutherland on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class KSImageNamedPreviewWindow;

@interface KSImageNamed : NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) KSImageNamedPreviewWindow *imageWindow;

- (void)indexNeedsUpdate:(id)index; //IDEIndex
- (void)removeImageCompletionsForIndex:(id)index; //IDEIndex
- (NSArray *)imageCompletionsForIndex:(id)index; //IDEIndex

@end
