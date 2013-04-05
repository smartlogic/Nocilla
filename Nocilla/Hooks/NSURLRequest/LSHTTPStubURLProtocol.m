#import "LSHTTPStubURLProtocol.h"
#import "LSNocilla.h"
#import "NSURLRequest+LSHTTPRequest.h"
#import "LSStubRequest.h"
#import "NSURLRequest+DSL.h"

@interface NSHTTPURLResponse(UndocumentedInitializer)
- (id)initWithURL:(NSURL*)URL statusCode:(NSInteger)statusCode headerFields:(NSDictionary*)headerFields requestTime:(double)requestTime;
@end

static NSURLRequest* unstubbedRequest = nil;
static NSString *LSFallThroughHeader = @"X-Nocilla-FallThrough";

@implementation LSHTTPStubURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [@[ @"http", @"https" ] containsObject:request.URL.scheme] && ![request isEqual:unstubbedRequest];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return NO;
}

- (void)startLoading {
    NSURLRequest* request = [self request];
	id<NSURLProtocolClient> client = [self client];
    
    LSStubRequest *stubbedRequest = nil;
    LSStubResponse* stubbedResponse = nil;
    NSArray* requests = [LSNocilla sharedInstance].stubbedRequests;
    
    for(LSStubRequest *someStubbedRequest in requests) {
        if ([someStubbedRequest matchesRequest:request]) {
            stubbedRequest = someStubbedRequest;
            stubbedResponse = stubbedRequest.response;
            break;
        }
    }
    
    NSHTTPURLResponse* urlResponse = nil;
    NSData *body = nil;
    if (stubbedRequest) {
        urlResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                                 statusCode:stubbedResponse.statusCode
                                                               headerFields:stubbedResponse.headers
                                                                requestTime:0];
        body = stubbedResponse.body;
    } else {
        NSHTTPURLResponse *response = nil;
        unstubbedRequest = request;

        NSData* data = [NSURLConnection sendSynchronousRequest:unstubbedRequest returningResponse:&response error:nil];
        NSString *returnBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"------------------------------------");
        NSLog(@"%@", [response allHeaderFields]);
        NSString *exceptionMessage = [NSString stringWithFormat:@"An unexcepted HTTP request was fired.\n\nUse this snippet to stub the request:\n%@\nandReturn(%d).\nwithHeaders(@\"{ Content-Type\": @\"%@\"}).\nwithBody(@\"%@\");\n", [request toNocillaDSL], response.statusCode, response.allHeaderFields[@"Content-type"], returnBody];
        NSLog(@"%@", exceptionMessage);
        NSLog(@"------------------------------------");

        [NSException raise:@"NocillaUnexpectedRequest" format:exceptionMessage];
    }
    [client URLProtocol:self didReceiveResponse:urlResponse
     cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [client URLProtocol:self didLoadData:body];
    [client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end
