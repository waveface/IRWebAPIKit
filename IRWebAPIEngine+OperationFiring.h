//
//  IRWebAPIEngine+OperationFiring.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 6/25/12.
//
//

#import "IRWebAPIEngine.h"

@interface IRWebAPIEngine (OperationFiring)

- (void) fireAPIRequestNamed:(NSString *)methodName withArguments:(NSDictionary *)arguments options:(NSDictionary *)options validator:(IRWebAPIResponseValidator)validatorBlock successHandler:(IRWebAPICallback)successBlock failureHandler:(IRWebAPICallback)failureBlock;

@end

extern NSString * const kIRWebAPIEngineRequestHTTPBaseURL;
extern NSString * const kIRWebAPIEngineRequestHTTPHeaderFields;
extern NSString * const kIRWebAPIEngineRequestHTTPPOSTParameters;
extern NSString * const kIRWebAPIEngineRequestHTTPBody;
extern NSString * const kIRWebAPIEngineRequestHTTPQueryParameters;
extern NSString * const kIRWebAPIEngineRequestHTTPMethod;
extern NSString * const kIRWebAPIEngineParser;
extern NSString * const kIRWebAPIEngineResponseContextURLResponse;
extern NSString * const kIRWebAPIRequestTimeout;

extern NSString * const kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey;
