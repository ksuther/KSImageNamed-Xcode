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

- (id)initWithFileName:(NSString *)fileName includeExtension:(BOOL)includeExtension prefix:(NSString *)prefix
{
    if ( (self = [super init]) ) {
        [self setFileName:fileName];
        
        _imageIncludeExtension = includeExtension;
        _imageCompletionText = [self _imageNamedText];
        
        if (prefix) {
            //Adjust the completion text based on the prefix
            //This allows completion to continue if someone starts typing @ or @"
            NSRange range = [_imageCompletionText rangeOfString:prefix options:NSAnchoredSearch];
            
            _imageCompletionText = [_imageCompletionText substringFromIndex:NSMaxRange(range)];
        }
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
    NSString *displayFormat = [self has2x] ? @"%@ (%@, 2x)" : @"%@ (%@)";
    
    return [NSString stringWithFormat:displayFormat, [self _imageNamedText], [[self fileName] pathExtension]];
}

- (NSString *)_fileName
{
    NSString *fileName = [self fileName];
    
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
