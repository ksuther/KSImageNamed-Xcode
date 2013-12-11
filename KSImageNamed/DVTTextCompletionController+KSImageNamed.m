//
//  DVTTextCompletionController+KSImageNamed.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 1/22/13.
//
//

#import "DVTTextCompletionController+KSImageNamed.h"
#import "KSImageNamedIndexCompletionItem.h"
#import "MethodSwizzle.h"
#import "KSImageNamed.h"
#import "KSImageNamedPreviewWindow.h"

@implementation DVTTextCompletionController (KSImageNamed)

+ (void)load
{
    MethodSwizzle(self, @selector(acceptCurrentCompletion), @selector(swizzle_acceptCurrentCompletion));
}

- (BOOL)swizzle_acceptCurrentCompletion
{
    BOOL success = [self swizzle_acceptCurrentCompletion];
    
    if (success) {
        @try {
            NSRange range = [[self textView] selectedRange];
            
            for (NSString *nextClassAndMethod in [[KSImageNamed sharedPlugin] completionStringsForType:KSImageNamedCompletionStringTypeClassAndMethod]) {
                //If an autocomplete causes imageNamed: to get inserted, remove the token and immediately pop up autocomplete
                if (range.location > [nextClassAndMethod length]) {
                    NSString *insertedString = [[[self textView] string] substringWithRange:NSMakeRange(range.location - [nextClassAndMethod length], [nextClassAndMethod length])];
                    
                    if ([insertedString isEqualToString:nextClassAndMethod]) {
                        [[self textView] insertText:@"" replacementRange:range];
                        [self _showCompletionsAtCursorLocationExplicitly:YES];
                    }
                }
            }
        } @catch (NSException *exception) {
            //I'd rather not crash if Xcode chokes on something
        }
    }
    
    return success;
}
@end
