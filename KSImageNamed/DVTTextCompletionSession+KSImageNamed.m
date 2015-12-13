//
//  DVTTextCompletionSession+KSImageNamed.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 11/1/15.
//
//

#import "DVTTextCompletionSession+KSImageNamed.h"
#import "KSImageNamedIndexCompletionItem.h"
#import "MethodSwizzle.h"

@implementation DVTTextCompletionSession (KSImageNamed)

+ (void)load
{
    MethodSwizzle(self, @selector(replacementRangeForSuggestedRange:), @selector(swizzle_replacementRangeForSuggestedRange:));
}

- (NSRange)swizzle_replacementRangeForSuggestedRange:(NSRange)arg1
{
    NSInteger selectedIndex = [self selectedCompletionIndex];

    if (selectedIndex != -1) {
        id completion = [[self filteredCompletionsAlpha] objectAtIndex:selectedIndex];

        if ([completion isKindOfClass:[KSImageNamedIndexCompletionItem class]]) {
            NSTextView *textView = [self textView];
            NSRange selectedRange = [textView selectedRange];

            // Check if we need to replace redundant text
            // This can happen in the following situation:
            // - Type in [NSImage imageNamed:@"image"]
            // - Move insertion point inside image, such as @"ima|ge"
            // - Press escape or F5 to trigger completion
            // - Accept the completion
            // Without this extra handling you would end up with @"ima@"image"ge
            if (selectedRange.length == 0 && selectedRange.location <= NSMaxRange(arg1)) {
                NSString *string = [[textView textStorage] string];
                NSString *completionText = [completion completionText];
                NSString *completionName = [completion name];

                if (NSMaxRange(arg1) - selectedRange.location == 0) {
                    // The completion is being accepted (through insertCurrentCompletion)
                    // We want to include the entire string (include the leading and trailing quotation marks) to make sure it all gets replaced
                    NSUInteger offsetInCompletionString = [completionText rangeOfString:completionName].location;
                    NSString *textBeforeCompletionRange = [string substringWithRange:NSMakeRange(arg1.location - offsetInCompletionString, offsetInCompletionString)];

                    if (offsetInCompletionString != NSNotFound && [textBeforeCompletionRange isEqualToString:[completionText substringToIndex:offsetInCompletionString]]) {
                        arg1.location -= offsetInCompletionString;
                        arg1.length += offsetInCompletionString;
                    }
                }

                // Replace up to the next quotation mark on the same line
                NSRange lineRange = [string lineRangeForRange:arg1];
                NSRange nextQuoteRange = [string rangeOfString:@"\"" options:0 range:NSMakeRange(NSMaxRange(arg1), NSMaxRange(lineRange) - NSMaxRange(arg1))];
                
                if (nextQuoteRange.location != NSNotFound) {
                    return NSMakeRange(arg1.location, nextQuoteRange.location - arg1.location + 1);
                }
            }
        }
    }

    return [self swizzle_replacementRangeForSuggestedRange:arg1];
}

@end
