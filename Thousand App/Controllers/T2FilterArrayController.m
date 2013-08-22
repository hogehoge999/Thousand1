//
//  T2FilterArrayController.m
//  Thousand
//
//  Created by R. Natori on 05/12/11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "T2FilterArrayController.h"
#import "T2ThreadFace.h"


@implementation T2FilterArrayController

-(void)setSearchString:(NSString *)searchString {
	[searchString retain];
	[_searchString release];
	_searchString = searchString;
}
-(NSString *)searchString { return _searchString; }

- (NSArray *)arrangeObjects:(NSArray *)objects {
	if (!_searchString || [_searchString isEqualToString:@""]) return [super arrangeObjects:objects];
	NSString *searchString = [[_searchString copy] autorelease];
	NSMutableArray *resultArray = [NSMutableArray array];
	NSEnumerator *enumerator = [objects objectEnumerator];
	T2ThreadFace *object;
	while (object = [enumerator nextObject]) {
		if ([[object title] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)
			[resultArray addObject:object];
	}
	return [super arrangeObjects:resultArray];
}
@end
