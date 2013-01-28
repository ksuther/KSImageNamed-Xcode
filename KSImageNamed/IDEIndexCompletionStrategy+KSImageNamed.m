//
//  IDEIndexCompletionStrategy+KSImageNamed.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 1/19/13.
//
//

#import "IDEIndexCompletionStrategy+KSImageNamed.h"
#import "KSImageNamed.h"
#import "KSImageNamedIndexCompletionItem.h"
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

                atImageNamed = [itemString rangeOfString:@" imageNamed:"].location != NSNotFound;
            }
            
            if (!atImageNamed && previousItem) {
                NSRange previousItemRange = [previousItem range];
                
                if (NSMaxRange(previousItemRange) > selectedRange.location) {
                    previousItemRange.length -= NSMaxRange(previousItemRange) - selectedRange.location;
                }

                NSString *previousItemString = [string substringWithRange:previousItemRange];

                atImageNamed = [previousItemString isEqualToString:@"imageNamed"];
            }
            
            if (atImageNamed) {
                //Find index
                id document = [[[sourceTextView window] windowController] document];
                id index = [[document performSelector:@selector(workspace)] performSelector:@selector(index)];
                NSArray *completions = [[KSImageNamed sharedPlugin] imageCompletionsForIndex:index];
                
                if ([completions count] > 0) {
                    [self merge:completions into:items];
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

- (void)merge:(NSArray *)origin into:(NSMutableArray *)destination
{
    __block NSRange destinationRange = NSMakeRange(0, [destination count]);
    [origin enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSUInteger insertionIdx = [destination indexOfObject:obj
                                               inSortedRange:destinationRange
                                                     options:NSBinarySearchingInsertionIndex|NSBinarySearchingLastEqual
                                             usingComparator:^NSComparisonResult(IDEIndexCompletionItem *left, IDEIndexCompletionItem *right) {
                                                 return [left.name caseInsensitiveCompare:right.name];
                                             }];

        [destination insertObject:obj atIndex:insertionIdx];
        destinationRange.location = insertionIdx;
        destinationRange.length = [destination count] - insertionIdx;
    }];
}

@end
