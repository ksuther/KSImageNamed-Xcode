//
//  KSImageNamedPreviewWindow.h
//  KSImageNamed
//
//  Created by Friedrich Markgraf on 10.03.13.
//
//

#import <Cocoa/Cocoa.h>

@interface KSImageNamedPreviewWindow : NSWindow

//@property (nonatomic, strong) NSString *descriptionString;
@property (nonatomic, strong) NSImage *image;

- (void)setFrameTopRightPoint:(NSPoint)point;

@end
