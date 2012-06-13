//
//  IRWebAPIHelpers.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/24/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIHelpers.h"





# pragma mark -
# pragma mark Request Arguments Helpers

NSString * IRWebAPIKitStringValue (id<NSObject> inObject) {

	if (!inObject)
	return @"";
	
	if ([inObject isKindOfClass:[NSString class]])
	return (NSString *)inObject;
		
	if ([inObject respondsToSelector:@selector(stringValue)])
	return IRWebAPIKitStringValue([inObject performSelector:@selector(stringValue)]);
	
	return [inObject description];

}

BOOL IRWebAPIKitValidResponse (id inObject) {

	if (!inObject || [inObject isEqual:[NSNull null]]) return NO;
	
	return YES;

}

id IRWebAPIKitWrapNil(id inObjectOrNil) {

	if (inObjectOrNil == nil)
	return [NSNull null];
	
	return inObjectOrNil;

}

id IRWebAPIKitNumberOrNull (NSNumber *aNumber) {

	if (!(BOOL)[aNumber boolValue])
	return [NSNull null];
	
	return aNumber;
	
};





# pragma mark -
# pragma mark # pragma mark Encoding, Decoding and Conversion

NSString * IRWebAPIKitRFC3986EncodedStringMake (id<NSObject> inObject) {

	NSString *inString = IRWebAPIKitStringValue(inObject);

//	From Google’s GData Toolkit
//	http://oauth.net/core/1.0a/#encoding_parameters

	CFStringRef originalString = (CFStringRef)inString;

	CFStringRef leaveUnescaped = CFSTR("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._~");
	CFStringRef forceEscaped =  CFSTR("%!$&'()*+,/:;=?@");
	
	CFStringRef escapedStr = NULL;

	if (inString) {

		escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, originalString, leaveUnescaped, forceEscaped, kCFStringEncodingUTF8);
		
		[(id)CFMakeCollectable(escapedStr) autorelease];

	}
	
	return (NSString *)escapedStr;
	
}

NSString * IRWebAPIKitRFC3986DecodedStringMake (id<NSObject> inObject) {

	NSString *inString = IRWebAPIKitStringValue(inObject);
	
//	From Google’s GData Toolkit
//	http://oauth.net/core/1.0a/#encoding_parameters

	CFStringRef originalString = (CFStringRef)inString;

	CFStringRef unescapedStr = NULL;

	if (inString) {

		unescapedStr = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, originalString, CFSTR(""), kCFStringEncodingUTF8);
		
		[(id)CFMakeCollectable(unescapedStr) autorelease];

	}

	return (NSString *)unescapedStr;
	
}

