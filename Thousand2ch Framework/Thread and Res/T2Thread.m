//
//  T2Thread.m
//  Thousand
//
//  Created by R. Natori on 05/06/19.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2Thread.h"
#import "T2Res.h"
#import "T2ThreadFace.h"
#import "T2ListFace.h"
#import "T2SubThread.h"
#import "T2WebConnector.h"
#import "T2WebData.h"
#import "T2NSURLRequestAdditions.h"
#import "T2PluginProtocols.h"
#import "T2PluginManager.h"
#import "T2ResourceManager.h"
#import "T2LabeledCell.h"
#import "T2Posting.h"

static NSArray *__extensions = nil;

NSString *T2ThreadDidStartLoadingNotification = @"T2ThreadDidStartLoadingNotification";
NSString *T2ThreadDidProgressLoadingNotification = @"T2ThreadDidProgressLoadingNotification";
NSString *T2ThreadDidLoadResIndexesNotification = @"T2ThreadDidLoadResIndexesNotificationName";
NSString *T2ThreadDidUpdateStyleOfResIndexesNotification = @"T2ThreadDidUpdateStyleOfResIndexesNotificationName";
NSString *T2ThreadResIndexes = @"T2ThreadResIndexesName";

static NSMutableDictionary *__instancesDictionary = NULL;

static unsigned __maxDisplayResCount = 10000;
static unsigned __maxPopUpResCount = 1000;

@implementation T2Thread
+(void)initialize {
	if (__instancesDictionary) return;
	__extensions = [[NSArray arrayWithObjects:@"t2thread", @"plist", nil] retain];
	__instancesDictionary = [self createMutableDictionaryForIdentify];
}
+(NSMutableDictionary *)dictionaryForIndentify {
	return __instancesDictionary;
}
-(NSMutableDictionary *)dictionaryForIndentify {
	return __instancesDictionary;
}

#pragma mark -
-(NSArray *)dictionaryConvertingKeysForUse:(T2DictionaryConvertingUse)use {
	if (use == T2DictionaryEncoding) {
		NSArray *array = [NSArray arrayWithObjects:
						  @"internalPath",
						  @"threadFace",
						  @"draft",
						  @"lastLoadingDate",
						  @"extraInfo",
						  @"pathStyleDictionary",
						  @"indexesStyleDictionary",
						  @"threadListTitle",
						  nil];
		return array;
	}
	return [NSArray arrayWithObjects:
			@"internalPath",
			@"threadFace",
			@"draft",
			@"lastLoadingDate",
			@"extraInfo",
			@"pathStyleDictionary",
			@"indexesStyleDictionary",
			nil];
}

#pragma mark -
+(id)threadWithThreadFace:(T2ThreadFace *)threadFace {
	T2Thread *thread = [self objectWithInternalPath:[threadFace internalPath]];
	[thread setThreadFace:threadFace];
	return thread;
}
+(id)threadWithThreadFace:(T2ThreadFace *)threadFace resArray:(NSArray *)resArray {
	T2Thread *thread = [self objectWithInternalPath:[threadFace internalPath]];
	[thread setThreadFace:threadFace];
	if (resArray) [thread setResArray:resArray];
	return thread;
}

-(id)initWithThreadFace:(T2ThreadFace *)threadFace resArray:(NSArray *)resArray {
	self = [super initWithInternalPath:[threadFace internalPath]];
	[self setShouldSaveFile:YES];
	[self setThreadFace:threadFace];
	[self setResArray:resArray];
	
	_newResIndex = NSNotFound;
	
	return self;
}

