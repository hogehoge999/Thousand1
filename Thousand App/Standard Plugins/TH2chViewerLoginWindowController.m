//
//  TH2chViewerLoginWindowController.m
//  Thousand
//
//  Created by R. Natori on 08/12/08.
//  Copyright 2008 R. Natori. All rights reserved.
//

#import "TH2chViewerLoginWindowController.h"
#import "TH2chImporterPlug.h"

#define plugLocalizedString(aString) ([[NSBundle bundleForClass:[self class]] localizedStringForKey:aString value:aString table:@"StandardPlugLocalizable"])

static NSMutableSet *__instances = nil;
static NSString *__2chViewerCGIURLString = @"https://2chv.tora3.net/futen.cgi";
static NSString *__2chViewerServiceName = @"2ch Viewer";
static NSString *__p2URLString = @"http://p2.2ch.net/p2/";
static NSString *__p2ServiceName = @"p2.2ch.net";

@implementation TH2chViewerLoginWindowController

+(id)beginLoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			 defaultPassword:(NSString *)defaultPassword
	   defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
				   autoLogin:(BOOL)autoLogin
					delegate:(NSObject *)delegate {
	TH2chViewerLoginWindowController *loginWindowController = [[[self alloc] initLoginSheetOnWindow:docWindow
																				 defaultAccountName:defaultAccountName 
																					defaultPassword:defaultPassword
																			  defaultSaveInKeychain:defaultSaveInKeychain
																						  autoLogin:autoLogin
																						   delegate:delegate] autorelease];
	
	[loginWindowController beginSheet];
	return loginWindowController;
}
-(id)initLoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			defaultPassword:(NSString *)defaultPassword
	  defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
				  autoLogin:(BOOL)autoLogin
				   delegate:(NSObject *)delegate {
	self = [super initWithWindowNibName:@"TH2chViewerLoginWindow"];
	_docWindow = docWindow;
	_delegate = delegate;
	_accountName = [defaultAccountName copy];
	_password = [defaultPassword copy];
	_saveInKeychain = defaultSaveInKeychain;
	_autoLogin = autoLogin;
	return self;
}

+(id)beginP2LoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			   defaultPassword:(NSString *)defaultPassword
		 defaultSaveInKeychain:(BOOL)defaultSaveInKeychain
					 autoLogin:(BOOL)autoLogin
					  delegate:(NSObject *)delegate {
	TH2chViewerLoginWindowController *loginWindowController = [[[self alloc] initP2LoginSheetOnWindow:docWindow
																				   defaultAccountName:defaultAccountName 
																					  defaultPassword:defaultPassword
																				defaultSaveInKeychain:defaultSaveInKeychain
																							autoLogin:autoLogin
																							 delegate:delegate] autorelease];
	[loginWindowController beginSheet];
	return loginWindowController;
}
-(id)initP2LoginSheetOnWindow:(NSWindow *)docWindow defaultAccountName:(NSString *)defaultAccountName 
			  defaultPassword:(NSString *)defaultPassword
		defaultSaveInKeychain:(BOOL)defaultSaveInKeychain 
					autoLogin:(BOOL)autoLogin
					 delegate:(NSObject *)delegate {
	self = [self initLoginSheetOnWindow:docWindow defaultAccountName:defaultAccountName
						defaultPassword:defaultPassword
				  defaultSaveInKeychain:defaultSaveInKeychain
							  autoLogin:autoLogin
							   delegate:delegate];
	_isP2 = YES;
	_P2AlreadyLoggedIn = YES;
	return self;
}

- (void)windowDidLoad {
	if (_isP2) {
		[_titleField setStringValue:plugLocalizedString(@"p2.2ch.net")];
		[_sslField setHidden:YES];
	}
	else {
		[_titleField setStringValue:plugLocalizedString(@"2ch Viewer")];
	}
	
	if (_accountName && !_password && _saveInKeychain) {
		if (!_isP2) {
			_password = [[[T2KeychainManager sharedManager] genericPasswordForAccountName:_accountName serviceName:__2chViewerServiceName] retain];
		} else {
			_password = [[[T2KeychainManager sharedManager] genericPasswordForAccountName:_accountName serviceName:__p2ServiceName] retain];
			
		}
	}
	
	if (_accountName)
		[_accountNameField setStringValue:_accountName];
	if (_password)
		[_passwordField setStringValue:_password];
	
	if (_saveInKeychain)
		[_saveInKeychainButton setState:NSOnState];
	else
		[_saveInKeychainButton setState:NSOffState];
	
	[_tabView selectFirstTabViewItem:nil];
	
	if (_isP2) {
		[self p2challenge];
	} else if (_autoLogin) {
		[self login:nil];
		_autoLogin = NO;
	}
}

