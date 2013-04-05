#import "LSStubResponse.h"

@interface LSStubResponse ()
@property (nonatomic, assign, readwrite) NSInteger statusCode;
@property (nonatomic, strong) NSMutableDictionary *mutableHeaders;
@property (nonatomic, assign) UInt64 offset;
@property (nonatomic, assign, getter = isDone) BOOL done;
@end

@implementation LSStubResponse

#pragma Initializers
- (id)initDefaultResponse {
    self = [super init];
    if (self) {
        self.statusCode = 200;
        self.mutableHeaders = [NSMutableDictionary dictionary];
        self.body = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    }
    return self;
}

-(id)initWithStatusCode:(NSInteger)statusCode {
    self = [super init];
    if (self) {
        self.statusCode = statusCode;
        self.mutableHeaders = [NSMutableDictionary dictionary];
        self.body = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    }
    return self;
}

- (id)initWithRawResponse:(NSData *)rawResponseData {
    self = [self initDefaultResponse];
    if (self) {
        CFHTTPMessageRef httpMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
        if (httpMessage) {
            CFHTTPMessageAppendBytes(httpMessage, [rawResponseData bytes], [rawResponseData length]);
            
            self.body = rawResponseData; // By default
            
            if (CFHTTPMessageIsHeaderComplete(httpMessage)) {
                self.statusCode = (NSInteger)CFHTTPMessageGetResponseStatusCode(httpMessage);
                self.mutableHeaders = [NSMutableDictionary dictionaryWithDictionary:(__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(httpMessage)];
                self.body = (__bridge_transfer NSData *)CFHTTPMessageCopyBody(httpMessage);
            }
            CFRelease(httpMessage);
        }
    }
    return self;
}

- (id)initWithRawResponse:(NSData *)rawResponseData statusCode:(NSInteger)statusCode headers:(NSDictionary *)headers {
    self = [super init];
    if (self) {
        self.statusCode = statusCode;
        self.mutableHeaders = [headers mutableCopy];
        self.body = rawResponseData;
    }
    return self;
}

- (void)setHeader:(NSString *)header value:(NSString *)value {
    [self.mutableHeaders setValue:value forKey:header];
}
- (NSDictionary *)headers {
    return [NSDictionary dictionaryWithDictionary:self.mutableHeaders];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"StubRequest:\nStatus Code: %d\nHeaders: %@\nBody: %@",
            self.statusCode,
            self.mutableHeaders,
            self.body];
}

- (NSString *)toNocillaDSL {
    NSMutableString *result = [NSMutableString stringWithFormat:@"andReturn(%d)", self.statusCode];
    if (self.headers.count) {
        [result appendString:@".\nwithHeaders(@{ "];
        NSMutableArray *headerElements = [NSMutableArray arrayWithCapacity:self.headers.count];

        NSArray *descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"" ascending:YES]];
        NSArray * sortedHeaders = [[self.headers allKeys] sortedArrayUsingDescriptors:descriptors];

        for (NSString * header in sortedHeaders) {
            NSString *value = [self.headers objectForKey:header];
            [headerElements addObject:[NSString stringWithFormat:@"@\"%@\": @\"%@\"", header, value]];
        }
        [result appendString:[headerElements componentsJoinedByString:@", "]];
        [result appendString:@" })"];
    }
    if (self.body.length) {
        NSString *escapedBody = [[NSString alloc] initWithData:self.body encoding:NSUTF8StringEncoding];
        escapedBody = [escapedBody stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        [result appendFormat:@".\nwithBody(@\"%@\")", escapedBody];
    }
    return [NSString stringWithFormat:@"%@;", result];
}
@end