-(void)dealloc {
	[self setWebConnector:nil];
	[self setIsLoading:NO];
	
	[self saveToFile];
	
	[_threadFace release];
	[_resArray release];
	[_loadedResIndexes release];
	
	[_idDictionary release];
	[_tripDictionary release];
	
	[_pathStyleDictionary release];
	[_indexesStyleDictionary release];
	[_styleUpdatedresIndexes release];
	
	[_progressInfo release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors

-(void)setThreadFace:(T2ThreadFace *)threadFace {
	setObjectWithRetainSynchronized(_threadFace, threadFace);
}
-(T2ThreadFace *)threadFace { return _threadFace; }

-(void)setResArray:(NSArray *)anArray {
	if (!_resArray && anArray) {
		setObjectWithRetainSynchronized(_resArray, anArray);
		[[T2PluginManager sharedManager] processThread:self appendingIndex:0];
	} else {
		setObjectWithRetainSynchronized(_resArray, anArray);
	}
	int resCount = [_resArray count];
	if ([_threadFace resCount] != resCount) {
		[_threadFace setResCount:resCount];
		[_threadFace setStateFromResCount];
	}
}
-(NSArray *)resArray { return _resArray; }
-(NSArray *)originalResArray { return _resArray; }
-(void)setLoadedResIndexes:(NSIndexSet *)indexSet { setObjectWithRetainSynchronized(_loadedResIndexes,indexSet); }
-(NSIndexSet *)loadedResIndexes { return _loadedResIndexes; }

-(void)setDraft:(NSString *)aString { setObjectWithRetainSynchronized(_draft, aString); }
-(NSString *)draft { return _draft; }

-(void)setWebConnector:(T2WebConnector *)webConnector {
	@synchronized(self) {
		if (_connector) {
			[_connector cancelLoading];
			[_connector release];
			_connector = nil;
		}
		if (webConnector) {
			_connector = [webConnector retain];
		}
	}
}
-(T2WebConnector *)webConnector {
	return _connector;
}

#pragma mark -
#pragma mark Optional Accessors

-(NSArray *)resArrayForIndexes:(NSIndexSet *)indexSet {
	return [_resArray objectsAtIndexes_panther:indexSet];
}

-(void)setShouldSavePList:(BOOL)aBool { [super setShouldSaveFile:aBool]; }
-(BOOL)shouldSavePList { return [super shouldSaveFile]; }

-(void)setLoadingInterval:(NSTimeInterval)timeInterval {
	_loadingInterval = timeInterval;
}
-(NSTimeInterval)loadingInterval { return _loadingInterval; }
-(void)setLastLoadingDate:(NSDate *)date {
	setObjectWithRetainSynchronized(_lastLoadingDate, date);
}
-(NSDate *)lastLoadingDate { return _lastLoadingDate; }
-(BOOL)loadableInterval {
	if (_loadingInterval <= 0 || !_lastLoadingDate)
		return YES;
	else {
		NSTimeInterval temp = [_lastLoadingDate timeIntervalSinceNow];
		if (-1*temp >= _loadingInterval) return YES;
	}
	return NO;
}

-(void)setNewResIndex:(unsigned)index { _newResIndex = index; }
-(unsigned)newResIndex { return _newResIndex; }

-(void)setWebBrowserURLString:(NSString *)urlString {
	setObjectWithRetainSynchronized(_webBrowserURLString, urlString);
}
-(NSString *)webBrowserURLString { return _webBrowserURLString; }

-(void)setShouldUseSharedCookies:(BOOL)aBool { _shouldUseSharedCookies = aBool; }
-(BOOL)shouldUseSharedCookies { return _shouldUseSharedCookies; }

#pragma mark -
#pragma mark Getting Posting
-(T2Posting *)postingWithRes:(T2Res *)res {
	if (!_internalPath) return nil;
	T2PluginManager *pluginManager = [T2PluginManager sharedManager];
	id <T2Posting_v200> plugin = [pluginManager postingPluginForInternalPath:_internalPath];
	if (plugin) {
		T2Posting *posting = [plugin postingToThread:self res:res];
		return posting;
	} else {
		id <T2ResPosting_v100> plugin2 = [pluginManager resPostingPluginForInternalPath:_internalPath];
		if (plugin2) {
			return [[[T2Posting alloc] initWithThread:self res:res] autorelease];
		}
			
	}
	return nil;
}

#pragma mark -
#pragma mark Dictionary for ID and Trip
-(void)setIdDictionary:(NSDictionary *)dictionary {
	if (!_idDictionary) _idDictionary = [[NSMutableDictionary alloc] init];
	[_idDictionary setDictionary:dictionary];
}
-(NSDictionary *)idDictionary { return _idDictionary; }


-(void)setTripDictionary:(NSDictionary *)dictionary {
	if (!_tripDictionary) _tripDictionary = [[NSMutableDictionary alloc] init];
	[_tripDictionary setDictionary:dictionary];
}
-(NSDictionary *)tripDictionary { return _tripDictionary; }

#pragma mark -
#pragma mark Delegate
//-(void)setDelegate:(id)object { _delegate = object; }
//-(id)delegate { return _delegate; }
-(void)notifyLoadedResIndexes:(NSIndexSet *)resIndexes location:(unsigned)location {
	[self setLoadedResIndexes:resIndexes];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:T2ThreadDidLoadResIndexesNotification
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:resIndexes
																						   forKey:T2ThreadResIndexes]];
	/*
	if (!_delegate) return;
	if ([_delegate respondsToSelector:@selector(thread:didLoadResIndexes:location:)]) {
		[_delegate thread:self didLoadResIndexes:resIndexes location:location];
	}
	 */
}
-(void)notifyUpdatedStyleOfResIndexes:(NSIndexSet *)resIndexes {
	[self setStyleUpdatedResIndexes:resIndexes];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:T2ThreadDidUpdateStyleOfResIndexesNotification
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:resIndexes
																						   forKey:T2ThreadResIndexes]];
	/*
	if (!_delegate) return;
	if ([_delegate respondsToSelector:@selector(thread:didUpdateStyleOfResIndexes:)]) {
		[_delegate thread:self didUpdateStyleOfResIndexes:resIndexes];
	}
	 */
}