-(void)setViewerSID:(NSString *)aString {
	setObjectWithRetain(_viewerSID, aString);
	if (_viewerSID) {
		[_statusField setStringValue:plugLocalizedString(@"Log-in.")];
		
		unsigned location = [_viewerSID rangeOfString:@":" options:NSLiteralSearch].location;
		if (location != NSNotFound) {
			NSString *viewerSUA = [_viewerSID substringToIndex:location];
			
			NSBundle *appBundle = [NSBundle mainBundle];
			NSString *appName = [[appBundle executablePath] lastPathComponent];
			//NSString *appVersion = [appBundle objectForInfoDictionaryKey:@"CFBundleVersion"] ;
			
			viewerSUA = [viewerSUA stringByAppendingFormat:@" (%@/1.00)", appName];
			//NSLog(@"%@", viewerSUA);
			setObjectWithRetain(_viewerSUA, viewerSUA);
			return;
		}
	}
	setObjectWithRetain(_viewerSUA, @"");
}


-(void)dealloc {
	if (_webConnector) {
		[_webConnector cancelLoading];
		[_webConnector release];
		_webConnector = nil;
	}
	
	[_p2WebForm release];
	[_accountName release];
	[_password release];
	[_viewerSUA release];
	[_viewerSID release];
	[super dealloc];
}
-(void)beginSheet {
	[NSApp beginSheet:[self window]
	   modalForWindow:_docWindow
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
	if (!__instances) __instances = [[NSMutableSet alloc] init];
	[__instances addObject:self];
}
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
	if (!_isP2) {
		if ([_delegate respondsToSelector:@selector(loginSheetDidEndWithAccountName:sessionID:sessionUA:saveInKeychain:)]) {
			[_delegate loginSheetDidEndWithAccountName:_accountName sessionID:_viewerSID sessionUA:_viewerSUA saveInKeychain:_saveInKeychain];
		}
	} else {
		if ([_delegate respondsToSelector:@selector(p2loginSheetDidEndWithAccountName:succeed:alreadyLoggedIn:saveInKeychain:)]) {
			[_delegate p2loginSheetDidEndWithAccountName:_accountName succeed:_P2Succeed alreadyLoggedIn:_P2AlreadyLoggedIn saveInKeychain:_saveInKeychain];
		}
	}
	[__instances removeObject:self];
}
-(void)p2challenge {
	[_statusField setStringValue:plugLocalizedString(@"Authentication...")];
	[_tabView selectLastTabViewItem:nil];
	[_progressIndicator startAnimation:nil];
	
	NSString *P2URLString = __p2URLString;
	id the2chPlugin = [[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_Thousand_2chImporter"];
	if (the2chPlugin) {
		P2URLString = [(TH2chImporterPlug *)the2chPlugin P2URLString];
	}
	
	T2WebConnector *webConnector = [T2WebConnector connectorWithURLString:P2URLString
																 delegate:self
																inContext:nil];
	if (_webConnector) [_webConnector cancelLoading];
	setObjectWithRetain(_webConnector, webConnector);
}
-(IBAction)login:(id)sender {
	
	if (!_isP2) {
		
		NSString *_viewerID = [_accountNameField stringValue];
		NSString *_viewerPS = [_passwordField stringValue];
		_saveInKeychain = ([_saveInKeychainButton state] == NSOnState);
		
		if (!_viewerID || !_viewerPS) return;
		setObjectWithRetain(_accountName, _viewerID);
		
		if (_saveInKeychain)
			[[T2KeychainManager sharedManager] setGenericPassword:_viewerPS accountName:_viewerID serviceName:__2chViewerServiceName];
		
		NSString *x2chUA = [NSString stringWithFormat:@"%@/1.00", [NSString appName]];
		
		NSString *cgiPath = __2chViewerCGIURLString;
		NSString *bodyString = [NSString stringWithFormat:@"ID=%@&PW=%@", _viewerID, _viewerPS];
		NSData *bodyData = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
		
		// make request and header
		NSURL *cgiURL = [NSURL URLWithString:cgiPath];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:cgiURL];
		if (!request) return;
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody:bodyData];
		
		[request setValue:[NSString stringWithFormat:@"%d",[bodyData length]] forHTTPHeaderField:@"Content-length"];
		[request setValue:@"DOLIB/1.00" forHTTPHeaderField:@"User-Agent"];
		[request setValue:x2chUA forHTTPHeaderField:@"X-2ch-UA"];
		
		[_statusField setStringValue:plugLocalizedString(@"Authentication...")];
		[_tabView selectLastTabViewItem:nil];
		[_progressIndicator startAnimation:nil];
		_webConnector = [[T2WebConnector connectorWithURLRequest:request
														delegate:self
													   inContext:@"2chViewer"
										  shouldUseSharedCookies:NO] retain];
	} else {
		if (_p2WebForm) {
			_P2AlreadyLoggedIn = NO;
			NSString *_P2ID = [_accountNameField stringValue];
			NSString *_P2PS = [_passwordField stringValue];
			_saveInKeychain = ([_saveInKeychainButton state] == NSOnState);
			
			if (!_P2ID || !_P2PS) return;
			setObjectWithRetain(_accountName, _P2ID);
			
			if (_saveInKeychain)
				[[T2KeychainManager sharedManager] setGenericPassword:_P2PS accountName:_P2ID serviceName:__p2ServiceName];
			
			[_p2WebForm setFormValue:_P2ID forKey:@"form_login_id"];
			[_p2WebForm setFormValue:_P2PS forKey:@"form_login_pass"];
			[_p2WebForm setFormValue:@"1" forKey:@"regist_cookie"];
			
			NSURLRequest *urlRequest = [_p2WebForm formRequestUsingEncoding:NSShiftJISStringEncoding];
			
			[_statusField setStringValue:plugLocalizedString(@"Authentication...")];
			[_tabView selectLastTabViewItem:nil];
			[_progressIndicator startAnimation:nil];
			
			T2WebConnector *webConnector = [T2WebConnector connectorWithURLRequest:urlRequest
																		  delegate:self
																		 inContext:nil];
			setObjectWithRetain(_webConnector, webConnector);
		}
	}
}
-(IBAction)cancel:(id)sender {
	if (_webConnector) {
		[_webConnector cancelLoading];
		[_webConnector release];
		_webConnector = nil;
	}
	[_accountName release];
	[_password release];
	_accountName = [[_accountNameField stringValue] copy];
	_password = nil;
	_saveInKeychain = ([_saveInKeychainButton state] == NSOnState);
	[NSApp endSheet:[self window]];
}

