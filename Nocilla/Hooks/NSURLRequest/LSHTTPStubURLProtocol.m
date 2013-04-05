#import "LSHTTPStubURLProtocol.h"
#import "LSNocilla.h"
#import "NSURLRequest+LSHTTPRequest.h"
#import "LSStubRequest.h"
#import "LSStubResponse.h"
#import "NSURLRequest+DSL.h"

@interface NSHTTPURLResponse(UndocumentedInitializer)
- (id)initWithURL:(NSURL*)URL statusCode:(NSInteger)statusCode headerFields:(NSDictionary*)headerFields requestTime:(double)requestTime;
@end

static NSURLRequest* unstubbedRequest = nil;

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
        LSStubResponse *suggestedStubResponse = [[LSStubResponse alloc] initWithRawResponse:data statusCode:response.statusCode headers:response.allHeaderFields];
        NSLog(@"An unexcepted HTTP request was fired.\n\nUse this snippet to stub the request:\n%@\n%@\n", [request toNocillaDSL], [suggestedStubResponse toNocillaDSL]);

        [NSException raise:@"NocillaUnexpectedRequest" format:@"An unexcepted HTTP request was fired.\n\nUse this snippet to stub the request:\n%@\n%@\n", [request toNocillaDSL], [suggestedStubResponse toNocillaDSL]];
    }
    [client URLProtocol:self didReceiveResponse:urlResponse
     cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [client URLProtocol:self didLoadData:body];
    [client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end