#pragma mark -
#pragma mark Trace reply

-(NSIndexSet *)forwardResIndexesFromResIndexes:(NSIndexSet *)indexSet {
	unsigned resCount = [_resArray count];
	unsigned index = [indexSet firstIndex];
	NSMutableIndexSet *resultIndexSet = [NSMutableIndexSet indexSet];
	while (index != NSNotFound) {
		if (index < resCount) {
			NSIndexSet *nextResIndexSet = [(T2Res *)[_resArray objectAtIndex:index] forwardResIndexes];
			if (nextResIndexSet) {
				[resultIndexSet addIndexes:nextResIndexSet];
			}
		}
		index = [indexSet indexGreaterThanIndex:index];
	}
	if ([resultIndexSet count] > 0) {
		return resultIndexSet;
	}
	return nil;
}
-(NSIndexSet *)backwardResIndexesFromResIndexes:(NSIndexSet *)indexSet {
	unsigned resCount = [_resArray count];
	unsigned index = [indexSet firstIndex];
	NSMutableIndexSet *resultIndexSet = [NSMutableIndexSet indexSet];
	while (index != NSNotFound) {
		if (index < resCount) {
			NSIndexSet *nextResIndexSet = [(T2Res *)[_resArray objectAtIndex:index] backwardResIndexes];
			if (nextResIndexSet) {
				[resultIndexSet addIndexes:nextResIndexSet];
			}
		}
		index = [indexSet indexGreaterThanIndex:index];
	}
	if ([resultIndexSet count] > 0) {
		return resultIndexSet;
	}
	return nil;
}
-(NSIndexSet *)traceResIndexes:(NSIndexSet *)indexSet depth:(unsigned)depth {
	NSMutableIndexSet *resulttIndexSet = [[indexSet mutableCopy] autorelease];
	NSIndexSet *nextIndexSet = indexSet;
	unsigned i;
	for (i=0; i<depth; i++) {
		nextIndexSet = [self forwardResIndexesFromResIndexes:nextIndexSet];
		if ([nextIndexSet count] > 0) {
			[resulttIndexSet addIndexes:nextIndexSet];
		} else {
			break;
		}
	}
	return resulttIndexSet;
}
-(NSIndexSet *)backtraceResIndexes:(NSIndexSet *)indexSet depth:(unsigned)depth {
	NSMutableIndexSet *resulttIndexSet = [[indexSet mutableCopy] autorelease];
	NSIndexSet *nextIndexSet = indexSet;
	unsigned i;
	for (i=0; i<depth; i++) {
		nextIndexSet = [self backwardResIndexesFromResIndexes:nextIndexSet];
		if ([nextIndexSet count] > 0) {
			[resulttIndexSet addIndexes:nextIndexSet];
		} else {
			break;
		}
	}
	return resulttIndexSet;
}

#pragma mark -
#pragma mark Res Extracting and sub thread
-(T2Thread *)subThreadWithExtractPath:(NSString *)extractPath {
	return [T2SubThread subThreadWithThread:self extractPath:extractPath];
}
-(NSIndexSet *)resIndexesWithExtractPath:(NSString *)extractPath {
	NSArray *pathComponents = [extractPath pathComponents];
	unsigned pathComponentsCount = [pathComponents count];
	if (pathComponentsCount < 1) return nil;
	NSString *extractKey = [pathComponents objectAtIndex:0];
	NSString *subExtractPath;
	if ([extractKey isEqualToString:@"internal:"]) {
		extractKey = [pathComponents objectAtIndex:1];
		subExtractPath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(2,pathComponentsCount-2)]];
	} else {
		extractKey = [pathComponents objectAtIndex:0];
		subExtractPath = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(1,pathComponentsCount-1)]];
	}
	
	T2PluginManager *manager = [T2PluginManager sharedManager];
	NSIndexSet *resIndexSet = [[manager resExtractorForKey:extractKey] extractResIndexesInThread:self
																								   forKey:extractKey
																									 path:subExtractPath];
	return resIndexSet;
}

-(BOOL)newResIndexIsIn2ndToLast {
	if (_newResIndex > 0 && _newResIndex < [_resArray count]) return YES;
	else return NO;
}

#pragma mark -
#pragma mark  Styles

