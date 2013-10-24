//
//  DVTTextCompletionListWindowController+KSImageNamed.m
//  KSImageNamed
//
//  Created by Jack Chen on 24/10/2013.
//
//

#import "DVTTextCompletionListWindowController+KSImageNamed.h"
#import "MethodSwizzle.h"
#import "KSImageNamedIndexCompletionItem.h"
#import "KSImageNamed.h"
#import "KSImageNamedPreviewWindow.h"

@implementation DVTTextCompletionListWindowController (KSImageNamed)

+ (void)load
{
    MethodSwizzle(self, @selector(showInfoPaneForCompletionItem:), @selector(swizzle_showInfoPaneForCompletionItem:));
    MethodSwizzle(self, @selector(_hideWindow), @selector(swizzle__hideWindow));
}

- (void)swizzle_showInfoPaneForCompletionItem:(id)item
{
    [self swizzle_showInfoPaneForCompletionItem:item];
    
    if ([item isKindOfClass:[KSImageNamedIndexCompletionItem class]]) {
        NSImage *image = [[[NSImage alloc] initWithContentsOfURL:((KSImageNamedIndexCompletionItem *)item).imageFileURL] autorelease];
        [self showPreviewForImage:image];
    }
}

- (void)swizzle__hideWindow
{
    [[KSImageNamed sharedPlugin].imageWindow orderOut:self];
    [self swizzle__hideWindow];
}

- (void)showPreviewForImage:(NSImage *)image
{
    KSImageNamedPreviewWindow *imageWindow = [KSImageNamed sharedPlugin].imageWindow;
    
    imageWindow.image = image;
    
    if (!image) {
        [imageWindow orderOut:self];
    } else {
        NSRect imgRect = NSMakeRect(0.0, 0.0, image.size.width, image.size.height);
        
        NSImageView *imageView = [[[NSImageView alloc] initWithFrame:imgRect] autorelease];
        imageView.image = image;
        
        NSWindow *completionListWindow = [self window];
        
        if ([completionListWindow isVisible]) {
            NSRect completionListWindowFrame = completionListWindow ? completionListWindow.frame : NSMakeRect(image.size.width, image.size.height, 0.0, 0.0);
            
            [imageWindow setFrameTopRightPoint:NSMakePoint(completionListWindowFrame.origin.x - 1.0,
                                                           completionListWindowFrame.origin.y + completionListWindowFrame.size.height)];
            
            [[NSApp keyWindow] addChildWindow:imageWindow ordered:NSWindowAbove];
        }
    }
}
@end
