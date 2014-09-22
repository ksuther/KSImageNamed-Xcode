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
@property(nonatomic) long long selectedCompletionIndex;
@property(retain) NSArray *filteredCompletionsAlpha;
@property(retain) NSArray *allCompletions;

- (BOOL)shouldAutoSuggestForTextChange;
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

@interface IDEIndexCompletionStrategy : NSObject
- (id)completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 areDefinitive:(char *)arg3; // Xcode 5
- (id)completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 highlyLikelyCompletionItems:(id *)arg3 areDefinitive:(char *)arg4; // Xcode 6
@end