-(void)setPathStyleDictionary:(NSDictionary *)dic {
	if (!_pathStyleDictionary) _pathStyleDictionary = [[NSMutableDictionary alloc] init];
	[_pathStyleDictionary setDictionary:dic];
}
-(NSDictionary *)pathStyleDictionary { return [[_pathStyleDictionary copy] autorelease]; }
-(void)setIndexesStyleDictionary:(NSDictionary *)dic {
	if (!_indexesStyleDictionary) _indexesStyleDictionary = [[NSMutableDictionary alloc] init];
	[_indexesStyleDictionary setDictionary:dic];
}
-(NSDictionary *)indexesStyleDictionary { return [[_indexesStyleDictionary copy] autorelease]; }

-(void)setStyleUpdatedResIndexes:(NSIndexSet *)indexSet { setObjectWithRetain(_styleUpdatedresIndexes,indexSet); }
-(NSIndexSet *)styleUpdatedResIndexes { return _styleUpdatedresIndexes; }

-(BOOL)hasStyles {
	if ([_indexesStyleDictionary count] + [_pathStyleDictionary count] > 0) return YES;
	return NO;
}

#pragma mark -

-(void)addStyle:(NSString *)style ofResWithExtractPath:(NSString *)extractPath {
	
	if (!_indexesStyleDictionary) _indexesStyleDictionary = [[NSMutableDictionary alloc] init];
	if (!_pathStyleDictionary) _pathStyleDictionary = [[NSMutableDictionary alloc] init];
	
	NSArray *pathComponents = [extractPath pathComponents];
	unsigned pathComponentsCount = [pathComponents count];
	NSString *key = [pathComponents objectAtIndex:0];
	if ([key isEqualToString:@"internal:"] && pathComponentsCount>1) {
		key = [pathComponents objectAtIndex:1];
	}
	
	NSIndexSet *resIndexes = [self resIndexesWithExtractPath:extractPath];
	if ([key isEqualToString:@"resNumber"]) { // depends on standard plug!
		NSIndexSet *styledIndexes = [_indexesStyleDictionary objectForKey:style];
		if (styledIndexes) {
			NSMutableIndexSet *newIndexes = [[styledIndexes mutableCopy] autorelease];
			[newIndexes addIndexes:resIndexes];
			resIndexes = [[newIndexes copy] autorelease];
		}
		[_indexesStyleDictionary setObject:resIndexes forKey:style];
		
	} else {
		NSArray *styles = [_pathStyleDictionary objectForKey:extractPath];
		if (styles && ![styles containsObject:style]) {
			NSArray *newStyles = [styles arrayByAddingObject:style];
			[_pathStyleDictionary setObject:newStyles forKey:extractPath];
			
		} else if (!styles) {
			NSArray *newStyles = [NSArray arrayWithObject:style];
			[_pathStyleDictionary setObject:newStyles forKey:extractPath];
			
		}
	}
	[self addInternalStyle:style ofResWithIndexes:resIndexes];
	[self notifyUpdatedStyleOfResIndexes:resIndexes];
}

-(void)addInternalStyle:(NSString *)style ofResWithExtractPath:(NSString *)extractPath {
	NSIndexSet *resIndexes = [self resIndexesWithExtractPath:extractPath];
	[self addInternalStyle:style ofResWithIndexes:resIndexes];
}

