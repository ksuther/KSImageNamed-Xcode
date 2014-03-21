//
//  KSImageNamed.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KSImageNamed.h"
#import "KSImageNamedIndexCompletionItem.h"
#import "KSImageNamedPreviewWindow.h"
#import "XcodeMisc.h"
#import "MethodSwizzle.h"

NSString * const KSShowExtensionInImageCompletionDefaultKey = @"KSShowExtensionInImageCompletion";

@interface KSImageNamed () {
    NSTimer *_updateTimer;
}
@property(nonatomic, strong) NSMutableDictionary *imageCompletions;
@property(nonatomic, strong) NSMutableSet *indexesToUpdate;
@property(nonatomic, strong) KSImageNamedPreviewWindow *imageWindow;
@end

@implementation KSImageNamed

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    if ([self shouldLoadPlugin]) {
        [self sharedPlugin];
    }
}

+ (instancetype)sharedPlugin
{
    static id sharedPlugin = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedPlugin = [[self alloc] init];
	});

    return sharedPlugin;
}

+ (BOOL)shouldLoadPlugin
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    return bundleIdentifier && [bundleIdentifier caseInsensitiveCompare:@"com.apple.dt.Xcode"] == NSOrderedSame;
}

- (id)init
{
    if ( (self = [super init]) ) {
        [self setImageCompletions:[NSMutableDictionary dictionary]];
        [self setIndexesToUpdate:[NSMutableSet set]];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self setImageCompletions:nil];
    [self setIndexesToUpdate:nil];
    [self setImageWindow:nil];
    
    [super dealloc];
}

- (KSImageNamedPreviewWindow *)imageWindow
{
    if (!_imageWindow) {
        _imageWindow = [[KSImageNamedPreviewWindow alloc] init];
    }
    return _imageWindow;
}

- (void)indexNeedsUpdate:(id)index
{
    //Coalesce completion rebuilds to avoid hangs when Xcode rebuilds an index one file a time
    [[self indexesToUpdate] addObject:index];
    
    [_updateTimer invalidate];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(_rebuildCompletionsTimerFired:) userInfo:nil repeats:NO];
}

- (void)removeImageCompletionsForIndex:(id)index
{
    NSString *workspaceName = [index workspaceName];
    
    if (workspaceName && [[self imageCompletions] objectForKey:workspaceName]) {
        [[self imageCompletions] removeObjectForKey:workspaceName];
    }
}

- (NSArray *)imageCompletionsForIndex:(id)index
{
    NSArray *completions = [[self imageCompletions] objectForKey:[index workspaceName]];
    
    if (!completions) {
        completions = [self _rebuildCompletionsForIndex:index];
    }
    
    return completions;
}

- (NSSet *)completionStringsForType:(KSImageNamedCompletionStringType)type
{
    //Pulls completions out of Completions.plist and creates arrays so the rest of the plugin can do lookups to see if it should be autocompleting a particular method
    //The three different strings are needed because this plugin does raw string matching rather than doing anything fancy like looking at the AST
    static NSMutableSet *classAndMethodCompletionStrings;
    static NSMutableSet *methodDeclarationCompletionStrings;
    static NSMutableSet *methodNameCompletionStrings;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *completionsURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Completions" withExtension:@"plist"];
        NSArray *completionStrings = [NSArray arrayWithContentsOfURL:completionsURL];
        
        classAndMethodCompletionStrings = [[NSMutableSet alloc] init];
        methodDeclarationCompletionStrings = [[NSMutableSet alloc] init];
        methodNameCompletionStrings = [[NSMutableSet alloc] init];
        
        for (NSDictionary *nextCompletionDictionary in completionStrings) {
            [classAndMethodCompletionStrings addObject:[nextCompletionDictionary objectForKey:@"classAndMethod"]];
            [methodDeclarationCompletionStrings addObject:[nextCompletionDictionary objectForKey:@"methodDeclaration"]];
            [methodNameCompletionStrings addObject:[nextCompletionDictionary objectForKey:@"methodName"]];
        }
    });
    
    NSSet *completionStrings = nil;
    
    if (type == KSImageNamedCompletionStringTypeClassAndMethod) {
        completionStrings = classAndMethodCompletionStrings;
    } else if (type == KSImageNamedCompletionStringTypeMethodDeclaration) {
        completionStrings = methodDeclarationCompletionStrings;
    } else if (type == KSImageNamedCompletionStringTypeMethodName) {
        completionStrings = methodNameCompletionStrings;
    }
    
    return completionStrings;
}

#pragma mark - Private

- (void)_rebuildCompletionsTimerFired:(NSTimer *)timer
{
    for (id nextIndex in [self indexesToUpdate]) {
        [self _rebuildCompletionsForIndex:nextIndex];
    }
    
    [[self indexesToUpdate] removeAllObjects];
    
    _updateTimer = nil;
}

- (NSArray *)_rebuildCompletionsForIndex:(id)index
{
    NSString *workspaceName = [index workspaceName];
    NSArray *completions = nil;
    
    if (workspaceName) {
        if ([[self imageCompletions] objectForKey:workspaceName]) {
            [[self imageCompletions] removeObjectForKey:workspaceName];
        }
        
        completions = [self _imageCompletionsForIndex:index];
        
        if (completions) {
            [[self imageCompletions] setObject:completions forKey:workspaceName];
        }
    }
    
    return completions;
}

