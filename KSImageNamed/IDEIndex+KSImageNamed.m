//
//  IDEIndex+KSImageNamed.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 1/23/13.
//
//

#import "IDEIndex+KSImageNamed.h"
#import "KSImageNamed.h"
#import "MethodSwizzle.h"

@implementation IDEIndex (KSImageNamed)

+ (void)load
{
    MethodSwizzle(self, @selector(close), @selector(swizzle_close));
}

- (void)swizzle_close
{
    [[KSImageNamed sharedPlugin] removeImageCompletionsForIndex:self];
    
    [self swizzle_close];
}

@end