-(void)addInternalStyle:(NSString *)style ofResWithIndexes:(NSIndexSet *)indexes {
	if (!indexes) return;
	unsigned resIndex = [indexes firstIndex];
	while (resIndex != NSNotFound) {
		[(T2Res *)[_resArray objectAtIndex:resIndex] addHTMLClass:style];
		resIndex = [indexes indexGreaterThanIndex:resIndex];
	}
}
-(void)removeStylesOfResWithExtractPath:(NSString *)extractPath {
	
	if (!_indexesStyleDictionary) _indexesStyleDictionary = [[NSMutableDictionary alloc] init];
	if (!_pathStyleDictionary) _pathStyleDictionary = [[NSMutableDictionary alloc] init];
	
	NSArray *pathComponents = [extractPath pathComponents];
	unsigned pathComponentsCount = [pathComponents count];
	NSString *key = [pathComponents objectAtIndex:0];
	if ([key isEqualToString:@"internal:"] && pathComponentsCount>1) {
		key = [pathComponents objectAtIndex:1];
	}
	
	NSIndexSet *resIndexes = [self resIndexesWithExtractPath:extractPath];
	if ([key isEqualToString:@"resNumber"]) { // depends on standard plug!
		NSEnumerator *oldStyleEnumerator = [_indexesStyleDictionary keyEnumerator];
		NSString *oldStyle;
		while (oldStyle = [oldStyleEnumerator nextObject]) {
			NSIndexSet *styledIndexes = [_indexesStyleDictionary objectForKey:oldStyle];
			if ([styledIndexes containsIndexes:resIndexes]) {
				NSMutableIndexSet *newIndexes = [[styledIndexes mutableCopy] autorelease];
				[newIndexes removeIndexes:resIndexes];
				if (newIndexes && [newIndexes count]>0)
					[_indexesStyleDictionary setObject:[[newIndexes copy] autorelease] forKey:oldStyle];
				else
					[_indexesStyleDictionary removeObjectForKey:oldStyle];
			}
		}
		
	} else {
		NSArray *styles = [_pathStyleDictionary objectForKey:extractPath];
		if (styles) {
			[_pathStyleDictionary removeObjectForKey:extractPath];
			
		}
	}
	[self removeInternalStylesOfResWithIndexes:resIndexes];
	[self notifyUpdatedStyleOfResIndexes:resIndexes];
	
}
-(void)removeInternalStylesOfResWithExtractPath:(NSString *)extractPath {
	NSIndexSet *resIndexes = [self resIndexesWithExtractPath:extractPath];
	[self removeInternalStylesOfResWithIndexes:resIndexes];
}
-(void)removeInternalStylesOfResWithIndexes:(NSIndexSet *)indexes {
	if (!indexes) return;
	unsigned resIndex = [indexes firstIndex];
	while (resIndex != NSNotFound) {
		[(T2Res *)[_resArray objectAtIndex:resIndex] setHTMLClasses:nil];
		resIndex = [indexes indexGreaterThanIndex:resIndex];
	}
	
}
-(void)removeAllStyles {
	NSMutableIndexSet *removedIndexes = [NSMutableIndexSet indexSet];
	NSEnumerator *indexesEnumerator = [[_indexesStyleDictionary allValues] objectEnumerator];
	NSIndexSet *indexes;
	while (indexes = [indexesEnumerator nextObject]) {
		[removedIndexes addIndexes:indexes];
	}
	[_indexesStyleDictionary release];
	_indexesStyleDictionary = nil;
	
	NSEnumerator *pathEnumerator = [_pathStyleDictionary keyEnumerator];
	NSString *path;
	while (path = [pathEnumerator nextObject]) {
		[removedIndexes addIndexes:[self resIndexesWithExtractPath:path]];
	}
	[_pathStyleDictionary release];
	_pathStyleDictionary = nil;
	
	if ([removedIndexes count] == 0) return;
	if (_resArray)
		[self removeInternalStylesOfResWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[_resArray count])]];
	[self notifyUpdatedStyleOfResIndexes:removedIndexes];
}

-(void)applyAllStyles {
	NSString *style;
	if (_pathStyleDictionary) {
		NSEnumerator *pathsEnumerator = [_pathStyleDictionary keyEnumerator];
		NSString *path;
		while (path = [pathsEnumerator nextObject]) {
			NSArray *styles = [_pathStyleDictionary objectForKey:path];
			NSEnumerator *stylesEnumerator = [styles objectEnumerator];
			while (style = [stylesEnumerator nextObject]) {
				[self addInternalStyle:style ofResWithExtractPath:path];
			}
		}
	}
	if (_indexesStyleDictionary) {
		NSEnumerator *stylesEnumerator = [_indexesStyleDictionary keyEnumerator];
		while (style = [stylesEnumerator nextObject]) {
			NSIndexSet *indexes = [_indexesStyleDictionary objectForKey:style];
			if (indexes) [self addInternalStyle:style ofResWithIndexes:indexes];
		}
	}
}


#pragma mark -
#pragma mark Web representation
-(NSString *)HTMLForResWithExtractPath:(NSString *)extractPath baseURL:(NSURL **)baseURL
							  forPopUp:(BOOL)forPopUp {
	NSIndexSet *indexes = [self resIndexesWithExtractPath:extractPath];
	return [self HTMLForResIndexes:indexes
						   baseURL:baseURL
						  forPopUp:forPopUp];
}
-(NSString *)HTMLForAllResAndbaseURL:(NSURL **)baseURL forPopUp:(BOOL)forPopUp {
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[_resArray count])];
	return [self HTMLForResIndexes:indexes
						   baseURL:baseURL
						  forPopUp:forPopUp];
}
-(NSString *)HTMLForResInRange:(NSRange)range andFirstRes:(BOOL)firstRes
					   baseURL:(NSURL **)baseURL forPopUp:(BOOL)forPopUp {
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:range];
	if (firstRes) [indexes addIndex:0];
	return [self HTMLForResIndexes:indexes
						   baseURL:baseURL
						  forPopUp:forPopUp];
		
}

