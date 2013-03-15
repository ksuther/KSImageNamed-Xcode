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

NSString * const KSShowExtensionInImageCompletionDefaultKey = @"KSShowExtensionInImageCompletion";

@interface KSImageNamed () {
    NSTimer *_updateTimer;
    KSImageNamedPreviewWindow *_imageWindow;
}
@property(nonatomic, strong) NSMutableDictionary *imageCompletions;
@property(nonatomic, strong) NSMutableSet *indexesToUpdate;
@end

@implementation KSImageNamed

+ (void)pluginDidLoad:(NSBundle *)plugin
{
	[self sharedPlugin];
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

- (void)_rebuildCompletionsTimerFired:(NSTimer *)timer
{
    for (id nextIndex in [self indexesToUpdate]) {
        [self _rebuildCompletionsForIndex:nextIndex];
    }
    
    [[self indexesToUpdate] removeAllObjects];
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
    
    for (id nextResult in result) {
        NSString *fileName = [nextResult fileName];
        
        if (![imageCompletionItems objectForKey:fileName]) {
            //Is this a 2x image? Maybe we already added a 1x version that we can mark as having a 2x version
            NSString *imageName = [fileName stringByDeletingPathExtension];
            BOOL skip = NO;
            NSString *normalFileName = nil;
            
            if ([imageName hasSuffix:@"@2x"]) {
                normalFileName = [[imageName substringToIndex:[imageName length] - 3] stringByAppendingFormat:@".%@", [fileName pathExtension]];
            } else if ([imageName hasSuffix:@"@2x~ipad"]) {
                //2x iPad images need to be handled separately since (image~ipad and image@2x~ipad are valid pairs)
                normalFileName = [[[imageName substringToIndex:[imageName length] - 8] stringByAppendingString:@"~ipad"] stringByAppendingFormat:@".%@", [fileName pathExtension]];
            }
            
            if (normalFileName) {
                KSImageNamedIndexCompletionItem *existingCompletionItem = [imageCompletionItems objectForKey:normalFileName];
                
                if (existingCompletionItem) {
                    [existingCompletionItem setHas2x:YES];
                    skip = YES;
                }
            }
            
            if (!skip && [[nextResult fileDataTypePresumed] conformsToAnyIdentifierInSet:imageTypes]) {
                KSImageNamedIndexCompletionItem *imageCompletion = [[KSImageNamedIndexCompletionItem alloc] initWithFileURL:[nextResult fileReferenceURL] includeExtension:includeExtension];
                
                [completionItems addObject:imageCompletion];
                [imageCompletionItems setObject:imageCompletion forKey:fileName];
            }
        }
    }
    
    return completionItems;
}

@end
