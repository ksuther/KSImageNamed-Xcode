//
//  XcodeMisc.h
//  KSImageNamed
//
//  Created by Kent Sutherland on 1/19/13.
//
//

#import <Cocoa/Cocoa.h>

//Miscellaneous declarations pulled from class dumps of DVTFoundation, DVTKit, IDEFoundation, IDEKit

@interface IDEIndex : NSObject
- (void)close;
@end

@interface IDEWorkspace : NSObject
@property(retain) IDEIndex *index;

- (void)_updateIndexableFiles:(id)arg1;
@end

@interface IDEIndexCollection : NSObject <NSFastEnumeration>
{
    //IDEIndexDBTempTable *_tempTable;
    NSArray *_instantiatedRows;
}

//@property(readonly, nonatomic) IDEIndexDBTempTable *tempTable; // @synthesize tempTable=_tempTable;
- (id)uniqueObjects;
- (id)onlyObject;
- (id)firstObject;
//- (id)instantiateRow:(struct sqlite3_stmt *)arg1;
- (id)tempTableSchema;
- (id)allObjects;
//- (unsigned long long)countByEnumeratingWithState:(CDStruct_70511ce9 *)arg1 objects:(id *)arg2 count:(unsigned long long)arg3;
- (unsigned long long)instantiateRowsUpto:(unsigned long long)arg1;
- (void)finalize;
- (void)dropTempTable;
- (id)description;
- (id)initWithConnection:(id)arg1;
- (id)initWithArrayNoCopy:(id)arg1;
- (id)initWithArray:(id)arg1;
- (id)initWithObject:(id)arg1;
- (id)init;

@end

@interface NSObject ()
- (id)filesContaining:(id)arg1 anchorStart:(BOOL)arg2 anchorEnd:(BOOL)arg3 subsequence:(BOOL)arg4 ignoreCase:(BOOL)arg5 cancelWhen:(id)arg6;
- (id)fileDataTypePresumed;
- (BOOL)conformsTo:(id)arg1;
- (BOOL)conformsToAnyIdentifierInSet:(id)arg1;
- (id)databaseQueryProvider;
- (id)codeCompletionsAtLocation:(id)arg1 withCurrentFileContentDictionary:(id)arg2 completionContext:(id *)arg3 sortedUsingBlock:(id)arg4;
- (NSRange)characterRange; //DVTTextDocumentLocation
- (NSRange)lineRange; //DVTTextDocumentLocation

- (id)workspace;
- (id)index;
- (NSString *)workspaceName;

- (id)symbolNameAtCharacterIndex:(unsigned long long)arg1 nameRanges:(id *)arg2; //DVTSourceTextStorage
- (id)sourceModelItemAtCharacterIndex:(unsigned long long)arg1; //DVTSourceTextStorage in Xcode 5, DVTSourceLanguageSourceModelService protocol in Xcode 5.1
- (id)sourceModel; //DVTSourceTextStorage

@property(readonly) id sourceModelService; // DVTSourceTextStorage

- (id)stringConstantAtLocation:(unsigned long long)arg1; //DVTSourceModel

- (id)previousItem; //DVTSourceModelItem

- (id)_listWindowController; //DVTTextCompletionSession
@end

@interface DVTCompletingTextView : NSTextView
- (BOOL)shouldAutoCompleteAtLocation:(unsigned long long)arg1;
@end

@interface DVTSourceTextView : DVTCompletingTextView
@end


@interface DVTTextCompletionSession : NSObject
@property(nonatomic) NSInteger selectedCompletionIndex;
@property(retain) NSArray *filteredCompletionsAlpha;
@property(retain) NSArray *allCompletions;
@property(readonly) DVTCompletingTextView *textView;

- (BOOL)shouldAutoSuggestForTextChange;
- (NSRange)replacementRangeForSuggestedRange:(NSRange)arg1;
@end

@interface DVTTextCompletionController : NSObject
@property(retain) DVTTextCompletionSession *currentSession;
@property(readonly) DVTCompletingTextView *textView;
@property(getter=isAutoCompletionEnabled) BOOL autoCompletionEnabled;

