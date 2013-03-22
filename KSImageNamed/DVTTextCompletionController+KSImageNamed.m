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
    
    MethodSwizzle(self,
                  @selector(textViewShouldChangeTextInRange:replacementString:),
                  @selector(swizzle_textViewShouldChangeTextInRange:replacementString:));
}

- (BOOL)swizzle_acceptCurrentCompletion
{
    BOOL success = [self swizzle_acceptCurrentCompletion];
    
    if (success) {
        @try {
            NSRange range = [[self textView] realSelectedRange];
            NSString * const stringToMatch = @"mage imageNamed:";
            
            //If an autocomplete causes imageNamed: to get inserted, remove the token and immediately pop up autocomplete
            if (range.location > [stringToMatch length]) {
                NSString *insertedString = [[[self textView] string] substringWithRange:NSMakeRange(range.location - [stringToMatch length], [stringToMatch length])];
                
                if ([insertedString isEqualToString:stringToMatch]) {
                    [[self textView] _replaceCellWithCellText:@""];
                    [self _showCompletionsAtCursorLocationExplicitly:YES];
                }
            }
        } @catch (NSException *exception) {
            //I'd rather not crash if Xcode chokes on something
        }
    }
    
    return success;
}

- (BOOL)swizzle_textViewShouldChangeTextInRange:(NSRange)arg1 replacementString:(NSString *)replacementString
{
    BOOL result = [self swizzle_textViewShouldChangeTextInRange:arg1 replacementString:replacementString];
    
    @try {
        if (replacementString) {
            id document = [[[self.textView window] windowController] document];
            id index = [[document performSelector:@selector(workspace)] performSelector:@selector(index)];
            
            NSArray *imageCompletions = [[KSImageNamed sharedPlugin] imageCompletionsForIndex:index];
            
            NSInteger indexOfString = [imageCompletions indexOfObjectPassingTest:^BOOL(KSImageNamedIndexCompletionItem *item, NSUInteger idx, BOOL *stop) {
                if ([item.fileName isEqualToString:replacementString]) {
                    *stop = YES;
                    return YES;
                }
                else {
                    return NO;
                }
            }];
            
            NSImage *image = nil;
            if (indexOfString != NSNotFound) {
                KSImageNamedIndexCompletionItem *completionItem = imageCompletions[indexOfString];
                image = [[NSImage alloc] initWithContentsOfURL:completionItem.fileURL];
            }
            
            [self showPreviewForImage:image];
        }
    }
    @catch (NSException *exception) {
        //I'd rather not crash if Xcode chokes on something
    }
    
    return result;
}

- (void)showPreviewForImage:(NSImage *)image
{
    KSImageNamedPreviewWindow *imageWindow = [KSImageNamed sharedPlugin].imageWindow;
    
    if (!image) {
        [imageWindow orderOut:self];
    } else {
        NSRect imgRect = NSMakeRect(0.0, 0.0, image.size.width, image.size.height);
        
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:imgRect];
        imageView.image = image;
        
        id currentDVTTextCompletionSession = [self currentSession];
        id currentDVTTextCompletionListWindowController = [currentDVTTextCompletionSession _listWindowController];
        NSWindow *completionListWindow = [currentDVTTextCompletionListWindowController window];
        
        if ([completionListWindow isVisible] && [[currentDVTTextCompletionListWindowController _selectedCompletionItem] isKindOfClass:[KSImageNamedIndexCompletionItem class]]) {
            NSRect completionListWindowFrame = completionListWindow ? completionListWindow.frame : NSMakeRect(image.size.width, image.size.height, 0.0, 0.0);
            
            [imageWindow setFrameTopRightPoint:NSMakePoint(completionListWindowFrame.origin.x - 1.0,
                                                          completionListWindowFrame.origin.y + completionListWindowFrame.size.height)];
            
            [[NSApp keyWindow] addChildWindow:imageWindow ordered:NSWindowAbove];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        imageWindow.image = image;
    });
}

@end
