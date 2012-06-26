//
//  IRWebAPIEngine+LocalCaching.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/23/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <objc/runtime.h>

#import "IRWebAPIEngine+LocalCaching.h"
#import "IRWebAPIHelpers.h"

static NSString * const kCacheFileURLS = @"-[IRWebAPIRequestContext(LocalCaching) cacheFileURLs]";

@implementation IRWebAPIRequestContext (LocalCaching)

- (NSArray *) cacheFileURLs {

	return [objc_getAssociatedObject(self, &kCacheFileURLS) copy];

}

- (void) removeAllCacheFileURLValues {

	[self willChangeValueForKey:@"cacheFileURLs"];
	objc_setAssociatedObject(self, &kCacheFileURLS, nil, OBJC_ASSOCIATION_ASSIGN);
	[self didChangeValueForKey:@"cacheFileURLs"];

}

- (void) addCacheFileURL:(NSURL *)obj {

	NSMutableArray *cacheFileURLs = objc_getAssociatedObject(self, &kCacheFileURLS);
	
	if (!cacheFileURLs) {
		cacheFileURLs = [NSMutableArray array];
		objc_setAssociatedObject(self, &cacheFileURLs, cacheFileURLs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	[self willChangeValueForKey:@"cacheFileURLs"];
	
	if (obj) {
		[cacheFileURLs addObject:obj];
	} else {
		[cacheFileURLs removeObject:obj];
	}
	
	[self didChangeValueForKey:@"cacheFileURLs"];

}

@end


@implementation IRWebAPIEngine (LocalCaching)

+ (NSURL *) newTemporaryFileURL {

	NSString *applicationCacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *preferredCacheDirectoryPath = [applicationCacheDirectory stringByAppendingPathComponent:NSStringFromClass([self class])];
	
	if ([[NSFileManager defaultManager] createDirectoryAtPath:preferredCacheDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil])
		return [NSURL fileURLWithPath:[preferredCacheDirectoryPath stringByAppendingPathComponent:IRWebAPIKitNonce()]];
	
	return nil;
	
}


+ (BOOL) cleanUpTemporaryFileAtURL:(NSURL *)inTemporaryFileURL {

	return [[NSFileManager defaultManager] removeItemAtURL:inTemporaryFileURL error:nil];

}


+ (IRWebAPIResponseContextTransformer) defaultCleanUpTemporaryFilesResponseTransformer {

	return [(^ (NSDictionary *inParsedResponse, IRWebAPIRequestContext *inResponseContext) {
	
		NSArray *cachedFileURLs = inResponseContext.cacheFileURLs;
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^ {
		
			for (NSURL *aFileURL in cachedFileURLs)
				[self cleanUpTemporaryFileAtURL:aFileURL];
	
		});

		return inParsedResponse;
	
	}) copy];

}

@end
