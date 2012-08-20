//
//  IRWebAPIResponseParser.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/29/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIResponseParser.h"
#import "JSONKit.h"

NSDictionary * IRWebAPIResponseDictionarize (id<NSObject> incomingObject);

NSDictionary * IRWebAPIResponseDictionarize (id<NSObject> incomingObject) {

	if (!incomingObject)
		return (id)nil;

	if (![incomingObject isKindOfClass:[NSDictionary class]])
		return [NSDictionary dictionaryWithObject:incomingObject forKey:@"response"];
	
	return (id)incomingObject;

}



IRWebAPIResponseParser IRWebAPIResponseDefaultParserMake () {

//	Simply tucks the returned data into a dictionary

	NSDictionary * (^defaultParser) (NSData *) = ^ NSDictionary * (NSData *inData) {
	
		return [NSDictionary dictionaryWithObjectsAndKeys:
		
			inData, @"response",
			[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding], @"responseText",
			
		nil];
	
	};

	return [defaultParser copy];

}





IRWebAPIResponseParser IRWebAPIResponseQueryResponseParserMake () {

	//	Parses UTF8 String Data Like:
	//	
	//	Key=URL_Encoded_Value
	//	Another_Key=Another_Encoded_Value

	static IRWebAPIResponseParser parserBlock = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		parserBlock = [^ NSDictionary * (NSData *inData) {
		
			NSString *responseString = [[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
			
			NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"([^=&\n\r]+)=([^=&\n\r]+)[\n\r&]?" options:NSRegularExpressionCaseInsensitive error:nil];
			
			NSMutableDictionary *returnedResponse = [NSMutableDictionary dictionary];
			
			@try {
			
				[expression enumerateMatchesInString:responseString options:0 range:NSMakeRange(0, [responseString length]) usingBlock: ^ (NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
				
					[returnedResponse setObject:[responseString substringWithRange:[result rangeAtIndex:2]] forKey:[responseString substringWithRange:[result rangeAtIndex:1]]];
				
				}];
			
			} @catch (NSException * e) {
				
				NSLog(@"IRWebAPIResponseQueryResponseParser encountered an exception while parsing response.  Returning empty dictionary.");
				
				return [NSDictionary dictionary];
				
			}

			return returnedResponse;
		
		} copy];
					
	});
	
	return parserBlock;

}


IRWebAPIResponseParser IRWebAPIResponseDefaultJSONParserMake () {

	static IRWebAPIResponseParser parserBlock = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		
		parserBlock = [^ (NSData *incomingData) {
		
      NSError *error = nil;
      // sometimes the response from cloud contains invalid utf-8 characters,
      // so we deserialize it with loosely restriction
      id results = [incomingData objectFromJSONDataWithParseOptions:JKParseOptionLooseUnicode error:&error];

      if (error && [incomingData length] != 0) {
        NSLog(@"Unable to parse JSON response, error:%@", error);
      }
			
			return IRWebAPIResponseDictionarize(results);
			
		} copy];

	});
	
	return parserBlock;
	
}
