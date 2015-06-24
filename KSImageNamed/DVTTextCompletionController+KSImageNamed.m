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
    
    NSRange selectedRange = [[self textView] selectedRange];
    
    id item = nil;
    if ([self.textView.textStorage respondsToSelector:@selector(sourceModelItemAtCharacterIndex:)]) {
        item = [self.textView.textStorage sourceModelItemAtCharacterIndex:selectedRange.location]; //-2.插入时会增加@"
    } else {
        item = [[self.textView.textStorage sourceModelService] sourceModelItemAtCharacterIndex:selectedRange.location];
    }
    NSRange itemRange = [item range];
//    NSLog(@"替换前,itemRange: %@ selectRange:%@",NSStringFromRange(itemRange),NSStringFromRange(selectedRange));
    NSString *itemString = [[self.textView.textStorage string] substringWithRange:itemRange];
//    NSLog(@"替换前,itemString:%@",itemString);
    
    BOOL success = [self swizzle_acceptCurrentCompletion];

    if (success) {
        @try {
            NSRange range = [[self textView] selectedRange];

            if ([itemString hasPrefix:@"@\""]&&[itemString hasSuffix:@"\""]){
                [self.textView insertText:@"" replacementRange:NSMakeRange(range.location, itemRange.location+itemRange.length-range.location+1+2)];
                [self.textView insertText:@"" replacementRange:NSMakeRange(itemRange.location, 2)];
            }
            
            for (NSString *nextClassAndMethod in [[KSImageNamed sharedPlugin] completionStringsForType:KSImageNamedCompletionStringTypeClassAndMethod]) {
                //If an autocomplete causes imageNamed: to get inserted, remove the token and immediately pop up autocomplete
                if (range.location > [nextClassAndMethod length]) {
                    NSString *insertedString = [[[self textView] string] substringWithRange:NSMakeRange(range.location - [nextClassAndMethod length], [nextClassAndMethod length])];
//                    NSLog(@"准备插入替换.....%@,%@",insertedString,nextClassAndMethod);
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