NSString * IRWebAPIKitBase64StringFromNSDataMake (NSData *inData) {

//	Cyrus Najmabadi
//	Elegent little encoder
//	http://www.cocoadev.com/index.pl?BaseSixtyFour

//	From Google’s GData Toolkit

	if (inData == nil) return nil;

	const uint8_t* input = [inData bytes];
	NSUInteger length = [inData length];

	NSUInteger bufferSize = ((length + 2) / 3) * 4;
	NSMutableData* buffer = [NSMutableData dataWithLength:bufferSize];

	uint8_t* output = [buffer mutableBytes];

	static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	for (NSUInteger i = 0; i < length; i += 3) {

		NSInteger value = 0;
		
		for (NSUInteger j = i; j < (i + 3); j++) {

			value <<= 8;

			if (j < length)
			value |= (0xFF & input[j]);

		}

		NSInteger idx = (i / 3) * 4;
		output[idx + 0] =                    table[(value >> 18) & 0x3F];
		output[idx + 1] =                    table[(value >> 12) & 0x3F];
		output[idx + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
		output[idx + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';

	}

	return [[[NSString alloc] initWithData:buffer encoding:NSASCIIStringEncoding] autorelease];

}

NSString * IRWebAPIStringByDecodingXMLEntities (NSString *inString) {

//	Modified from:
//	http://stackoverflow.com/questions/659602/objective-c-html-escape-unescape
	
	static NSDictionary *entityNamesToNumbers;
	NSString *ampersand = @"&";
	
	if ([inString rangeOfString:ampersand options:NSLiteralSearch].location == NSNotFound)
	return inString;
	
	NSMutableString *result = [NSMutableString stringWithCapacity:([inString length] * 1.25)];
	NSScanner *scanner = [NSScanner scannerWithString:inString];
	NSCharacterSet *boundaryCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\r;"];

	[scanner setCharactersToBeSkipped:nil];

	entityNamesToNumbers = entityNamesToNumbers ? entityNamesToNumbers : [IRWebAPIKitXMLEntityNumbersFromNames() retain];
	
	NSString* (^scanEntityNumber) (NSScanner **inScanner) = ^ (NSScanner **inScanner) {
	
		NSScanner *scanner = *inScanner;
				
		if (![scanner scanString:@"&#" intoString:NULL]) {
		
			[scanner scanString:ampersand intoString:NULL];
			return ampersand;

		}

		unsigned int charCode;
		NSString *xForHex = @"";
		
		if ([scanner scanString:@"x" intoString:NULL] ? [scanner scanHexInt:&charCode] : [scanner scanInt:(int*)&charCode]) {

			[scanner scanString:@";" intoString:NULL];
			return (NSString *)[NSString stringWithFormat:@"%C", (unsigned short)charCode];
    
		}

		NSString *unknownEntity = @"";
		[scanner scanUpToCharactersFromSet:boundaryCharacterSet intoString:&unknownEntity];
		
		IRWebAPIKitLog(@"Expected numeric character entity but got &#%@%@;", xForHex, unknownEntity);
	
		return (NSString *)[NSString stringWithFormat:@"&#%@%@", xForHex, unknownEntity];
	
	};
	
	
	while (![scanner isAtEnd]) {

		NSString *nonEntityString;

		if ([scanner scanUpToString:ampersand intoString:&nonEntityString])
		[result appendString:nonEntityString];

		if ([scanner isAtEnd])
		return result;
		
		BOOL didScanEntity = NO;
		
		for (id entityRep in entityNamesToNumbers)
		if ([scanner scanString:entityRep intoString:NULL]) {
		
			NSScanner *entityNumberScanner = [NSScanner scannerWithString:[entityNamesToNumbers objectForKey:entityRep]];
		
			[result appendString:scanEntityNumber(&entityNumberScanner)];
			didScanEntity = YES;
			break;
		
		}
		
		if (didScanEntity)
		continue;
		
		[result appendString:scanEntityNumber(&scanner)];

	}
	
	
	return result;

}





# pragma mark -
# pragma mark Randomness and Order

NSString * IRWebAPIKitTimestamp () {

	return [NSString stringWithFormat:@"%lu", time(NULL)];

}

NSString * IRWebAPIKitNonce () {

	NSString *uuid = nil;
	
	CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
	if (!theUUID) return nil;
	
	uuid = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, theUUID) autorelease];
	CFRelease(theUUID);
	
	return [NSString stringWithFormat:@"%@-%@", IRWebAPIKitTimestamp(), uuid];
	
}





# pragma mark -
# pragma mark Crypto Helpers

NSString * IRWebAPIKitOAuthSignatureBaseStringMake (NSString *inHTTPMethod, NSURL *inBaseURL, NSDictionary *inQueryParameters) {

	IRWebAPIKitLog(@"IRWebAPIKitOAuthSignatureBaseStringMake -> %@ %@ %@", inHTTPMethod, inBaseURL, inQueryParameters);

	NSString * (^uriEncode) (NSString *) = ^ NSString * (NSString *inString) {

		return IRWebAPIKitRFC3986EncodedStringMake(inString);
	
	};

	NSMutableString *returnedString = [NSMutableString string];
	
	[returnedString appendString:inHTTPMethod];
	[returnedString appendString:@"&"];
	[returnedString appendString:uriEncode([inBaseURL absoluteString])];
	
	if ([inQueryParameters count] != 0) {
	
		NSArray *sortedQueryParameterKeys = [[inQueryParameters allKeys] sortedArrayUsingSelector:@selector(compare:)];
		
		NSMutableArray *encodedQueryParameters = [NSMutableArray array];
		
		for (NSString *queryParameterKey in sortedQueryParameterKeys) {
		
			[encodedQueryParameters addObject:[NSString stringWithFormat:@"%@%@%@",
			
				uriEncode(queryParameterKey),
				@"%3D",
				uriEncode([inQueryParameters objectForKey:queryParameterKey])
				
			]];
					
		}
		
		[returnedString appendString:@"&"];
		[returnedString appendString:[encodedQueryParameters componentsJoinedByString:@"%26"]];

	}
	
	IRWebAPIKitLog(@"IRWebAPIKitOAuthSignatureBaseStringMake -> %@", returnedString);
	
	return returnedString;

}

