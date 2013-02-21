//
//  IRWebAPIEngine+FormMultipart.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/23/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <objc/runtime.h>
#import "IRWebAPIEngine+FormMultipart.h"
#import "IRWebAPIEngine+LocalCaching.h"
#import "IRWebAPIHelpers.h"

NSString * const kIRWebAPIEngineRequestContextFormMultipartFieldsKey = @"kIRWebAPIEngineRequestContextFormMultipartFieldsKey";

static NSString * const kFormMultipartFields = @"-[IRWebAPIRequestContext(FormMultipart) formMultipartFields]";

@implementation IRWebAPIRequestContext (FormMultipart)

- (NSDictionary *) formMultipartFields {

	NSMutableDictionary *formMultipartFields = objc_getAssociatedObject(self, &kFormMultipartFields);
	
	if (!formMultipartFields) {
		formMultipartFields = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &kFormMultipartFields, formMultipartFields, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	return [formMultipartFields copy];

}

- (void) removeAllFormMultipartFieldValues {

	[self willChangeValueForKey:@"formMultipartFields"];
	objc_setAssociatedObject(self, &kFormMultipartFields, nil, OBJC_ASSOCIATION_ASSIGN);
	[self didChangeValueForKey:@"formMultipartFields"];

}

- (void) setValue:(id)obj forFormMultipartField:(NSString *)key {

	NSMutableDictionary *formMultipartFields = objc_getAssociatedObject(self, &kFormMultipartFields);
	
	if (!formMultipartFields) {
		formMultipartFields = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &kFormMultipartFields, formMultipartFields, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	[self willChangeValueForKey:@"formMultipartFields"];
	
	if (obj) {
		[formMultipartFields setObject:obj forKey:key];
	} else {
		[formMultipartFields removeObjectForKey:key];
	}
	
	[self didChangeValueForKey:@"formMultipartFields"];

}

@end

@implementation IRWebAPIEngine (FormMultipart)

+ (IRWebAPIRequestContextTransformer) defaultFormMultipartTransformer {

	return [(^ (IRWebAPIRequestContext *context) {
	
		NSDictionary *formNamesToContents = context.formMultipartFields;
		
		if (![formNamesToContents count])
			return context;
		
		NSError *error;
		NSURL *fileHandleURL = [[self class] newTemporaryFileURL];
		
		if (![[NSFileManager defaultManager] createFileAtPath:[fileHandleURL path] contents:[NSData data] attributes:nil]) {
			NSLog(@"Error creating file for URL %@.", fileHandleURL);
			return context;
		}
		
		NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:fileHandleURL error:&error];
		if (!fileHandle) {
			NSLog(@"Error grabbing file handle for URL %@: %@", fileHandleURL, error);
			return context;
		}
		
		[fileHandle truncateFileAtOffset:0];
		[fileHandle seekToEndOfFile];
		
		[context setValue:@"8bit" forHeaderField:@"Content-Transfer-Encoding"];
		
		NSString *mineBoundary = [NSString stringWithFormat:@"----_=_%@_%@_%@_=_----",
		
			NSStringFromClass([self class]),
			[[NSBundle mainBundle] bundleIdentifier],
			IRWebAPIKitNonce()
			
		];
		
		NSData *boundaryData = [mineBoundary dataUsingEncoding:NSUTF8StringEncoding];
		NSData *newLineData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
		NSData *separatorData = [@"--" dataUsingEncoding:NSUTF8StringEncoding];
		
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", mineBoundary];
		[context setValue:contentType forHeaderField:@"Content-Type"];
		
		//	Start writing
		
		for (id incomingFormName in formNamesToContents) {
		
      if ([incomingFormName isEqualToString:@"file_data"]) {
        continue;
      }

      //	--<BOUNDARY> ↵
			[fileHandle writeData:separatorData];
			[fileHandle writeData:boundaryData];
			[fileHandle writeData:newLineData];
			
			id incomingObject = [formNamesToContents objectForKey:incomingFormName];
      if ([incomingFormName isEqualToString:@"file"]) {
			
			//	Append contents of file
			
				[fileHandle writeData:[[NSString stringWithFormat:
				
					@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"",
					incomingFormName,
					incomingObject
				
				] dataUsingEncoding:NSUTF8StringEncoding]];
				
				[fileHandle writeData:newLineData];
				
				
				NSString *mimeType = IRWebAPIKitMIMETypeOfExtension([incomingObject pathExtension]);
				
				[fileHandle writeData:[[NSString stringWithFormat:
				
					@"Content-Type: %@", (mimeType ? mimeType : @"application/octet-stream")
				
				] dataUsingEncoding:NSUTF8StringEncoding]];				

				[fileHandle writeData:newLineData];
				[fileHandle writeData:newLineData];
			
				[fileHandle writeData:[formNamesToContents objectForKey:@"file_data"]];
			
			} else if ([incomingObject isKindOfClass:[NSString class]]) {

          //	Append contents of string

				[fileHandle writeData:[[NSString stringWithFormat:

                                @"Content-Disposition: form-data; name=\"%@\"",
                                incomingFormName

                                ] dataUsingEncoding:NSUTF8StringEncoding]];

				[fileHandle writeData:newLineData];
				[fileHandle writeData:newLineData];

				[fileHandle writeData:[(NSString *)incomingObject dataUsingEncoding:NSUTF8StringEncoding]];

			} else if ([incomingObject isKindOfClass:[NSData class]]) {
			
        [fileHandle writeData:(NSData *)incomingObject];
			
			} else {
			
				NSCAssert(NO, @"%s Can’t understand incoming object %@", __PRETTY_FUNCTION__, incomingObject);
			
			}

			[fileHandle writeData:newLineData];
		
		}
		
	//	--<BOUNDARY>-- ↵
		[fileHandle writeData:separatorData];
		[fileHandle writeData:boundaryData];
		[fileHandle writeData:separatorData];
		[fileHandle writeData:newLineData];
		
		[fileHandle closeFile];
		
		[context setBody:[NSData dataWithContentsOfFile:[fileHandleURL path] options:NSDataReadingMappedIfSafe error:nil]];
		[context addCacheFileURL:fileHandleURL];
		[context removeAllFormMultipartFieldValues];
		[context setMethod:@"POST"];
		
      if ([[NSFileManager defaultManager] fileExistsAtPath:[fileHandleURL path]]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:fileHandleURL error:&error];
        if (error != nil) {
          NSLog(@"failed to remove cached file for multipart transformer: %@", fileHandleURL);
        }
      }
		return context;
	
	}) copy];

}

@end