- (void)textViewDidInsertText;
- (BOOL)acceptCurrentCompletion;
- (BOOL)_showCompletionsAtCursorLocationExplicitly:(BOOL)arg1;
- (BOOL)textViewShouldChangeTextInRange:(NSRange)arg1 replacementString:(id)replacementString;
@end

@interface DVTTextCompletionListWindowController : NSWindowController
- (id)_selectedCompletionItem;
- (void)showInfoPaneForCompletionItem:(id)arg1;
- (void)_hideWindow;
@end

@interface DVTTextCompletionStrategy : NSObject
{
}

//+ (CDUnknownBlockType)priorityComparator;
- (id)bestMatchForPrefix:(id)arg1 inCompletionItems:(id)arg2 withContext:(id)arg3;
- (id)additionalCompletionItemsForDocumentLocation:(id)arg1 context:(id)arg2;
- (id)completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 highlyLikelyCompletionItems:(id *)arg3 areDefinitive:(char *)arg4;
- (void)prepareForDocumentLocation:(id)arg1 context:(id)arg2;

@end

@interface IDEIndexCompletionStrategy : DVTTextCompletionStrategy
- (id)completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 areDefinitive:(char *)arg3; // Xcode 5
- (id)completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 highlyLikelyCompletionItems:(id *)arg3 areDefinitive:(char *)arg4; // Xcode 6
@end

@interface DVTDocumentLocation : NSObject
{
    NSDictionary *_docParams;
    NSDictionary *_locParams;
    NSURL *_documentURL;
    NSNumber *_timestamp;
}

+ (BOOL)supportsSecureCoding;
+ (id)documentLocationWithURLScheme:(id)arg1 path:(id)arg2 documentParameters:(id)arg3 locationParameters:(id)arg4;
@property(readonly) NSNumber *timestamp; // @synthesize timestamp=_timestamp;
@property(readonly) NSURL *documentURL; // @synthesize documentURL=_documentURL;
- (id)locationParameters;
- (id)documentParameters;
- (id)documentPath;
- (id)documentScheme;
- (void)dvt_writeToSerializer:(id)arg1;
- (id)dvt_initFromDeserializer:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
- (id)initWithCoder:(id)arg1;
- (id)dvt_persistableStringRepresentation;
- (id)dvt_initFromPersistableStringRepresentation:(id)arg1 error:(id *)arg2;
- (long long)compare:(id)arg1;
@property(readonly, copy) NSString *description;
- (BOOL)isEqualDisregardingTimestamp:(id)arg1;
- (BOOL)isEqualToDocumentLocationDisregardingDocumentURL:(id)arg1;
@property(readonly) unsigned long long hash;
- (BOOL)isEqual:(id)arg1;
- (id)copyWithURL:(id)arg1;
- (id)copyWithZone:(struct _NSZone *)arg1;
- (id)documentURLString;
- (id)initWithDocumentURL:(id)arg1 timestamp:(id)arg2;
- (id)init;

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly) Class superclass;

@end

@interface DVTTextDocumentLocation : DVTDocumentLocation
{
    long long _startingColumnNumber;
    long long _endingColumnNumber;
    long long _startingLineNumber;
    long long _endingLineNumber;
    struct _NSRange _characterRange;
    long long _locationEncoding;
}