NSString * IRWebAPIKitHMACSHA1 (NSString *inConsumerSecret, NSString *inTokenSecret, NSString *inPayload) {

	IRWebAPIKitLog(@"IRWebAPIKitHMACSHA1 -> %@ %@ %@", inConsumerSecret, inTokenSecret, inPayload);

//	From Google’s GData Toolkit

	NSString *encodedConsumerSecret = IRWebAPIKitRFC3986EncodedStringMake(inConsumerSecret);
	NSString *encodedTokenSecret = IRWebAPIKitRFC3986EncodedStringMake(inTokenSecret);

	NSString *key = [NSString stringWithFormat:@"%@&%@",
	
		encodedConsumerSecret ? encodedConsumerSecret : @"",
		encodedTokenSecret ? encodedTokenSecret : @""
		
	];
	
	NSMutableData *sigData = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
	
	CCHmac(
	
		kCCHmacAlgSHA1,

		[key UTF8String], [key length],
		[inPayload UTF8String], [inPayload length],
		[sigData mutableBytes]
	 
	);
	
	NSString *returnedString = IRWebAPIKitBase64StringFromNSDataMake(sigData);
	
	IRWebAPIKitLog(@"IRWebAPIKitHMACSHA1 -> %@", returnedString);
	
	return returnedString;
  
}





# pragma mark -
# pragma mark Type Helpers

NSString * IRWebAPIKitMIMETypeOfExtension (NSString *inExtension) {
	
	if (!inExtension)
	return nil;
	
	CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)inExtension, NULL);
	
	if(!UTI)
	return nil;
	
	CFStringRef registeredType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
	CFRelease(UTI);

	if (!registeredType)
	return nil;
		
	return [(NSString *)registeredType autorelease];

}





# pragma mark -
# pragma mark URL Helpers

NSString * IRWebAPIRequestURLQueryParametersStringMake (NSDictionary *inQueryParameters, NSString *inSeparator) {

	if ((!inQueryParameters) || ([inQueryParameters count] == 0))
		return @"";
	
	NSMutableArray *returnedStringParts = [NSMutableArray array];

	for (NSString *queryParameterKey in inQueryParameters)
	[returnedStringParts addObject:[NSString stringWithFormat:@"%@=%@", 
			
		IRWebAPIKitRFC3986EncodedStringMake(queryParameterKey), 
		IRWebAPIKitRFC3986EncodedStringMake([inQueryParameters objectForKey:queryParameterKey])
		
	]];

	return [returnedStringParts componentsJoinedByString:inSeparator];

}

NSURL * IRWebAPIRequestURLWithQueryParameters (NSURL *inBaseURL, NSDictionary *inQueryParametersOrNil) {

	if (inQueryParametersOrNil == nil) return inBaseURL;
	if ([inQueryParametersOrNil count] == 0) return inBaseURL;
	
	NSURL *returnedURL = [NSURL URLWithString:[[inBaseURL absoluteString] stringByAppendingFormat:@"?%@", IRWebAPIRequestURLQueryParametersStringMake(inQueryParametersOrNil, @"&")]];
	
	
	return returnedURL;

}

NSDictionary *IRQueryParametersFromString (NSString *query) {

	if (!query)
		return nil;

	NSMutableDictionary *mutableArguments = [NSMutableDictionary dictionary];
	NSRange queryFullRange = (NSRange) {0, [query length] };
	
	NSString *queryPairPattern = @"([^=\\?\\&]+)=([^=\\?\\&]+)?";
	NSRegularExpression *queryPairExpression = [NSRegularExpression regularExpressionWithPattern:queryPairPattern options:0 error:nil];
	
	//	([^=\?\&]+)=([^=\?\&]+)?(?=&)

	[queryPairExpression enumerateMatchesInString:query options:0 range:queryFullRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
	
		__block NSString *currentArgumentName = nil;
		__block NSString *currentArgumentValue = nil;
		
		NSUInteger numberOfRanges = result.numberOfRanges;
		if (!numberOfRanges)
			return;
		
		for (NSUInteger i = 0; i < numberOfRanges; i++) {
			
			NSRange substringRange = [result rangeAtIndex:i];
			if (substringRange.location == NSNotFound)
				continue;
			
			NSString *substring = [query substringWithRange:substringRange];
			
			if (i == 1)
				currentArgumentName = substring;
			else if (i == 2)
				currentArgumentValue = substring;
		
		}
		
		if (currentArgumentValue)
			[mutableArguments setObject:IRWebAPIKitRFC3986DecodedStringMake(currentArgumentValue) forKey:currentArgumentName];
		else
			[mutableArguments setObject:@"" forKey:currentArgumentName];
		
	}];
	
	return mutableArguments;

}