-(void)connector:(T2WebConnector *)connector ofURL:(NSString *)urlString didReceiveWebData:(T2WebData *)webData
	   inContext:(id)contextObject {
	if ([urlString isEqualToString:__2chViewerCGIURLString]) {
		// 2ch Viewer Login
		
		if (webData) {
			NSString *src = [webData decodedString];
			
			if ([src rangeOfString:@"SESSION-ID=ERROR"].location == NSNotFound) {
				NSScanner *scanner = [NSScanner scannerWithString:src];
				[scanner scanString:@"SESSION-ID=" intoString:NULL];
				NSString *sessionID = nil;
				[scanner scanUpToString:@"\n" intoString:&sessionID];
				[self setViewerSID:sessionID];
				/*
				// load registered thread
				if (_threadInternalPathToLoadAfterRelogin) {
					T2Thread *thread = [T2Thread availableObjectWithInternalPath:_threadInternalPathToLoadAfterRelogin];
					if (thread) [thread load];
					
					[_threadInternalPathToLoadAfterRelogin release];
					_threadInternalPathToLoadAfterRelogin = nil;
				}
				 */
				
				[NSApp endSheet:[self window]];
			} else {
				[self setViewerSID:nil];
				[_progressIndicator stopAnimation:nil];
				[_statusField setStringValue:plugLocalizedString(@"Login Failed.")];
			}
		}
	} else {
		//P2 Login
		if (![webData contentData]) {
			[_progressIndicator stopAnimation:nil];
			[_statusField setStringValue:plugLocalizedString(@"Login Failed.")];
		}
		T2WebForm *webForm = [T2WebForm webFormWithHTMLString:[NSString stringWithData:[webData contentData]
																		 iconvEncoding:@"SHIFT-JIS"] 
												baseURLString:urlString];
		
		if (webForm) {
			setObjectWithRetain(_p2WebForm, webForm);
			
			[_progressIndicator stopAnimation:nil];
			[_tabView selectTabViewItemAtIndex:0];
			
			if (_isP2 && _autoLogin) {
				[self login:nil];
				_autoLogin = NO;
				return;
			}
			
		} else {
			NSString *redirectedURLString = [connector redirectedUrlString];
			if (redirectedURLString) {
				NSRange range = [redirectedURLString rangeOfString:@"p2.2ch.net/p2/"];
				if (range.location != NSNotFound) {
					redirectedURLString = [redirectedURLString substringToIndex:range.location + range.length];
					id the2chPlugin = [[T2PluginManager sharedManager] pluginForUniqueName:@"jp_natori_Thousand_2chImporter"];
					if (the2chPlugin) {
						[(TH2chImporterPlug *)the2chPlugin setP2URLString:redirectedURLString];
					}
				}
			}
			_P2Succeed = YES;
			[NSApp endSheet:[self window]];
		}
	}
	
	if (_webConnector) {
		[_webConnector cancelLoading];
		[_webConnector release];
		_webConnector = nil;
	}
}

@end
