//
//  XcodeMisc.h
//  KSImageNamed
//
//  Created by Kent Sutherland on 1/19/13.
//
//

#import <Cocoa/Cocoa.h>

//Miscellaneous declarations pulled from class dumps of DVTFoundation, DVTKit, IDEFoundation, IDEKit

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
- (BOOL)conformsToAnyIdentifierInSet:(id)arg1;
- (id)databaseQueryProvider;
- (id)codeCompletionsAtLocation:(id)arg1 withCurrentFileContentDictionary:(id)arg2 completionContext:(id *)arg3 sortedUsingBlock:(id)arg4;
- (NSRange)characterRange; //DVTTextDocumentLocation
- (NSRange)lineRange; //DVTTextDocumentLocation

- (id)workspace;
- (id)index;
- (NSString *)workspaceName;

- (id)symbolNameAtCharacterIndex:(unsigned long long)arg1 nameRanges:(id *)arg2; //DVTSourceTextStorage
- (id)sourceModelItemAtCharacterIndex:(unsigned long long)arg1; //DVTSourceTextStorage
- (id)sourceModel; //DVTSourceTextStorage

- (id)stringConstantAtLocation:(unsigned long long)arg1; //DVTSourceModel

- (id)previousItem; //DVTSourceModelItem
@end

@interface DVTCompletingTextView : NSTextView
- (BOOL)shouldAutoCompleteAtLocation:(unsigned long long)arg1;
@end

@interface IDEIndexCompletionStrategy : NSObject
- (id)completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 areDefinitive:(char *)arg3;
@end
