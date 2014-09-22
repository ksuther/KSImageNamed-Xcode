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
    // Xcode 5 completion method
    MethodSwizzle(self,
                  @selector(completionItemsForDocumentLocation:context:areDefinitive:),
                  @selector(swizzle_completionItemsForDocumentLocation:context:areDefinitive:));
    
    // Xcode 6 completion method
    MethodSwizzle(self,
                  @selector(completionItemsForDocumentLocation:context:highlyLikelyCompletionItems:areDefinitive:),
                  @selector(swizzle_completionItemsForDocumentLocation:context:highlyLikelyCompletionItems:areDefinitive:));
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
    
    [self ksimagenamed_checkForImageCompletionItems:items sourceTextView:sourceTextView textStorage:textStorage];
    
    return items;
}

- (id)swizzle_completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 highlyLikelyCompletionItems:(id *)arg3 areDefinitive:(char *)arg4
{
    id items = [self swizzle_completionItemsForDocumentLocation:arg1 context:arg2 highlyLikelyCompletionItems:arg3 areDefinitive:arg4];
    id sourceTextView = [arg2 objectForKey:@"DVTTextCompletionContextTextView"];
    DVTCompletingTextView *textStorage = [arg2 objectForKey:@"DVTTextCompletionContextTextStorage"];
    
    [self ksimagenamed_checkForImageCompletionItems:items sourceTextView:sourceTextView textStorage:textStorage];
    
    return items;
}

// Returns void because this modifies items in place
- (void)ksimagenamed_checkForImageCompletionItems:(id)items sourceTextView:(id)sourceTextView textStorage:(id)textStorage
{
    void(^buildImageCompletions)() = ^{
        NSRange selectedRange = [sourceTextView selectedRange];
        
        @try {
            NSString *string = [textStorage string];
            id item;
            
            //Xcode 5.1 added sourceModelService and moved sourceModelItemAtCharacterIndex: into it
            if ([textStorage respondsToSelector:@selector(sourceModelItemAtCharacterIndex:)]) {
                item = [textStorage sourceModelItemAtCharacterIndex:selectedRange.location];
            } else {
                item = [[textStorage sourceModelService] sourceModelItemAtCharacterIndex:selectedRange.location];
            }
            
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
                
                for (NSString *nextMethodDeclaration in [[KSImageNamed sharedPlugin] completionStringsForType:KSImageNamedCompletionStringTypeMethodDeclaration]) {
                    NSRange imageNamedRange = [itemString rangeOfString:nextMethodDeclaration];
                    
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
            }
            
            if (!atImageNamed && previousItem) {
                NSRange previousItemRange = [previousItem range];
                
                if (NSMaxRange(previousItemRange) > selectedRange.location) {
                    previousItemRange.length -= NSMaxRange(previousItemRange) - selectedRange.location;
                }
                
                //Enlarge previousItemRange to ensure we're at a method call and not a variable declaration or something else
                //For example, previousItemRange could be hitting a variable declaration such as "NSImage *imageNamed = [" (issue #34)
                if (previousItemRange.location > 0) {
                    previousItemRange.location--;
                    previousItemRange.length += 2;
                }
                
                NSString *previousItemString = [string substringWithRange:previousItemRange];
                
                if ([[[KSImageNamed sharedPlugin] completionStringsForType:KSImageNamedCompletionStringTypeMethodDeclaration] containsObject:previousItemString]) {
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
}

@end
