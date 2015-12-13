//
//  KSImageNamedIndexCompletionItem.h
//  KSImageNamed
//
//  Created by Kent Sutherland on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVTSourceCodeSymbolKind : NSObject
{
    NSString *_identifier;
    NSString *_localizedDescription;
    NSArray *_conformedToSymbolKindIdentifiers;
    NSArray *_conformedToSymbolKinds;
    NSArray *_allConformingSymbolKinds;
}

+ (id)sourceCodeSymbolKinds;
+ (id)sourceCodeSymbolKindForIdentifier:(id)arg1;
+ (id)_sourceCodeSymbolKindForExtension:(id)arg1;
+ (void)initialize;
+ (id)classMethodTemplateSymbolKind;
+ (id)instanceMethodTemplateSymbolKind;
+ (id)functionTemplateSymbolKind;
+ (id)classTemplateSymbolKind;
+ (id)namespaceSymbolKind;
+ (id)ibOutletCollectionPropertySymbolKind;
+ (id)ibOutletCollectionVariableSymbolKind;
+ (id)ibOutletCollectionSymbolKind;
+ (id)ibOutletPropertySymbolKind;
+ (id)ibOutletVariableSymbolKind;
+ (id)ibOutletSymbolKind;
+ (id)ibActionMethodSymbolKind;
+ (id)globalVariableSymbolKind;
+ (id)localVariableSymbolKind;
+ (id)unionSymbolKind;
+ (id)typedefSymbolKind;
+ (id)structSymbolKind;
+ (id)protocolSymbolKind;
+ (id)propertySymbolKind;
+ (id)parameterSymbolKind;
+ (id)macroSymbolKind;
+ (id)classVariableSymbolKind;
+ (id)instanceVariableSymbolKind;
+ (id)instanceMethodSymbolKind;
+ (id)functionSymbolKind;
+ (id)fieldSymbolKind;
+ (id)enumConstantSymbolKind;
+ (id)enumSymbolKind;
+ (id)classSymbolKind;
+ (id)classMethodSymbolKind;
+ (id)categorySymbolKind;
+ (id)memberContainerSymbolKind;
+ (id)memberSymbolKind;
+ (id)callableSymbolKind;
+ (id)globalSymbolKind;
+ (id)containerSymbolKind;
@property(readonly) NSString *localizedDescription; // @synthesize localizedDescription=_localizedDescription;
@property(readonly) NSString *identifier; // @synthesize identifier=_identifier;
- (BOOL)conformsToSymbolKind:(id)arg1;
@property(readonly, getter=isContainer) BOOL container;
@property(readonly) NSArray *allConformingSymbolKinds;
@property(readonly) NSArray *conformedToSymbolKinds;
- (id)copyWithZone:(struct _NSZone *)arg1;
- (id)description;
- (id)initWithSourceCodeSymbolKindExtension:(id)arg1;

@end

@interface IDEIndexCompletionItem : NSObject
{
    void *_completionResult;
    NSString *_displayText;
    NSString *_displayType;
    NSString *_completionText;
    NSAttributedString *_descriptionText;
    NSString *_parentText;
    DVTSourceCodeSymbolKind *_symbolKind;
    double _priority;
    NSString *_name;
    BOOL _notRecommended;
    double _fuzzyMatchingScore;
}

@property double fuzzyMatchingScore; // @synthesize fuzzyMatchingScore=_fuzzyMatchingScore;
@property double priority; // @synthesize priority=_priority;
@property(readonly) NSString *name; // @synthesize name=_name;
@property(readonly) BOOL notRecommended;
@property(readonly) DVTSourceCodeSymbolKind *symbolKind;
@property(readonly) NSAttributedString *descriptionText;
@property(readonly, copy) NSString *parentText;
@property(readonly) NSString *completionText;
@property(readonly) NSString *displayType;
@property(readonly) NSString *displayText;
- (void)_fillInTheRest;
- (id)description;
- (id)initWithCompletionResult:(void *)arg1;

@end

@interface KSImageNamedIndexCompletionItem : IDEIndexCompletionItem

@property(nonatomic, strong) NSURL *fileURL;
@property(nonatomic, strong, readonly) NSURL *imageFileURL; //derived from fileURL
@property(nonatomic, strong, readonly) NSString *fileName;
@property(nonatomic, assign) BOOL has1x;
@property(nonatomic, assign) BOOL has2x;
@property(nonatomic, assign) BOOL has3x;
@property(nonatomic, assign) BOOL forSwift;
@property(nonatomic, assign, getter=isInAssetCatalog, readonly) BOOL inAssetCatalog;

- (id)initWithFileURL:(NSURL *)fileURL includeExtension:(BOOL)includeExtension;
- (id)initWithAssetFileURL:(NSURL *)fileURL;

@end
