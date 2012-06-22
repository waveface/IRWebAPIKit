//
//  IRWebAPIEngine+FormMultipart.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/23/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIEngine.h"


extern NSString * const kIRWebAPIEngineRequestContextFormMultipartFieldsKey;

@interface IRWebAPIEngine (FormMultipart)

+ (IRWebAPIRequestContextTransformer) defaultFormMultipartTransformer;

@end
