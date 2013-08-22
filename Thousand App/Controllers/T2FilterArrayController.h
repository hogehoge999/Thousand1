//
//  T2FilterArrayController.h
//  Thousand
//
//  Created by R. Natori on 05/12/11.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface T2FilterArrayController : NSArrayController {
	NSString *_searchString;
}
-(void)setSearchString:(NSString *)searchString ;
-(NSString *)searchString ;
@end
