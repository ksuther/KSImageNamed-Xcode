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
    BOOL _imageIncludeExtension;
}
@property(nonatomic, assign, getter=isInAssetCatalog) BOOL inAssetCatalog;
@end

@implementation KSImageNamedIndexCompletionItem

- (id)initWithFileURL:(NSURL *)fileURL includeExtension:(BOOL)includeExtension
{
    if ( (self = [super init]) ) {
        [self setFileURL:fileURL];
        
        _imageIncludeExtension = includeExtension;
    }
    return self;
}

- (id)initWithAssetFileURL:(NSURL *)fileURL
{
    if ( (self = [super init]) ) {
        [self setFileURL:fileURL];
        [self setInAssetCatalog:YES];
        
        _imageIncludeExtension = NO;
    }
    return self;
}

- (void)dealloc
{
    [self setFileURL:nil];
    
    [super dealloc];
}

- (void)_fillInTheRest
{
    
}

- (long long)priority
{
    return 9999;
}

- (NSURL *)imageFileURL
{
    NSURL *imageFileURL = nil;
    
    if ([self isInAssetCatalog]) {
        //Pull the first image out of the imageset's Contents.json
        NSURL *contentsURL = [[self fileURL] URLByAppendingPathComponent:@"Contents.json"];
        NSData *contentsData = [NSData dataWithContentsOfURL:contentsURL];
        
        if (contentsData) {
            NSDictionary *contentsJSON = [NSJSONSerialization JSONObjectWithData:contentsData options:0 error:NULL];
            
            if ([contentsJSON isKindOfClass:[NSDictionary class]]) {
                NSArray *images = [contentsJSON objectForKey:@"images"];
                
                // Ignore idiom, scale, slicing for now
                for (NSDictionary *nextImageDictionary in images) {
                    NSString *filename = [nextImageDictionary objectForKey:@"filename"];
                    
                    if (filename) {
                        imageFileURL = [[self fileURL] URLByAppendingPathComponent:filename];
                        break;
                    }
                }
            }
        }
    } else {
        imageFileURL = [self fileURL];
    }
    
    return imageFileURL;
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
    return [self _imageNamedText];
}

- (NSString *)displayType
{
    return @"NSString *";
}

- (NSString *)displayText
{
    NSString *displayFormat = @"%@ (%@)";
    
    if (self.has1x && self.has2x) {
        displayFormat = @"%@ (%@, 1x and 2x)";
    } else if (self.has1x) {
        displayFormat = @"%@ (%@, 1x only)";
    } else if (self.has2x) {
        displayFormat = @"%@ (%@, 2x only)";
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
