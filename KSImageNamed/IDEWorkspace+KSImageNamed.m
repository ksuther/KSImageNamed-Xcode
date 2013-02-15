//
//  IDEWorkspace+KSImageNamed.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 1/23/13.
//
//

#import "IDEWorkspace+KSImageNamed.h"
#import "MethodSwizzle.h"
#import "KSImageNamed.h"

@implementation IDEWorkspace (KSImageNamed)

+ (void)load
{
    MethodSwizzle(self, @selector(_updateIndexableFiles:), @selector(swizzle__updateIndexableFiles:));
}

- (void)swizzle__updateIndexableFiles:(id)arg1
{
    [self swizzle__updateIndexableFiles:arg1];
    
    [[KSImageNamed sharedPlugin] indexNeedsUpdate:[self index]];
}

@end
