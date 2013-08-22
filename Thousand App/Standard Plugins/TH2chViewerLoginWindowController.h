//
//  TH2chViewerLoginWindowController.h
//  Thousand
//
//  Created by R. Natori on 08/12/08.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Thousand2ch/Thousand2ch.h>

@interface NSObject (TH2chViewerLoginWindowControllerDelegate)
-(void)loginSheetDidEndWithAccountName:(NSString *)accountName sessionID:(NSString *)sessionID sessionUA:(NSString *)sessionUA saveInKeychain:(BOOL)saveInKeychain;
-(void)p2loginSheetDidEndWithAccountName:(NSString *)accountName succeed:(BOOL)succeed alreadyLoggedIn:(BOOL)alreadyLoggedIn saveInKeychain:(BOOL)saveInKeychain;
@end

@interface TH2chViewerLoginWindowController : NSWindowController {
	NSWindow *_docWindow;
	NSObject *_delegate;
	
	BOOL 	_isP2;
	BOOL	_P2Succeed;
	BOOL	_P2AlreadyLoggedIn;
	T2WebForm *_p2WebForm;
	
	NSString *_accountName;
	NSString *_password;
	NSString *_viewerSUA;
	NSString *_viewerSID;
	BOOL _saveInKeychain;
	BOOL _autoLogin;
	
	T2WebConnector *_webConnector;
	
	IBOutlet NSTextField *_titleField;
	IBOutlet NSTextField *_accountNameField;
	IBOutlet NSSecureTextField *_passwordField;
	IBOutlet NSButton *_saveInKeychainButton;
	IBOutlet NSTextField *_statusField;
	IBOutlet NSTextField *_sslField;
	IBOutlet NSProgressIndicator *_progressIndicator;
	IBOutlet NSTabView *_tabView;
}
+(id)beginLoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			 defaultPassword:(NSString *)defaultPassword
	   defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
				   autoLogin:(BOOL)autoLogin
					delegate:(NSObject *)delegate;

-(id)initLoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			defaultPassword:(NSString *)defaultPassword
	  defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
				  autoLogin:(BOOL)autoLogin
				   delegate:(NSObject *)delegate;

+(id)beginP2LoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			 defaultPassword:(NSString *)defaultPassword
		 defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
					 autoLogin:(BOOL)autoLogin
					  delegate:(NSObject *)delegate;

-(id)initP2LoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			defaultPassword:(NSString *)defaultPassword
	  defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
					autoLogin:(BOOL)autoLogin
					 delegate:(NSObject *)delegate;

-(void)beginSheet ;
-(void)p2challenge ;
-(IBAction)login:(id)sender ;
-(IBAction)cancel:(id)sender ;
@end