+ (BOOL)supportsSecureCoding;
@property(readonly) long long locationEncoding; // @synthesize locationEncoding=_locationEncoding;
@property(readonly) struct _NSRange characterRange; // @synthesize characterRange=_characterRange;
@property(readonly) long long endingLineNumber; // @synthesize endingLineNumber=_endingLineNumber;
@property(readonly) long long startingLineNumber; // @synthesize startingLineNumber=_startingLineNumber;
@property(readonly) long long endingColumnNumber; // @synthesize endingColumnNumber=_endingColumnNumber;
@property(readonly) long long startingColumnNumber; // @synthesize startingColumnNumber=_startingColumnNumber;
- (id)dvt_persistableStringRepresentation;
- (id)dvt_initFromPersistableStringRepresentation:(id)arg1 error:(id *)arg2;
- (id)copyWithURL:(id)arg1;
- (long long)compare:(id)arg1;
- (BOOL)isEqualDisregardingTimestamp:(id)arg1;
- (BOOL)isEqualToDocumentLocationDisregardingDocumentURL:(id)arg1;
- (BOOL)isEqual:(id)arg1;
@property(readonly) struct _NSRange lineRange;
- (id)description;
- (void)dvt_writeToSerializer:(id)arg1;
- (id)dvt_initFromDeserializer:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
- (id)initWithCoder:(id)arg1;
- (id)initWithDocumentURL:(id)arg1 timestamp:(id)arg2 characterRange:(struct _NSRange)arg3;
- (id)initWithDocumentURL:(id)arg1 timestamp:(id)arg2 characterRange:(struct _NSRange)arg3 locationEncoding:(long long)arg4;
- (id)initWithDocumentURL:(id)arg1 timestamp:(id)arg2 lineRange:(struct _NSRange)arg3;
- (id)initWithDocumentURL:(id)arg1 timestamp:(id)arg2 startingColumnNumber:(long long)arg3 endingColumnNumber:(long long)arg4 startingLineNumber:(long long)arg5 endingLineNumber:(long long)arg6 characterRange:(struct _NSRange)arg7;
- (id)initWithDocumentURL:(id)arg1 timestamp:(id)arg2 startingColumnNumber:(long long)arg3 endingColumnNumber:(long long)arg4 startingLineNumber:(long long)arg5 endingLineNumber:(long long)arg6 characterRange:(struct _NSRange)arg7 locationEncoding:(long long)arg8;

@end

@interface DVTSourceModel : NSObject
{
    id _sourceBufferProvider;
    id _inputStream;
    id _scanner;
    struct _NSRange _dirtyRange;
    long long _batchDelta;
    id _sourceItems;
    BOOL _isDoingBatchEdit;
    id _nativeParser;
}

