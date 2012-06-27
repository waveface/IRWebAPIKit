//
//  IRWebAPIEngine+FormURLEncoding.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "IRWebAPIEngine.h"

@interface IRWebAPIRequestContext (FormURLEncoding)

@property (nonatomic, readonly, copy) NSDictionary *formURLEncodingFields;
- (void) removeAllFormURLEncodingFieldValues;
- (void) setValue:(id)obj forFormURLEncodingField:(NSString *)key;

@end

@interface IRWebAPIEngine (FormURLEncoding)

+ (IRWebAPIRequestContextTransformer) defaultFormURLEncodingTransformer;

@end

extern NSData * IRWebAPIEngineFormURLEncodedDataWithDictionary (NSDictionary *formNamesToContents);