-(NSString *)HTMLForResIndexes:(NSIndexSet *)resIndexes baseURL:(NSURL **)baseURL forPopUp:(BOOL)forPopUp {
	if (!_resArray || !resIndexes) return nil;
	unsigned i = [resIndexes firstIndex];
	unsigned maxResNumber = [_resArray count];
	
	NSMutableString *resultHTML = [[[NSMutableString alloc] init] autorelease];
	NSURL *tempBaseURL = nil;
	T2PluginManager *sharedManager = [T2PluginManager sharedManager];
	id <T2ThreadPartialHTMLExporting_v100> partialViewPlug = [sharedManager partialHTMLExporterPlugin];
	
	NSString *resStringFormat;
	NSString *newResStringFormat;
	unsigned j=0 ,maxResCount;
	if (!forPopUp) {
		[resultHTML appendString:[partialViewPlug headerHTMLWithThread:self baseURL:&tempBaseURL]];
		resStringFormat = @"<div class=\"%@\" id=\"res%d\">%@</div>";
		newResStringFormat = @"<div class=\"new %@\" id=\"res%d\">%@</div>";
		maxResCount = __maxDisplayResCount;
	}
	else {
		[resultHTML appendString:[partialViewPlug popUpHeaderHTMLWithThread:self baseURL:&tempBaseURL]];
		resStringFormat = @"<div class=\"popUp %@\" id=\"res%d\">%@</div>";
		newResStringFormat = @"<div class=\"popUp new %@\" id=\"res%d\">%@</div>";
		maxResCount = __maxPopUpResCount;
	}
	if (maxResCount > maxResNumber) maxResCount = maxResNumber;
	
	while (i != NSNotFound && i<maxResNumber && j<maxResCount) {
		if ((resStringFormat != newResStringFormat) && i>=_newResIndex) {
			resStringFormat = newResStringFormat;
			[resultHTML appendString:@"<div id=\"new\"></div>"];
		}
		T2Res *res = [_resArray objectAtIndex:i];
		NSString *processedResHTML = [sharedManager processedHTML:[partialViewPlug resHTMLWithRes:res]
															ofRes:res
														 inThread:self];
		[resultHTML appendString:[NSString stringWithFormat:
			resStringFormat,
			[res HTMLClassesString],
			[res resNumber],
			processedResHTML]];
		i = [resIndexes indexGreaterThanIndex:i];
		j++;
	}
	
	if (forPopUp)
		[resultHTML appendString:[partialViewPlug popUpFooterHTMLWithThread:self]];
	else {
		[resultHTML appendString:@"<div id=\"last\"></div>"];
		[resultHTML appendString:[partialViewPlug footerHTMLWithThread:self]];
	}
	
	baseURL = &tempBaseURL;
	return resultHTML;
}

-(NSString *)excerptHTMLForResIndexes:(NSIndexSet *)resIndexes {
	if (!_resArray || !resIndexes) return nil;
	unsigned i = [resIndexes firstIndex];
	
	NSMutableString *resultHTML = [[[NSMutableString alloc] init] autorelease];
	T2PluginManager *sharedManager = [T2PluginManager sharedManager];
	id <T2ThreadPartialHTMLExporting_v100> partialViewPlug = [sharedManager partialHTMLExporterPlugin];
	
	NSString *resStringFormat;
	unsigned j=0 ,maxResCount;
	
	resStringFormat = @"<div class=\"inline %@\">%@</div>";
	maxResCount = __maxDisplayResCount;
	if (maxResCount > [_resArray count]) maxResCount = [_resArray count];
	
	while (i != NSNotFound && j<maxResCount) {
		
		T2Res *res = [_resArray objectAtIndex:i];
		NSString *processedResHTML = [sharedManager processedHTML:[partialViewPlug resHTMLWithRes:res]
															ofRes:res
														 inThread:self];
		[resultHTML appendString:[NSString stringWithFormat:
			resStringFormat,
			[res HTMLClassesString],
			processedResHTML]];
		i = [resIndexes indexGreaterThanIndex:i];
		j++;
	}
	
	return resultHTML;
}

-(NSString *)HTMLWithOtherInsertion:(NSString *)htmlString baseURL:(NSURL **)baseURL
						   forPopUp:(BOOL)forPopUp {
	NSMutableString *resultHTML = [[[NSMutableString alloc] init] autorelease];
	NSURL *tempBaseURL = nil;
	T2PluginManager *sharedManager = [T2PluginManager sharedManager];
	id <T2ThreadPartialHTMLExporting_v100> partialViewPlug = [sharedManager partialHTMLExporterPlugin];
	
	if (!forPopUp) 
		[resultHTML appendString:[partialViewPlug headerHTMLWithThread:self baseURL:&tempBaseURL]];
	else
		[resultHTML appendString:[partialViewPlug popUpHeaderHTMLWithThread:self baseURL:&tempBaseURL]];
	
	if (htmlString) {
		if (forPopUp)
			[resultHTML appendFormat:@"<div class=\"popUp preview\">%@</div>", htmlString];
		else
			[resultHTML appendFormat:@"<div>%@</div>", htmlString];
	}
	
	if (forPopUp)
		[resultHTML appendString:[partialViewPlug popUpFooterHTMLWithThread:self]];
	else
		[resultHTML appendString:[partialViewPlug footerHTMLWithThread:self]];
	
	*baseURL = tempBaseURL;
	return resultHTML;
}