- (NSArray *)_imageCompletionsForIndex:(id)index
{
    id result = [index filesContaining:@"" anchorStart:NO anchorEnd:NO subsequence:NO ignoreCase:YES cancelWhen:nil];
    NSSet *imageTypes = [NSSet setWithArray:[NSImage imageTypes]];
    
    NSMutableArray *completionItems = [NSMutableArray array];
    NSMutableDictionary *imageCompletionItems = [NSMutableDictionary dictionary];
    
    //Sort results so @2x is sorted after the 1x image
    result = [[result uniqueObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *fileName1 = [obj1 fileName];
        NSString *fileName2 = [obj2 fileName];
        NSComparisonResult result = [fileName1 caseInsensitiveCompare:fileName2];
        BOOL is2xiPad1 = [[fileName1 stringByDeletingPathExtension] hasSuffix:@"@2x~ipad"];
        BOOL is2xiPad2 = [[fileName2 stringByDeletingPathExtension] hasSuffix:@"@2x~ipad"];
        
        //@2x~ipad should be sorted after ~ipad
        //This ensures that the 2x detection in the loop below works correctly for 2x iPad images
        //Otherwise @2x~ipad will be checked before ~ipad and the 2x property won't be set correctly
        if (is2xiPad1 && !is2xiPad2) {
            result = NSOrderedDescending;
        } else if (!is2xiPad1 && is2xiPad2) {
            result = NSOrderedAscending;
        }
        
        return result;
    }];
    
    BOOL includeExtension = [[NSUserDefaults standardUserDefaults] boolForKey:KSShowExtensionInImageCompletionDefaultKey];
    BOOL encounteredAssetCatalog = NO;
    
    for (id nextResult in result) {
        NSString *fileName = [nextResult fileName];
        
        if (![imageCompletionItems objectForKey:fileName]) {
            if ([[nextResult fileDataTypePresumed] conformsTo:@"com.apple.dt.assetcatalog"]) {
                //Iterate over asset catalog contents
                NSArray *assetCatalogCompletions = [self _imageCompletionsForAssetCatalog:nextResult];
                
                [completionItems addObjectsFromArray:assetCatalogCompletions];
                
                for (KSImageNamedIndexCompletionItem *nextImageCompletion in assetCatalogCompletions) {
                    [imageCompletionItems setObject:nextImageCompletion forKey:[nextImageCompletion fileName]];
                }
                
                encounteredAssetCatalog = YES;
            } else {
                //Is this a 2x image? Maybe we already added a 1x version that we can mark as having a 2x version
                //Is this a 2x image? Maybe we already added a 1x version that we can mark as having a 2x version
                NSString *imageName = [fileName stringByDeletingPathExtension];
                NSString *normalFileName;
                BOOL skip = NO;
                BOOL is2x = NO;
                
                if ([imageName hasSuffix:@"@2x"]) {
                    normalFileName = [[imageName substringToIndex:[imageName length] - 3] stringByAppendingFormat:@".%@", [fileName pathExtension]];
                    is2x = YES;
                } else if ([imageName hasSuffix:@"@2x~ipad"]) {
                    //2x iPad images need to be handled separately since (image~ipad and image@2x~ipad are valid pairs)
                    normalFileName = [[[imageName substringToIndex:[imageName length] - 8] stringByAppendingString:@"~ipad"] stringByAppendingFormat:@".%@", [fileName pathExtension]];
                    is2x = YES;
                } else {
                    normalFileName = fileName;
                }
                
                KSImageNamedIndexCompletionItem *existingCompletionItem = [imageCompletionItems objectForKey:normalFileName];
                
                if (existingCompletionItem) {
                    if (is2x) {
                        existingCompletionItem.has2x = YES;
                    } else {
                        existingCompletionItem.has1x = YES;
                    }
                    skip = YES;
                }
                
                if (!skip && [[nextResult fileDataTypePresumed] conformsToAnyIdentifierInSet:imageTypes]) {
                    KSImageNamedIndexCompletionItem *imageCompletion = [[KSImageNamedIndexCompletionItem alloc] initWithFileURL:[nextResult fileReferenceURL] includeExtension:includeExtension];
                    imageCompletion.has2x = is2x;
                    imageCompletion.has1x = !is2x;
                    [completionItems addObject:imageCompletion];
                    [imageCompletionItems setObject:imageCompletion forKey:fileName];
                }
            }
        }
    }
    
    if (encounteredAssetCatalog) {
        //Need to sort completionItems by fileName to ensure autocompletion in asset catalogs is handled correctly
        //Autocomplete doesn't work correctly if the completion items aren't in alphabetical order
        [completionItems sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    }
    
    return completionItems;
}

//arg1 is a DVTFilePath
- (NSArray *)_imageCompletionsForAssetCatalog:(id)filePath
{
    NSMutableArray *imageCompletions = [NSMutableArray array];
    NSArray *properties = @[NSURLNameKey, NSURLIsDirectoryKey];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:[filePath fileURL] includingPropertiesForKeys:properties options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
    
    for (NSURL *nextURL in enumerator) {
        NSString *fileName;
        NSNumber *isDirectory;
        
        if ([nextURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL] && [nextURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL] && [isDirectory boolValue]) {
            if ([[fileName pathExtension] caseInsensitiveCompare:@"imageset"] == NSOrderedSame) {
                KSImageNamedIndexCompletionItem *imageCompletion = [[[KSImageNamedIndexCompletionItem alloc] initWithAssetFileURL:nextURL] autorelease];
                
                [imageCompletions addObject:imageCompletion];
                
                [enumerator skipDescendants];
            }
        }
    }
    
    return imageCompletions;
}

@end
