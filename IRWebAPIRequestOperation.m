//
//  IRWebAPIRequestOperation.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 6/25/12.
//
//

#import "IRWebAPIRequestOperation.h"
#import "IRWebAPIRequestContext.h"
#import "IRWebAPIInterceptor.h"
#import "IRWebAPIHelpers.h"

@interface IRWebAPIRequestOperation () <NSURLConnectionDataDelegate> {
	BOOL _isExecuting;
	BOOL _isFinished;
}
@property (nonatomic, readwrite, assign) IRWebAPIRequestState state;
@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property (nonatomic, readonly, strong) NSMutableData *data;
@property (nonatomic, readonly, strong) IRWebAPIInterceptor *interceptor;
@end


@implementation IRWebAPIRequestOperation
@synthesize context = _context;
@synthesize request = _request;
@synthesize connection = _connection;
@synthesize state = _state;
@synthesize result = _result;
@synthesize data = _data;
@synthesize interceptor = _interceptor;

- (id) initWithContext:(IRWebAPIRequestContext *)context {

	self = [super init];
	if (!self)
		return;

	_context = context;
	
	_isExecuting = NO;
	_isFinished = NO;
	
	_state = IRWebAPIRequestStateEnqueued;
	
	return self;

}

- (void) start {

	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
		return;
	}
	
	[self willChangeValueForKey:@"isExecuting"];
	_isExecuting = YES;
	[self didChangeValueForKey:@"isExecuting"];
	
	_data = [NSMutableData data];
	
	_interceptor = [IRWebAPIInterceptor new];
	_interceptor.receiver = self;
	
	self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:(id<NSURLConnectionDelegate>)_interceptor];
	self.state = IRWebAPIRequestStateRunning;
	
	if (!_connection) {
		self.state = IRWebAPIRequestStateFailed;
		[self finish];
	}

}

- (void) cancel {

	[_connection cancel];
	_interceptor.receiver = nil;
	
	[super cancel];

	self.state = IRWebAPIRequestStateFailed;
	
}

- (void) finish {

	_connection = nil;
	
	if (self.data)
		_result = self.context.parser(self.data);
		
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];

	_isExecuting = NO;
	_isFinished = YES;

	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
	
}

- (BOOL) isExecuting {

	return _isExecuting;

}

- (BOOL) isFinished {

	return _isFinished;

}

- (NSURLRequest *) request {

	if (!_request) {
	
		NSURL *url = IRWebAPIRequestURLWithQueryParameters(self.context.baseURL, self.context.queryParams);
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:self.context.timeout];
		
		[self.context.headerFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[request setValue:obj forHTTPHeaderField:key];
		}];
		
		if (self.context.body)
			[request setHTTPBody:self.context.body];
		
		[request setHTTPMethod:self.context.method];
		[request setHTTPShouldHandleCookies:NO];
		
		_request = request;
	
	}
	
	return _request;

}

- (void) connection:(NSURLConnection *)inConnection didReceiveData:(NSData *)inData {

	[self.data appendData:inData];

}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

	NSCParameterAssert([response isKindOfClass:[NSHTTPURLResponse class]]);
	self.context.urlResponse = (NSHTTPURLResponse *)response;
	
	[self.data setLength:0];

}

- (void) connectionDidFinishLoading:(NSURLConnection *)inConnection {

	self.state = IRWebAPIRequestStateSucceeded;
	
	[self finish];

}

- (void) connection:(NSURLConnection *)inConnection didFailWithError:(NSError *)error {
	
	self.context.error = error;
	self.state = IRWebAPIRequestStateFailed;

	[self finish];

}

- (BOOL) connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
	
}

- (void) connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
		if ([[self.context.baseURL host] isEqualToString:challenge.protectionSpace.host])
			[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
	
  [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
	
}

- (NSString *) description {

	return [NSString stringWithFormat:@"<%@: %p { %@ %@ %@ }>", NSStringFromClass([self class]), self, self.context.engineMethod, self.context.method, self.context.baseURL];

}

@end