-(NSString *)CSSPathsLinkString {
	return [[T2ResourceManager sharedManager] CSSPathsLinkString];
}

#pragma mark -
#pragma mark ThreadFace Methods
-(void)setTitle:(NSString *)aString {
	[_threadFace setTitle:aString];
}
-(NSString *)title { return [_threadFace title]; }
-(NSString *)escapedTitle { return [[_threadFace title] stringByAddingHTMLEscapes]; }
//-(NSString *)replacedTitle { return [_threadFace replacedTitle]; }

-(int)resCount { return [_resArray count]; }
-(int)resCountNew { return [_threadFace resCountNew]; }

-(T2ListFace *)threadListFace {
	NSString *listFaceInternalPath = [_internalPath stringByDeletingLastPathComponent];
	if (listFaceInternalPath) {
		return [T2ListFace listFaceWithInternalPath:listFaceInternalPath
															  title:nil
															  image:nil];
	}
	return nil;
}
-(NSString *)threadListTitle {
	NSString *listFaceInternalPath = [_internalPath stringByDeletingLastPathComponent];
	if (listFaceInternalPath) {
		T2ListFace *listFace = [T2ListFace listFaceWithInternalPath:listFaceInternalPath
															  title:nil
															  image:nil];
		if (listFace) return [listFace title];
	}
	return @"(Untitled)";
}

-(NSString *)resCountString {
	return [NSString stringWithFormat:@"%d", [_resArray count]];
}
-(NSString *)labelColorString {
	int label = [_threadFace label];
	NSArray *colors = [[T2LabeledCellManager sharedManager] labelColors];
	if (label == 0 || label-1 > [colors count]) {
		return @"rgb(0,0,0)";
	} else {
		NSColor *color = [colors objectAtIndex:label-1];
		return [color webDecimalRGBRepresentation];
	}
}
-(NSString *)lightLabelColorString {
	int label = [_threadFace label];
	NSArray *colors = [[T2LabeledCellManager sharedManager] lightLabelColors];
	if (label == 0 || label-1 > [colors count]) {
		return @"rgb(255,255,255)";
	} else {
		NSColor *color = [colors objectAtIndex:label-1];
		return [color webDecimalRGBRepresentation];
	}
}
-(NSString *)darkLabelColorString {
	int label = [_threadFace label];
	NSArray *colors = [[T2LabeledCellManager sharedManager] selectedLabelColors];
	if (label == 0 || label-1 > [colors count]) {
		return @"rgb(0,0,0)";
	} else {
		NSColor *color = [colors objectAtIndex:label-1];
		return [color webDecimalRGBRepresentation];
	}
}

#pragma mark -
#pragma mark Score or Other Property
/*
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	[_threadFace setValue:value forKey:key];
}
- (id)valueForUndefinedKey:(NSString *)key {
	return [_threadFace valueForKey:key];
}
*/

#pragma mark -
#pragma mark Automaticaly Saving & Loading

+(void)setExtensions:(NSArray *)extensions {
	setObjectWithRetainSynchronized(__extensions, extensions);
}
+(NSArray *)extensions {
	return __extensions;
}

