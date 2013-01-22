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

@interface KSImageNamed ()
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
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (NSArray *)imageCompletionsForIndex:(id)index prefix:(NSString *)prefix
{
    id result = [index filesContaining:@"" anchorStart:NO anchorEnd:NO subsequence:NO ignoreCase:YES cancelWhen:nil];
    NSSet *imageTypes = [NSSet setWithArray:[NSImage imageTypes]];
    
    NSMutableArray *completionItems = [NSMutableArray array];
    NSMutableDictionary *imageCompletionItems = [NSMutableDictionary dictionary];
    
    //Sort results so @2x is sorted after the 1x image
    result = [[result uniqueObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 fileName] caseInsensitiveCompare:[obj2 fileName]];
    }];
    
    //Handle the @" prefix that people may type when using imageNamed
    //Doesn't automatically pop up autocomplete but at least it'll show matches if they explicitly show autocomplete
    if (![prefix isEqualToString:@"@"]) {
        if ([prefix hasPrefix:@"@\""]) {
            prefix = @"@\"";
        } else {
            prefix = nil;
        }
    }
    
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
                KSImageNamedIndexCompletionItem *imageCompletion = [[KSImageNamedIndexCompletionItem alloc] initWithFileName:fileName includeExtension:includeExtension prefix:prefix];
                
                [completionItems addObject:imageCompletion];
                [imageCompletionItems setObject:imageCompletion forKey:fileName];
            }
        }
    }
    
    return completionItems;
}

@end
