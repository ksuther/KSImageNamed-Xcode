//
//  KSImageNamed.h
//  KSImageNamed
//
//  Created by Kent Sutherland on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, KSImageNamedCompletionStringType) {
    KSImageNamedCompletionStringTypeClassAndMethod = 0,
    KSImageNamedCompletionStringTypeMethodDeclaration = 1,
    KSImageNamedCompletionStringTypeMethodName = 2,
};

@class KSImageNamedPreviewWindow;

@interface KSImageNamed : NSObject

@property (nonatomic, strong, readonly) KSImageNamedPreviewWindow *imageWindow;

+ (instancetype)sharedPlugin;
+ (BOOL)shouldLoadPlugin;

- (void)indexNeedsUpdate:(id)index; //IDEIndex
- (void)removeImageCompletionsForIndex:(id)index; //IDEIndex
- (NSArray *)imageCompletionsForIndex:(id)index; //IDEIndex

- (NSSet *)completionStringsForType:(KSImageNamedCompletionStringType)type;

@end