-(NSString *)filePath {
	if (!_internalPath) return nil;
	return [[[[NSString appLogFolderPath] stringByAppendingPathComponent:_internalPath] stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"];
}
/*
-(void)loadFromFile {
	[super loadFromFile];
	if (!_internalPath) return;
	NSObject <T2ThreadImporting_v100> *threadImporter = [[T2PluginManager sharedManager] threadImporterForInternalPath:_internalPath];
	[threadImporter URLRequestForThread:self];
	if (_resArray && [_resArray count]>0) 
		[[T2PluginManager sharedManager] processThread:self appendingIndex:0];
}
*/

#pragma mark -
#pragma mark protocol T2AsynchronousLoading
-(void)load {
	@synchronized(self) {
		if (_isLoading
			|| !_internalPath
			|| ![self loadableInterval]
			|| _connector) return;
		
		NSObject <T2ThreadImporting_v100> *threadImporter = [[T2PluginManager sharedManager] threadImporterForInternalPath:_internalPath];
		if (threadImporter) {
			if (![threadImporter respondsToSelector:@selector(URLRequestForThread:)])
				return;
		} else	return;
		
		NSURLRequest *threadRequest = [threadImporter URLRequestForThread:self];
		
		if (threadRequest) {
			threadRequest = [threadRequest requestByAddingUserAgentAndImporterName:[threadImporter uniqueName]];
			if (!_shouldUseSharedCookies) {
				threadRequest = [threadRequest requestByAddingCookies];
			}
			
			[self setIsLoading:YES];
			[self setProgress:0];
			[self setProgressInfo:[[threadRequest URL] absoluteString]];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:T2ThreadDidStartLoadingNotification
																object:self
															  userInfo:nil];
			
			T2WebConnector *webConnector = [T2WebConnector connectorWithURLRequest:threadRequest delegate:self inContext:_internalPath shouldUseSharedCookies:_shouldUseSharedCookies];
			[self setWebConnector:webConnector];
		}
	}
}
/*
-(void)unload {
	if (!_isActive) return;
	
	[self cancelLoading];
	if (_shouldSavePList) [self savePlist];
	[self setIsActive:NO];
}
*/
-(void)cancelLoading {
	@synchronized(self) {
		if (_connector) {
			[[NSNotificationCenter defaultCenter] postNotificationName:T2ThreadDidLoadResIndexesNotification
																object:self
															  userInfo:nil];
			[self setWebConnector:nil];
			[self setIsLoading:NO];
		}
		[self setProgress:0];
		[self setProgressInfo:nil];
	}
}

-(void)setIsLoading:(BOOL)aBool { _isLoading = aBool; }
-(BOOL)isLoading { return _isLoading; }
/*
-(void)setIsActive:(BOOL)aBool { _isActive = aBool; }
-(BOOL)isActive { return _isActive; }
*/

-(void)setProgress:(float)aFloat { _progress = aFloat; }
-(float)progress { return _progress; }
-(void)setProgressInfo:(NSString *)aString { setObjectWithRetainSynchronized(_progressInfo, aString); }
-(NSString *)progressInfo { return _progressInfo; }

#pragma mark -
-(void)processAfterResIndex:(unsigned)resIndex {
	[[T2PluginManager sharedManager] processThread:self appendingIndex:resIndex];
}

#pragma mark -
#pragma mark T2WebConnector delegate
-(void)connector:(T2WebConnector *)connector
		   ofURL:(NSString *)urlString
		progress:(float)progress
	   inContext:(id)contextObject {
	[self setProgress:progress];
	[[NSNotificationCenter defaultCenter] postNotificationName:T2ThreadDidProgressLoadingNotification
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:progress]
																						   forKey:@"progress"]];
}

-(void)connector:(T2WebConnector *)connector
		   ofURL:(NSString *)urlString
 didReceiveError:(NSError *)error
	   inContext:(id)contextObject {
	
	[self setProgress:0];
	[self setProgressInfo:[error localizedDescription]];
	[self setIsLoading:NO];
	[self setWebConnector:nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:T2ThreadDidLoadResIndexesNotification
														object:self
													  userInfo:nil];
}

-(void)connector:(T2WebConnector *)connector
		   ofURL:(NSString *)urlString
didReceiveWebData:(T2WebData *)webData
	   inContext:(id)contextObject {
	
	NSString *internalPath = [self internalPath];
	if (webData && internalPath) {
		
		unsigned oldResCount = [_resArray count] ,appendingIndex = 0, newResCount ;
		NSObject <T2ThreadImporting_v100> *threadImporter = [[T2PluginManager sharedManager] threadImporterForInternalPath:internalPath];
		if (![threadImporter respondsToSelector:@selector(buildThread:withWebData:)]) return;
		
		T2LoadingResult loadingresult = [threadImporter buildThread:self withWebData:webData];
		if (loadingresult == T2RetryLoading) {
			if (_retryCount > 2) {
				// Loading Failed
				[self setLastLoadingDate:nil];
			} else {
				// Retry Loading
				_retryCount++;
				[self setLastLoadingDate:nil];
				[self setProgress:1];
				[self setProgressInfo:[connector status]];
				[self setIsLoading:NO];
				[_connector release];
				_connector = nil;
				[self load];
				return;
			}
		} else if (loadingresult == T2LoadingSucceed) {
			// Succeed
			if (_loadingInterval > 0) [self setLastLoadingDate:[NSDate date]];
		} 
		
		newResCount = [_resArray count];
		if (newResCount > oldResCount) {
			appendingIndex = oldResCount;
		}
		[[T2PluginManager sharedManager] processThread:self appendingIndex:appendingIndex];
		
		[self applyAllStyles];
		
		[self notifyLoadedResIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(appendingIndex, newResCount)] location:appendingIndex];
	
		if (loadingresult == T2LoadingSucceed) {
			[self saveToFile];
		}
	}
	[self setProgress:1];
	[self setProgressInfo:[connector status]];
	[self setIsLoading:NO];
	[self setWebConnector:nil];
}
@end
