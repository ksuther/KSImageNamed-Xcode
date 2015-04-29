//
//  KSImageNamedPreviewWindow.m
//  KSImageNamed
//
//  Created by Friedrich Markgraf on 10.03.13.
//
//

#import "KSImageNamedPreviewWindow.h"

@interface KSImageNamedPreviewWindow () {
    NSView *_contentView;
    NSTextField *_scalingLabel;
    NSTextField *_sizeLabel;
    NSImageView *_imageView;
    NSPoint _frameTopRightPoint;
}
@end

@implementation KSImageNamedPreviewWindow

- (instancetype)init
{
    NSRect frame = NSMakeRect(0.0, 0.0, 10.0, 50.0);
    if ( (self = [super initWithContentRect:frame
                                styleMask:NSBorderlessWindowMask
                                  backing:NSBackingStoreBuffered
                                    defer:NO]) ) {
        self.hasShadow = YES;
        _frameTopRightPoint = NSMakePoint(10.0, 50.0);

        _contentView = [[NSView alloc] initWithFrame:frame];
        self.contentView = _contentView;
        
        _scalingLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0, 33.0, 120.0, 16.0)];
        _scalingLabel.autoresizingMask = NSViewMaxXMargin | NSViewMinYMargin;
        _scalingLabel.textColor = [NSColor blueColor];
        _scalingLabel.bezeled = NO;
        _scalingLabel.drawsBackground = NO;
        _scalingLabel.editable = NO;
        _scalingLabel.selectable = NO;
        _scalingLabel.alignment = NSLeftTextAlignment;
        [_contentView addSubview:_scalingLabel];
        
        _sizeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0, 33.0, 10.0, 16.0)];
        _sizeLabel.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        _sizeLabel.font = [NSFont labelFontOfSize:[NSFont labelFontSize]];
        _sizeLabel.textColor = [NSColor textColor];
        _sizeLabel.bezeled = NO;
        _sizeLabel.drawsBackground = NO;
        _sizeLabel.editable = NO;
        _sizeLabel.selectable = YES;
        _sizeLabel.alignment = NSRightTextAlignment;
        [_contentView addSubview:_sizeLabel];
        
        _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 0.0, 0.0)];
        _imageView.wantsLayer = YES;
        _imageView.layer.borderColor = [[NSColor colorWithCalibratedWhite:0.0 alpha:0.3] CGColor];
        _imageView.layer.borderWidth = 1.0;
        [_contentView addSubview:_imageView];
    }
    return self;
}

- (void)setImage:(NSImage *)image
{
    _image = image;
    NSString *infoString = @"";
    if (image) {
        CGFloat width = image.size.width;
        CGFloat height = image.size.height;
        for (NSImageRep *representation in image.representations) {
            width = fmax(width, representation.pixelsWide);
            height = fmax(height, representation.pixelsHigh);
        }
        infoString = [NSString stringWithFormat:@"%d × %d", (int)round(width), (int)round(height)];
    }
    _sizeLabel.stringValue = infoString;
    
    [self _updateDisplay];
}

- (void)setFrameTopRightPoint:(NSPoint)point
{
    _frameTopRightPoint = point;
    [self _updateDisplay];
}

- (void)_updateDisplay
{
    int factor = 1;
    if (!_image) {
        return;
    }
    
    //Crash on multi monitors(Display) becuase some time value is in -ve
    NSPoint tempPoint = CGPointMake(fabs(_frameTopRightPoint.x), fabs(_frameTopRightPoint.y));
    
    //if image doesn't fit screen, scale by even factors until it does
    while ((tempPoint.y < (_image.size.height / factor)) || (tempPoint.x < (_image.size.width / factor))) {
        factor += 1;
    }
    
    if (factor == 1) {
        _scalingLabel.stringValue = @"";
    }
    else {
        _scalingLabel.stringValue = [NSString stringWithFormat:@"(Scaled to 1/%d)", factor];
    }
    
    NSSize imageSize = NSMakeSize(_image.size.width / (CGFloat)factor, _image.size.height / (CGFloat)factor);
    
    //ensure window is wide enough to display size info
    CGFloat stringWidth = [_sizeLabel.stringValue sizeWithAttributes: @{ NSFontAttributeName : _sizeLabel.font }].width;
    CGFloat width = fmax(stringWidth + 6.0, imageSize.width);
    
    NSRect displayFrame = NSMakeRect(_frameTopRightPoint.x - width,
                                     _frameTopRightPoint.y - imageSize.height - _sizeLabel.frame.size.height,
                                     width,
                                     imageSize.height + _sizeLabel.frame.size.height);
    
    _imageView.frame = NSMakeRect(width - imageSize.width, 0.0, imageSize.width, imageSize.height);
    _imageView.image = _image;
    
    [self setFrame:displayFrame display:YES animate:NO];
    
    _contentView.frame = NSMakeRect(0.0, 0.0, displayFrame.size.width, displayFrame.size.height);
}

@end
