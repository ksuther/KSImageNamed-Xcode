//
//  KSImageNamed.h
//  KSImageNamed
//
//  Created by Kent Sutherland on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KSImageNamed : NSObject

+ (instancetype)sharedPlugin;

- (void)rebuildImageCompletionsForIndex:(id)index; //IDEIndex
- (void)removeImageCompletionsForIndex:(id)index; //IDEIndex
- (NSArray *)imageCompletionsForIndex:(id)index; //IDEIndex

@end
