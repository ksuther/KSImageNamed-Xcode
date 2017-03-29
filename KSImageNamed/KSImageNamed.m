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
    static id sharedPlugin;
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
    NSString *workspaceName = [index respondsToSelector:@selector(workspaceName)] ? [index workspaceName] : [[index workspace] name];
    
    if (workspaceName && [[self imageCompletions] objectForKey:workspaceName]) {
        [[self imageCompletions] removeObjectForKey:workspaceName];
    }
}

- (NSArray *)imageCompletionsForIndex:(id)index language:(id)language
{
    NSString *workspaceName = [index respondsToSelector:@selector(workspaceName)] ? [index workspaceName] : [[index workspace] name];
    NSArray *completions = [[self imageCompletions] objectForKey:workspaceName];
    
    if (!completions) {
        completions = [self _rebuildCompletionsForIndex:index];
    }

    BOOL forSwift = [[language identifier] isEqualToString:@"Xcode.SourceCodeLanguage.Swift"];

    for (KSImageNamedIndexCompletionItem *nextCompletionItem in completions) {
        [nextCompletionItem setForSwift:forSwift];
    }
    
    return completions;
}

- (NSSet<NSString *> *)completionStringsForType:(KSImageNamedCompletionStringType)type
{
    //Pulls completions out of Completions.plist and creates arrays so the rest of the plugin can do lookups to see if it should be autocompleting a particular method
    //The three different strings are needed because this plugin does raw string matching rather than doing anything fancy like looking at the AST
    static NSSet<NSString *> *classAndMethodCompletionStrings;
    static NSSet<NSString *> *methodDeclarationCompletionStrings;
    static NSSet<NSString *> *methodNameCompletionStrings;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *completionsURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Completions" withExtension:@"plist"];
        NSArray *completionStrings = [NSArray arrayWithContentsOfURL:completionsURL];
        
        NSMutableSet<NSString *> *mutableClassAndMethodCompletionStrings = [[NSMutableSet alloc] init];
        NSMutableSet<NSString *> *mutableMethodDeclarationCompletionStrings = [[NSMutableSet alloc] init];
        NSMutableSet<NSString *> *mutableMethodNameCompletionStrings = [[NSMutableSet alloc] init];
        
        for (NSDictionary *nextCompletionDictionary in completionStrings) {
            [mutableClassAndMethodCompletionStrings addObject:[nextCompletionDictionary objectForKey:@"classAndMethod"]];
            [mutableMethodDeclarationCompletionStrings addObject:[nextCompletionDictionary objectForKey:@"methodDeclaration"]];
            [mutableMethodNameCompletionStrings addObject:[nextCompletionDictionary objectForKey:@"methodName"]];
        }

        classAndMethodCompletionStrings = [mutableClassAndMethodCompletionStrings copy];
        methodDeclarationCompletionStrings = [mutableMethodDeclarationCompletionStrings copy];
        methodNameCompletionStrings = [mutableMethodNameCompletionStrings copy];
    });
    
    NSSet *completionStrings;
    
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
    NSString *workspaceName = [index respondsToSelector:@selector(workspaceName)] ? [index workspaceName] : [[index workspace] name];
    NSArray *completions;
    
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
                NSString *imageName = [fileName stringByDeletingPathExtension];
                NSString *normalFileName;
                BOOL skip = NO;
                BOOL is2x = NO;
                BOOL is3x = NO;
                
                if ([imageName hasSuffix:@"@3x"]) {
                    normalFileName = [[imageName substringToIndex:[imageName length] - 3] stringByAppendingFormat:@".%@", [fileName pathExtension]];
                    is3x = YES;
                }else if ([imageName hasSuffix:@"@2x"]) {
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
                    if (is3x) {
                        existingCompletionItem.has2x = YES;
                    }else if (is2x) {
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
    NSMutableDictionary<NSURL *, NSString *> *namespaces = [NSMutableDictionary dictionary];
    
    for (NSURL *nextURL in enumerator) {
        NSString *fileName;
        NSNumber *isDirectory;
        
        if ([nextURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL] && [nextURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL] && [isDirectory boolValue]) {
            if ([[fileName pathExtension] caseInsensitiveCompare:@"imageset"] == NSOrderedSame) {
                NSString *namespace = [namespaces objectForKey:[nextURL URLByDeletingLastPathComponent]];
                KSImageNamedIndexCompletionItem *imageCompletion = [[KSImageNamedIndexCompletionItem alloc] initWithAssetFileURL:nextURL namespace:namespace];

                if ([imageCompletion imageFileURL]) {
                    // Only add the completion if there's an image in the set
                    [imageCompletions addObject:imageCompletion];
                }
                
                [enumerator skipDescendants];
            } else if ([[fileName pathExtension] length] == 0) {
                // Check if this directory defines a namespace
                NSURL *contentsURL = [nextURL URLByAppendingPathComponent:@"Contents.json"];
                NSData *contentsData = [NSData dataWithContentsOfURL:contentsURL];
                BOOL registeredNamespace = NO;

                if (contentsData) {
                    NSDictionary *contentsJSON = [NSJSONSerialization JSONObjectWithData:contentsData options:0 error:NULL];

                    if ([contentsJSON isKindOfClass:[NSDictionary class]]) {
                        BOOL providesNamespace = [[[contentsJSON objectForKey:@"properties"] objectForKey:@"provides-namespace"] boolValue];

                        if (providesNamespace) {
                            // Add the namespace to the namespaces dictionary
                            NSURL *namespaceKey = nextURL;
                            NSString *namespace = fileName;

                            // Check if there's a parent namespace (namespaces can be nested)
                            NSURL *parentNamespaceKey = [namespaceKey URLByDeletingLastPathComponent];
                            NSString *parentNamespace = [namespaces objectForKey:parentNamespaceKey];

                            if (parentNamespace) {
                                namespace = [parentNamespace stringByAppendingPathComponent:namespace];
                            }

                            [namespaces setObject:namespace forKey:namespaceKey];

                            registeredNamespace = YES;
                        }
                    }
                }

                if (!registeredNamespace) {
                    // There may be a parent namespace that we need to inherit
                    NSURL *inheritedNamespaceKey = [nextURL URLByDeletingLastPathComponent];
                    NSString *inheritedNamespace = [namespaces objectForKey:inheritedNamespaceKey];

                    if (inheritedNamespace) {
                        [namespaces setObject:inheritedNamespace forKey:nextURL];
                    }
                }
            }
        }
    }
    
    return imageCompletions;
}

@end
