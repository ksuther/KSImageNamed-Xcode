//
//  DVTSourceTextView+KSImageNamed.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 1/19/13.
//
//

#import "DVTSourceTextView+KSImageNamed.h"
#import "MethodSwizzle.h"
#import "XcodeMisc.h"
#import "KSImageNamed.h"

@implementation DVTSourceTextView (KSImageNamedSwizzle)

+ (void)load
{
    MethodSwizzle(self,
                  @selector(shouldAutoCompleteAtLocation:),
                  @selector(swizzle_shouldAutoCompleteAtLocation:));
}

- (BOOL)swizzle_shouldAutoCompleteAtLocation:(unsigned long long)arg1
{
    BOOL shouldAutoComplete = [self swizzle_shouldAutoCompleteAtLocation:arg1];
    
    if (!shouldAutoComplete) {
        @try {
            //Ensure that image autocomplete automatically pops up when you type imageNamed:
            //Search backwards from the current line
            NSRange range = NSMakeRange(0, arg1);
            NSString *string = [[self textStorage] string];
            NSRange newlineRange = [string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch range:range];
            NSString *line = string;
            
            if (newlineRange.location != NSNotFound) {
                NSRange lineRange = NSMakeRange(newlineRange.location, arg1 - newlineRange.location);
                
                if (lineRange.location < [line length] && NSMaxRange(lineRange) < [line length]) {
                    line = [string substringWithRange:lineRange];
                }
            }
            
            for (NSString *nextClassAndMethod in [[KSImageNamed sharedPlugin] completionStringsForType:KSImageNamedCompletionStringTypeClassAndMethod]) {
                if ([line hasSuffix:nextClassAndMethod]) {
                    id document = [[[self window] windowController] document];
                    id index = [[document performSelector:@selector(workspace)] performSelector:@selector(index)];
                    NSArray *completions = [[KSImageNamed sharedPlugin] imageCompletionsForIndex:index];
                    
                    if ([completions count] > 0) {
                        shouldAutoComplete = YES;
                    }
                    break;
                }
            }
        } @catch (NSException *exception) {
            //I'd rather not crash if Xcode chokes on something
        }
    }
    
    return shouldAutoComplete;
}

@end
