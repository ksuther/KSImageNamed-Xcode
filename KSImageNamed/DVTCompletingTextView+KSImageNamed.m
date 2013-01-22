//
//  DVTCompletingTextView+KSImageNamed.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 1/19/13.
//
//

//This code doesn't do what I had hoped it would
//The code is correct, but just returning YES for shouldAutoCompleteAtLocation: isn't
//enough to get the completions to appear
#if 0

#import "DVTCompletingTextView+KSImageNamed.h"
#import "MethodSwizzle.h"
#import "XcodeMisc.h"

//Trying to get autocompletion to automatically appear when typing imageNamed:@"
//This returns YES at the right time, but that desn't seem to be enough
@implementation DVTCompletingTextView (KSImageNamedSwizzle)

+ (void)load
{
    MethodSwizzle(self,
                  @selector(shouldAutoCompleteAtLocation:),
                  @selector(swizzle_shouldAutoCompleteAtLocation:));
}

- (BOOL)swizzle_shouldAutoCompleteAtLocation:(unsigned long long)arg1
{
    BOOL shouldAutoComplete = [self swizzle_shouldAutoCompleteAtLocation:arg1];
    id stringConstantItem = [[[self textStorage] sourceModel] stringConstantAtLocation:arg1];
    
    if (stringConstantItem) {
        //Is this inside imageNamed?
        NSRange range = [stringConstantItem range];
        NSString * const imageNamed = @"imageNamed:";
        
        if (NSMaxRange(range) > [imageNamed length]) {
            NSString *previousString = [[[self textStorage] string] substringWithRange:NSMakeRange(range.location - 11, [imageNamed length])];
            
            if ([previousString isEqualToString:imageNamed]) {
                shouldAutoComplete = YES;
            }
        }
    }
    
    return shouldAutoComplete;
}

@end

#endif
