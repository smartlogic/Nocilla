#import <Foundation/Foundation.h>
#import "LSHTTPResponse.h"

@interface LSStubResponse : NSObject<LSHTTPResponse>

@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, strong) NSData *body;
@property (nonatomic, strong, readonly) NSDictionary *headers;

- (id)initWithStatusCode:(NSInteger)statusCode;
- (id)initWithRawResponse:(NSData *)rawResponseData;
- (id)initWithRawResponse:(NSData *)rawResponseData statusCode:(NSInteger)statusCode headers:(NSDictionary *)headers;
- (id)initDefaultResponse;
- (void)setHeader:(NSString *)header value:(NSString *)value;
- (NSString *)toNocillaDSL;
@end
