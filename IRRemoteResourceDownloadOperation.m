//
//  IRRemoteResourceDownloadOperation.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 9/16/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "IRRemoteResourceDownloadOperation.h"

NSString * const kIRRemoteResourcesDownloadOperation_connectionRequest = @"kIRRemoteResourcesDownloadOperation_connectionRequest";

NSString * const kIRRemoteResourceDownloadOperationDidReceiveDataNotification = @"IRRemoteResourceDownloadOperationDidReceiveDataNotification";
NSString * const kIRRemoteResourceDownloadOperationURL = @"IRRemoteResourceDownloadOperationURL";


@interface IRRemoteResourceDownloadOperation ()

@property (nonatomic, readwrite, copy) NSString *path;
@property (nonatomic, readwrite, copy) NSString *mimeType;
@property (nonatomic, readwrite, retain) NSURL *url;
@property (nonatomic, readwrite, assign) long long processedBytes;
@property (nonatomic, readwrite, assign) long long totalBytes;
@property (nonatomic, readwrite, assign) long long preferredByteOffset;
@property (nonatomic, readwrite, assign, getter=isExecuting) BOOL executing;
@property (nonatomic, readwrite, assign, getter=isFinished) BOOL finished;
@property (nonatomic, readwrite, assign, getter=isCancelled) BOOL cancelled;
@property (nonatomic, readwrite, retain) NSFileHandle *fileHandle;
@property (nonatomic, readwrite, retain) NSURLConnection *connection;
@property (nonatomic, readwrite, assign) dispatch_queue_t actualDispatchQueue;
@property (nonatomic, readwrite, retain) NSMutableArray *appendedCompletionBlocks;

- (void) onMainQueue:(void(^)(void))aBlock;
- (void) onOriginalQueue:(void(^)(void))aBlock;

@property (nonatomic, readwrite, copy) void(^onMain)(void);

@end


@implementation IRRemoteResourceDownloadOperation

@synthesize path, mimeType, url, processedBytes, totalBytes, preferredByteOffset, executing, finished, cancelled;
@synthesize fileHandle = _fileHandle;
@synthesize connection = _connection;
@synthesize actualDispatchQueue;
@synthesize onMain;
@synthesize appendedCompletionBlocks;
@synthesize delegate;

+ (IRRemoteResourceDownloadOperation *) operationWithURL:(NSURL *)aRemoteURL path:(NSString *)aLocalPath prelude:(void(^)(void))aPrelude completion:(void(^)(void))aBlock {

	NSParameterAssert(aRemoteURL);
	NSParameterAssert(aLocalPath);

	IRRemoteResourceDownloadOperation *returnedOperation = [[self alloc] init];
	
	returnedOperation.url = aRemoteURL;
	returnedOperation.path = aLocalPath;
	returnedOperation.onMain = aPrelude;
	returnedOperation.completionBlock = aBlock;
	
	return returnedOperation;

}

- (void) dealloc {

	[_connection cancel];
	
}

- (void) onMainQueue:(void(^)(void))aBlock {
	
	if (!self.actualDispatchQueue)
		self.actualDispatchQueue = dispatch_get_current_queue();
	
	if ([NSThread isMainThread]) {
		aBlock();
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^ {
		aBlock();
	});
	
}

- (void) onOriginalQueue:(void(^)(void))aBlock {

	dispatch_async(self.actualDispatchQueue, aBlock);
	
}

- (void) start {

	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
		return;
	}

	if ([self isCancelled]) {
		self.finished = YES;
		return;
	}
	
	self.executing = YES;
	[self main];

}

