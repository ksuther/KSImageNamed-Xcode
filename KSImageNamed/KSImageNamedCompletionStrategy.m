//
//  KSImageNamedCompletionStrategy.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 10/3/15.
//
//

#import "KSImageNamedCompletionStrategy.h"
#import "KSImageNamed.h"
#import "XcodeMisc.h"

@implementation KSImageNamedCompletionStrategy

- (id)completionItemsForDocumentLocation:(DVTTextDocumentLocation *)arg1 context:(NSDictionary *)arg2 highlyLikelyCompletionItems:(id *)arg3 areDefinitive:(char *)arg4
{
    NSArray *completions;
    id language = [arg2 objectForKey:@"DVTTextCompletionContextSourceCodeLanguage"];

    @try {
        BOOL atImageNamed = NO;
        NSRange selectedRange = [arg1 characterRange];
        NSString *string = [arg2 objectForKey:@"DVTTextCompletionContextTextStorageString"];
        id textStorage = [arg2 objectForKey:@"DVTTextCompletionContextTextStorage"];

        if ([[language identifier] isEqualToString:@"Xcode.SourceCodeLanguage.Swift"]) {
            // sourceModel isn't available in Swift, check the string manually
            NSRange newlineRange = [string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch range:NSMakeRange(0, NSMaxRange(selectedRange))];

            if (newlineRange.location != NSNotFound) {
                NSString *lineString = [string substringWithRange:NSMakeRange(newlineRange.location, NSMaxRange(selectedRange) - newlineRange.location)];

                for (NSString *nextString in [[KSImageNamed sharedPlugin] completionStringsForType:KSImageNamedCompletionStringTypeClassAndMethod]) {
                    if ([lineString hasSuffix:nextString]) {
                        atImageNamed = YES;
                        break;
                    }
                }
            }
        } else {
            id item = [[textStorage sourceModel] enclosingItemAtLocation:selectedRange.location];
            
            id previousItem = [item previousItem];
            NSString *itemString;
            
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
        }

        if (atImageNamed) {
            IDEWorkspace *workspace = [arg2 objectForKey:@"IDETextCompletionContextWorkspaceKey"];
            IDEIndex *index = [workspace index];

            completions = [[KSImageNamed sharedPlugin] imageCompletionsForIndex:index language:language];

            if ([completions count] > 0) {
                // This makes it so that only image suggestions are shown (setting arg4 to 1 halts subsequent strategies)
                *arg3 = completions;
                *arg4 = 1;
            }
        }
    } @catch (NSException *exception) {
        //Handle this or something
    }

    return completions;
}

@end