+ (void)initialize;
@property BOOL isDoingBatchEdit; // @synthesize isDoingBatchEdit=_isDoingBatchEdit;
@property long long batchDelta; // @synthesize batchDelta=_batchDelta;
@property struct _NSRange dirtyRange; // @synthesize dirtyRange=_dirtyRange;
@property(retain) id scanner; // @synthesize scanner=_scanner;
@property(retain) id sourceItems; // @synthesize sourceItems=_sourceItems;
@property(retain) id inputStream; // @synthesize inputStream=_inputStream;
@property(assign) id sourceBufferProvider; // @synthesize sourceBufferProvider=_sourceBufferProvider;
- (id)objCMethodNameForItem:(id)arg1 nameRanges:(id *)arg2;
- (BOOL)isItemDictionaryLiteral:(id)arg1;
- (BOOL)isItemObjectLiteral:(id)arg1;
- (BOOL)isItemForStatement:(id)arg1;
- (BOOL)isItemSemanticBlock:(id)arg1;
- (BOOL)isItemBracketExpression:(id)arg1;
- (BOOL)isItemAngleExpression:(id)arg1;
- (BOOL)isItemParenExpression:(id)arg1;
- (BOOL)isPostfixExpressionAtLocation:(unsigned long long)arg1;
- (BOOL)isInTokenizableCodeAtLocation:(unsigned long long)arg1;
- (BOOL)isInPlainCodeAtLocation:(unsigned long long)arg1;
- (BOOL)isInKeywordAtLocation:(unsigned long long)arg1;
- (BOOL)isIncompletionPlaceholderAtLocation:(unsigned long long)arg1;
- (BOOL)isInNumberConstantAtLocation:(unsigned long long)arg1;
- (BOOL)isInCharacterConstantAtLocation:(unsigned long long)arg1;
- (BOOL)isInIdentifierAtLocation:(unsigned long long)arg1;
- (BOOL)isInStringConstantAtLocation:(unsigned long long)arg1;
- (BOOL)isInIncludeStatementAtLocation:(unsigned long long)arg1;
- (BOOL)isInPreprocessorStatementAtLocation:(unsigned long long)arg1;
- (BOOL)isInDocCommentAtLocation:(unsigned long long)arg1;
- (BOOL)isInCommentAtLocation:(unsigned long long)arg1;
- (id)completionPlaceholderItemAtLocation:(unsigned long long)arg1;
- (id)identOrKeywordItemAtLocation:(unsigned long long)arg1;
- (id)objCDeclaratorItemAtLocation:(unsigned long long)arg1;
- (id)numberConstantAtLocation:(unsigned long long)arg1;
- (id)characterConstantAtLocation:(unsigned long long)arg1;
- (id)stringConstantAtLocation:(unsigned long long)arg1;
- (id)moduleImportStatementAtLocation:(unsigned long long)arg1;
- (id)includeStatementAtLocation:(unsigned long long)arg1;
- (id)preprocessorStatementAtLocation:(unsigned long long)arg1;
- (id)docCommentAtLocation:(unsigned long long)arg1;
- (id)commentAtLocation:(unsigned long long)arg1;
- (id)placeholderItemsFromItem:(id)arg1;
- (id)identifierItemsFromItem:(id)arg1;
- (id)commentBlockItems;
- (id)functionsAndMethodItems;
- (id)classItems;
- (void)addBlockItemsInTypeList:(long long *)arg1 fromItem:(id)arg2 toArray:(id)arg3;
- (void)addIdentifierItemsFromItem:(id)arg1 toArray:(id)arg2;
- (void)addItemsInTypeList:(long long *)arg1 fromItem:(id)arg2 toArray:(id)arg3;
- (id)functionOrMethodDefinitionAtLocation:(unsigned long long)arg1;
- (id)functionOrMethodAtLocation:(unsigned long long)arg1;
- (id)interfaceDeclarationAtLocation:(unsigned long long)arg1;
- (id)typeDeclarationAtLocation:(unsigned long long)arg1;
- (id)classAtLocation:(unsigned long long)arg1;
- (id)itemNameAtLocation:(unsigned long long)arg1 inTypeList:(long long *)arg2 nameRanges:(id *)arg3 scopeRange:(struct _NSRange *)arg4;
- (id)nameOfItem:(id)arg1 nameRanges:(id *)arg2 scopeRange:(struct _NSRange *)arg3;
//- (void)enumerateIdentifierItemsInRange:(struct _NSRange)arg1 usingBlock:(CDUnknownBlockType)arg2;
- (id)itemAtLocation:(unsigned long long)arg1 ofType:(id)arg2;
- (id)itemAtLocation:(unsigned long long)arg1 inTypeList:(long long *)arg2;
- (id)builtUpNameForItem:(id)arg1 nameRanges:(id *)arg2;
- (id)_builtUpNameForItem:(id)arg1 mutableNameRanges:(id)arg2;
- (id)_builtUpNameForSubTree:(id)arg1 mutableNameRanges:(id)arg2;
- (id)objectLiteralItemAtLocation:(unsigned long long)arg1;
- (id)parenItemAtLocation:(unsigned long long)arg1;
- (id)parenLikeItemAtLocation:(unsigned long long)arg1;
- (id)foldableBlockItemForLocation:(unsigned long long)arg1;
- (id)foldableBlockItemForLineAtLocation:(unsigned long long)arg1;
- (id)blockItemAtLocation:(unsigned long long)arg1;
- (long long)indentForItem:(id)arg1;
- (id)adjoiningItemAtLocation:(unsigned long long)arg1;
- (id)enclosingItemAtLocation:(unsigned long long)arg1;
- (id)_topLevelSourceItem;
- (void)parse;
- (void)doingBatchEdit:(BOOL)arg1;
- (void)dirtyRange:(struct _NSRange)arg1 changeInLength:(long long)arg2;
- (id)initWithSourceBufferProvider:(id)arg1;

@end
