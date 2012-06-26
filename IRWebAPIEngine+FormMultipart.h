//
//  IRWebAPIEngine+FormMultipart.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/23/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIEngine.h"
#import "IRWebAPIRequestContext.h"

@interface IRWebAPIRequestContext (FormMultipart)

@property (nonatomic, readonly, copy) NSDictionary *formMultipartFields;
- (void) removeAllFormMultipartFieldValues;
- (void) setValue:(id)obj forFormMultipartField:(NSString *)key;

@end

@interface IRWebAPIEngine (FormMultipart)

+ (IRWebAPIRequestContextTransformer) defaultFormMultipartTransformer;

@end

extern NSString * const kIRWebAPIEngineRequestContextFormMultipartFieldsKey;
