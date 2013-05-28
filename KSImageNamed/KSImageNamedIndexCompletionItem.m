//
//  KSImageNamedIndexCompletionItem.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KSImageNamedIndexCompletionItem.h"
#import <objc/runtime.h>

@interface KSImageNamedIndexCompletionItem () {
    NSString *_imageCompletionText;
    BOOL _imageIncludeExtension;
}
@end

@implementation KSImageNamedIndexCompletionItem

- (id)initWithFileURL:(NSURL *)fileURL includeExtension:(BOOL)includeExtension
{
    if ( (self = [super init]) ) {
        [self setFileURL:fileURL];
        
        _imageIncludeExtension = includeExtension;
        _imageCompletionText = [self _imageNamedText];
    }
    return self;
}

- (void)_fillInTheRest
{
    
}

- (long long)priority
{
    return 9999;
}

- (NSString *)fileName
{
    return [self _fileName];
}

- (NSString *)name
{
    return [self _fileName];
}

- (BOOL)notRecommended
{
    return NO;
}

- (DVTSourceCodeSymbolKind *)symbolKind
{
    return nil;
}

- (NSString *)completionText
{
    return _imageCompletionText;
}

- (NSString *)displayType
{
    return @"NSString *";
}

- (NSString *)displayText
{
    NSString *displayFormat = nil;//[self has2x] ? @"%@ (%@, 2x)" : @"%@ (%@)";
    if(self.has2x && self.has1x)
    {
        displayFormat = @"%@ (%@, 2x,combo)";
    }
    else if(self.has2x)
    {
        displayFormat = @"%@ (%@, 2x,only)";
    }
    else if(self.has1x)
    {
        displayFormat = @"%@ (%@)";
    }
    return [NSString stringWithFormat:displayFormat, [self _imageNamedText], [[self fileURL] pathExtension]];
}

- (NSString *)_fileName
{
    NSString *fileName = [[self fileURL] lastPathComponent];
    NSString *imageName = [fileName stringByDeletingPathExtension];

    if ([imageName hasSuffix:@"@2x"]) {
        fileName = [[imageName substringToIndex:[imageName length] - 3] stringByAppendingFormat:@".%@", [fileName pathExtension]];
    } else if ([imageName hasSuffix:@"@2x~ipad"]) {
        //2x iPad images need to be handled separately since (image~ipad and image@2x~ipad are valid pairs)
        fileName = [[[imageName substringToIndex:[imageName length] - 8] stringByAppendingString:@"~ipad"] stringByAppendingFormat:@".%@", [fileName pathExtension]];
    }
    if (!_imageIncludeExtension) {
        fileName = [fileName stringByDeletingPathExtension];
    }
    
    return fileName;
}

- (NSString *)_imageNamedText
{
    return [NSString stringWithFormat:@"@\"%@\"", [self _fileName]];
}

@end
