//
//  IDEIndexCompletionStrategy+KSImageNamed.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 1/19/13.
//
//

#import "IDEIndexCompletionStrategy+KSImageNamed.h"
#import "KSImageNamed.h"
#import "MethodSwizzle.h"

@implementation IDEIndexCompletionStrategy (KSImageNamed)

+ (void)load
{
    MethodSwizzle(self,
                  @selector(completionItemsForDocumentLocation:context:areDefinitive:),
                  @selector(swizzle_completionItemsForDocumentLocation:context:areDefinitive:));
}

/*
 arg1 = DVTTextDocumentLocation
 arg2 = NSDictionary
     DVTTextCompletionContextSourceCodeLanguage <DVTSourceCodeLanguage>
     DVTTextCompletionContextTextStorage <DVTTextStorage>
     DVTTextCompletionContextTextView <DVTSourceTextView>
     IDETextCompletionContextDocumentKey <IDESourceCodeDocument>
     IDETextCompletionContextEditorKey <IDESourceCodeEditor>
     IDETextCompletionContextPlatformFamilyNamesKey (macosx, iphoneos?)
     IDETextCompletionContextUnsavedDocumentStringsKey <NSDictionary>
     IDETextCompletionContextWorkspaceKey <IDEWorkspace>
 arg3 = unsure, not changing it
 returns = IDEIndexCompletionArray
 */
- (id)swizzle_completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 areDefinitive:(char *)arg3
{
    id items = [self swizzle_completionItemsForDocumentLocation:arg1 context:arg2 areDefinitive:arg3];
    
    id sourceTextView = [arg2 objectForKey:@"DVTTextCompletionContextTextView"];
    DVTCompletingTextView *textStorage = [arg2 objectForKey:@"DVTTextCompletionContextTextStorage"];
    
    void(^buildImageCompletions)() = ^{
        NSRange selectedRange = [sourceTextView realSelectedRange];
        
        @try {
            NSString *string = [textStorage string];
            id item = [textStorage sourceModelItemAtCharacterIndex:selectedRange.location];
            id previousItem = [item previousItem];
            NSString *itemString = nil;
            BOOL atImageNamed = NO;
            
            if (item) {
                NSRange itemRange = [item range];
                
                if (NSMaxRange(itemRange) > selectedRange.location) {
                    itemRange.length -= NSMaxRange(itemRange) - selectedRange.location;
                }
                
                itemString = [string substringWithRange:itemRange];
                
                //Limit search to a single line
                //itemRange can be massive in some situations, such as -(void)<autocomplete>
                NSRange newlineRange = [itemString rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch];
                
                if (newlineRange.location != NSNotFound) {
                    itemRange.length = itemRange.length - newlineRange.location;
                    itemRange.location = itemRange.location + newlineRange.location;
                    
                    //Extra range check to prevent huge itemRange.location
                    //Checking length and NSMaxRange in case NSMaxRange overflows
                    if (itemRange.length < [string length] && NSMaxRange(itemRange) < [string length]) {
                        itemString = [string substringWithRange:itemRange];
                    }
                }
                
                NSRange imageNamedRange = [itemString rangeOfString:@" imageNamed:"];
                
                if (imageNamedRange.location != NSNotFound) {
                    atImageNamed = YES;
                    
                    //We might be past imageNamed, such as 'imageNamed:@"name"] draw<insertion point>'
                    //For now just check if the insertion point is past the closing bracket. This won't work if an image has a bracket in the name and other edge cases.
                    //It'd probably be cleaner to use the source model to determine this
                    NSRange closeBracketRange = [itemString rangeOfString:@"]" options:0 range:NSMakeRange(imageNamedRange.location, [itemString length] - imageNamedRange.location)];
                    
                    if (closeBracketRange.location != NSNotFound) {
                        atImageNamed = NO;
                    }
                }
            }
            
            if (!atImageNamed && previousItem) {
                NSRange previousItemRange = [previousItem range];
                
                if (NSMaxRange(previousItemRange) > selectedRange.location) {
                    previousItemRange.length -= NSMaxRange(previousItemRange) - selectedRange.location;
                }
                
                NSString *previousItemString = [string substringWithRange:previousItemRange];
                
                if ([previousItemString isEqualToString:@"imageNamed"]) {
                    atImageNamed = YES;
                }
            }
            
            if (atImageNamed) {
                //Find index
                id document = [[[sourceTextView window] windowController] document];
                id index = [[document performSelector:@selector(workspace)] performSelector:@selector(index)];
                NSArray *completions = [[KSImageNamed sharedPlugin] imageCompletionsForIndex:index];
                
                if ([completions count] > 0) {
                    [items removeAllObjects];
                    [items addObjectsFromArray:completions];
                }
            }
        } @catch (NSException *exception) {
            //Handle this or something
        }
    };
    
    //Ensure this runs on the main thread since we're using NSTextStorage
    if ([NSThread isMainThread]) {
        buildImageCompletions();
    } else {
        dispatch_sync(dispatch_get_main_queue(), buildImageCompletions);
    }
    
    return items;
}

@end