- (void) main {

	NSParameterAssert(self.url);
	NSParameterAssert(self.path);
	
	if (self.onMain)
		self.onMain();
	
	[[NSFileManager defaultManager] createFileAtPath:self.path contents:nil attributes:nil];
	self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.path];
	NSParameterAssert(self.fileHandle);
	
	[self onMainQueue: ^ {
	
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
		
		NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
		
		objc_setAssociatedObject(connection, &kIRRemoteResourcesDownloadOperation_connectionRequest, request, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		self.connection = connection;
		
		[self.delegate remoteResourceDownloadOperationWillBegin:self];
		
		connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
		
		objc_setAssociatedObject(connection, &kIRRemoteResourcesDownloadOperation_connectionRequest, request, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		self.connection = connection;
		
		//	Do not mutate the URL
		//	self.url = usedRequest.URL;
		
		[self.connection start];
		
	}];
	
}

- (void) cancel {

	[self onMainQueue: ^ {		
		[self.connection cancel];
	}];
	
	[self onOriginalQueue: ^ {
		[self.fileHandle closeFile];
		self.fileHandle = nil;
	}];
	
	if (self.executing) {
		self.executing = NO;
		self.finished = YES;
	}
	
	self.cancelled = YES;

}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

	if ([self isCancelled])
		return;
	
	[self onOriginalQueue: ^ {

		if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		
			NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
			if (httpResponse.statusCode != 200) {
			
				[self.fileHandle closeFile];
				self.fileHandle = nil;
				
				[[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
				
			}
		
		}
		
		//	Per discussion in Apple documentation, this can be called multiple times
		
		[self.fileHandle truncateFileAtOffset:0];
		self.mimeType = response.MIMEType;

		[self willChangeValueForKey:@"progress"];
		self.totalBytes = response.expectedContentLength;
		[self didChangeValueForKey:@"progress"];
		
	}];

}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {

	if ([self isCancelled])
			return;
		
	[self onOriginalQueue: ^ {
	
		[self willChangeValueForKey:@"progress"];
		self.processedBytes += [data length];
		[self didChangeValueForKey:@"progress"];
		
		[self.fileHandle writeData:data];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kIRRemoteResourceDownloadOperationDidReceiveDataNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
		
			self.url, kIRRemoteResourceDownloadOperationURL,
		
		nil]];
			
	}];

}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {

	if ([self isCancelled]) {
    if ([self.delegate respondsToSelector:@selector(remoteResourceDownloadOperationDidEnd:successfully:)])
      [self.delegate remoteResourceDownloadOperationDidEnd:self successfully:NO];
    return;
  }
	
	[self onOriginalQueue: ^ {
	
		[self.fileHandle closeFile];
		self.fileHandle = nil;
		
		if (self.mimeType) {
		
			//	If there is a MIME type available, rename the underlying file
			
			CFStringRef const tag = (__bridge CFStringRef)self.mimeType;
			NSString *utiType = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, tag, NULL));
			
			CFStringRef const tagClass = kUTTagClassFilenameExtension;
			NSString *pathExtension = (NSString *)CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)utiType, tagClass));
			
			if (pathExtension) {

				NSFileManager * const fm = [NSFileManager defaultManager];
				
				NSString *fromPath = self.path;
				NSString *toPath = [[self.path stringByDeletingPathExtension] stringByAppendingPathExtension:pathExtension];
				NSError *error = nil;
				
				BOOL didMove = [fm moveItemAtPath:fromPath toPath:toPath error:&error];
				if (!didMove) {
					NSLog(@"%s: %@ -> %@ Error: %@", __PRETTY_FUNCTION__, fromPath, toPath, error);
				} else {
					self.path = toPath;
				}
			
			}
		
		}
		
		if (self.executing) {
			self.executing = NO;
			self.finished = YES;
		}
    
    if ([self.delegate respondsToSelector:@selector(remoteResourceDownloadOperationDidEnd:successfully:)])
      [self.delegate remoteResourceDownloadOperationDidEnd:self successfully:YES];
	
	}];

}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

	if ([self isCancelled])
		return;
		
	[self onOriginalQueue: ^ {
	
		[self.fileHandle closeFile];
		self.fileHandle = nil;
		
		[[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
		
		if (self.executing) {
			self.executing = NO;
			self.finished = YES;
		}
		
	}];

}

- (NSURLRequest *) connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)aRequest redirectResponse:(NSURLResponse *)aRedirectResponse {

	if (!aRedirectResponse)
		return aRequest;
		
	NSMutableURLRequest *mutatedRequest = [[self underlyingRequest] mutableCopy];
	mutatedRequest.URL = [aRequest URL];
	
	return mutatedRequest;

}

- (BOOL) isConcurrent {

	return YES;

}

- (float_t) progress {

	if (totalBytes <= 0)
		return 0.0f;
	
	return (float_t)((double_t)processedBytes / (double_t)totalBytes);

}

- (void) setFinished:(BOOL)newFinished {

	if (newFinished == finished)
		return;
	
	[self willChangeValueForKey:@"isFinished"];
	finished = newFinished;
	[self didChangeValueForKey:@"isFinished"];

}

- (void) setExecuting:(BOOL)newExecuting {

	if (newExecuting == executing)
		return;
	
	[self willChangeValueForKey:@"isExecuting"];
	executing = newExecuting;
	[self didChangeValueForKey:@"isExecuting"];

}

- (NSString *) description {

	return [NSString stringWithFormat:
	
		@"<%@: 0x%x> "
		
		//	@"Offset: %lu, "
		
		@"URL: %@, "
		@"Path: %@, "
		@"Completion Blocks: %@, "
		
		@"Executing: %x, "
		@"Cancelled: %x, "
		@"Finished: %x ",
		
		NSStringFromClass([self class]), (unsigned int)self, 

		//	self.preferredByteOffset,
		
		self.url, 
		self.path, 
		self.appendedCompletionBlocks,
		
		self.executing,
		self.cancelled,
		self.finished
		
	];

}

- (NSMutableArray *) appendedCompletionBlocks {

	if (!appendedCompletionBlocks) {
		appendedCompletionBlocks = [NSMutableArray array];
	}
	
	return appendedCompletionBlocks;

}

- (void) appendCompletionBlock:(void (^)(void))aBlock {

	[self.appendedCompletionBlocks addObject:[aBlock copy]];

}

- (void) invokeCompletionBlocks {

	@synchronized (self) {	

		for (void(^aBlock)(void) in self.appendedCompletionBlocks)
			aBlock();
		
		self.appendedCompletionBlocks = [NSMutableArray array];
	
	}

}

- (IRRemoteResourceDownloadOperation *) continuationOperationCancellingCurrentOperation:(BOOL)cancelsCurrentOperation {

	if (!self.path || !self.url)
		return nil;

	__block IRRemoteResourceDownloadOperation *continuationOperation = [[[self class] alloc] init];
	continuationOperation.path = self.path;
	continuationOperation.url = self.url;
	continuationOperation.preferredByteOffset = self.processedBytes;
	continuationOperation.totalBytes = self.totalBytes;
	
	@synchronized (self) {
	
		continuationOperation.appendedCompletionBlocks = self.appendedCompletionBlocks;
		[self.appendedCompletionBlocks removeAllObjects];
		
	}

	if (cancelsCurrentOperation) {
		[self.connection cancel];
		[self cancel];
	}
	
	return continuationOperation;

}

- (NSURLConnection *) underlyingConnection {

	return self.connection;

}

- (NSMutableURLRequest *) underlyingRequest {

	return objc_getAssociatedObject([self underlyingConnection], &kIRRemoteResourcesDownloadOperation_connectionRequest);

}

@end
