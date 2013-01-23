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
    
    //Wait a bit to allow IDEIndex to catch up
    //Another option is to listen for IDEIndexDidIndexWorkspaceNotification and update then, but that doesn't work correctly when adding files
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[KSImageNamed sharedPlugin] rebuildImageCompletionsForIndex:[self index]];
    });
}

@end
