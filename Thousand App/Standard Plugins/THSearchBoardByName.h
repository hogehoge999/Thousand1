//
//  THSearchBoardByName.h
//  Thousand
//
//  Created by R. Natori on 08/11/01.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface THSearchBoardByName : NSObject <T2SearchListImporting_v100> {
	
	NSBundle *_selfBundle;
	NSImage *_rootImage;
	
	NSString *_searchString;
}
#pragma mark -
#pragma mark T2PluginInterface_v100
+(NSArray *)pluginInstances ;
-(NSString *)uniqueName ;
-(NSString *)localizedName ;
-(NSString *)localizedPluginInfo ;
-(T2PluginType)pluginType ;
-(int)pluginOrder ;

#pragma mark -
#pragma mark T2ListImporting_v100
-(NSString *)importableRootPath ;
-(T2List *)listForListFace:(T2ListFace *)listFace ;

-(NSArray *)rootListFaces ;
-(NSImage *)imageForListFace:(T2ListFace *)listFace ;

#pragma mark -
#pragma mark T2SearchListImporting_v100
-(void)setSearchString:(NSString *)searchString ;
-(NSString *)searchString ;
-(T2ListFace *)persistentListFaceForSearchString:(NSString *)searchString ;
-(BOOL)receivesWholeSearchString ;
@end
