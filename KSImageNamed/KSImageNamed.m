//
//  KSImageNamed.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KSImageNamed.h"
#import "KSImageNamedIndexCompletionItem.h"
#import "XcodeMisc.h"

NSString * const KSShowExtensionInImageCompletionDefaultKey = @"KSShowExtensionInImageCompletion";

@interface KSImageNamed () {
    NSTimer *_updateTimer;
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
        return [[obj1 fileName] caseInsensitiveCompare:[obj2 fileName]];
    }];
    
    BOOL includeExtension = [[NSUserDefaults standardUserDefaults] boolForKey:KSShowExtensionInImageCompletionDefaultKey];
    
    for (id nextResult in result) {
        NSString *fileName = [nextResult fileName];
        
        if (![imageCompletionItems objectForKey:fileName]) {
            //Is this a 2x image? Maybe we already added a 1x version that we can mark as having a 2x version
            NSString *imageName = [fileName stringByDeletingPathExtension];
            BOOL skip = NO;
            
            if ([imageName hasSuffix:@"@2x"]) {
                NSString *normalFileName = [[imageName substringToIndex:[imageName length] - 3] stringByAppendingFormat:@".%@", [fileName pathExtension]];
                KSImageNamedIndexCompletionItem *existingCompletionItem = [imageCompletionItems objectForKey:normalFileName];
                
                if (existingCompletionItem) {
                    [existingCompletionItem setHas2x:YES];
                    skip = YES;
                }
            }
            
            if (!skip && [[nextResult fileDataTypePresumed] conformsToAnyIdentifierInSet:imageTypes]) {
                KSImageNamedIndexCompletionItem *imageCompletion = [[KSImageNamedIndexCompletionItem alloc] initWithFileName:fileName includeExtension:includeExtension];
                
                [completionItems addObject:imageCompletion];
                [imageCompletionItems setObject:imageCompletion forKey:fileName];
            }
        }
    }
    
    return completionItems;
}

@end
