#import <objc/message.h>
#import <UIKit/UIKit.h>
#import "WEBPURLProtocol.h"
#define UIWEBVIEW_WEBP_DEBUG

static NSString * const WebpURLRequestHandledKey = @"Webp-handled";
static NSString * const WebpURLRequestHandledValue = @"handled";
static id <WEBPURLProtocolDecoder> decoder = nil;

@interface WEBPURLProtocol () <NSURLSessionDataDelegate>
@property (atomic, copy) NSArray *modes;
@property (atomic, strong) NSThread *clientThread;
@property (atomic, strong) NSMutableData *data;
@property (atomic, strong) NSURLRequest *tmpRequest;
@property (atomic, strong) NSURLSession *session;
@end

@implementation WEBPURLProtocol

- (void)p_performBlock:(dispatch_block_t)block
{
#if defined (DEBUG) && defined (UIWEBVIEW_WEBP_DEBUG)
    NSAssert(self.modes != nil, @"UIWEBVIEW WEBP ERROR #4");
    NSAssert(self.modes.count > 0, @"UIWEBVIEW WEBP ERROR #5");
    NSAssert(self.clientThread != nil, @"UIWEBVIEW WEBP ERROR #6");
#endif
    [self performSelector:@selector(p_helperPerformBlockOnClientThread:) onThread:self.clientThread withObject:[block copy] waitUntilDone:NO modes:self.modes];
}

- (void)p_helperPerformBlockOnClientThread:(dispatch_block_t)block
{
#if defined (DEBUG) && defined (UIWEBVIEW_WEBP_DEBUG)
    NSAssert([NSThread currentThread] == self.clientThread, @"UIWEBVIEW WEBP ERROR #7");
#endif
    if(block != nil)
    {
        block();
    }
}

+ (void)registerWebP: (id <WEBPURLProtocolDecoder>)externalDecoder {
#if defined (DEBUG) && defined (UIWEBVIEW_WEBP_DEBUG)
	NSAssert([NSThread isMainThread], @"UIWEBVIEW WEBP ERROR #8");
    NSAssert(externalDecoder != nil, @"UIWEBVIEW WEBP ERROR #10");
    NSAssert([externalDecoder respondsToSelector:@selector(decodeWebpData:)], @"UIWEBVIEW WEBP ERROR #12");
#endif
    decoder = externalDecoder;
	[NSURLProtocol registerClass:self];
}

+ (void)unregister {
#if defined (DEBUG) && defined (UIWEBVIEW_WEBP_DEBUG)
    NSAssert([NSThread isMainThread], @"UIWEBVIEW WEBP ERROR #9");
#endif
	[self unregisterClass:self];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
    if (!request) {
        return NO;
    }
    
    if (!request.URL) {
        return NO;
    }
    
    if (!request.URL.absoluteString) {
        return NO;
    }
    
    NSString * const requestURLPathExtension = request.URL.pathExtension.lowercaseString;

    if (!requestURLPathExtension) {
        return NO;
    }
    
    BOOL webpExtension = NO;
    
    if ([@"webp" isEqualToString:requestURLPathExtension]) {
        webpExtension = YES;
    }
    
    if (webpExtension == NO) {
        return NO;
    }
    
    if ([self propertyForKey:WebpURLRequestHandledKey inRequest:request] == WebpURLRequestHandledValue) {
        return NO;
    }
    
    NSString *scheme = request.URL.scheme;
    
    if (!scheme) {
        return NO;
    }
    
    scheme = [scheme lowercaseString];
    
    if (!scheme) {
        return NO;
    }
    
    if (([@"http" isEqualToString:scheme] == NO) && ([@"https" isEqualToString:scheme] == NO)) {
        return NO;
    }
    
	request = [self webp_canonicalRequestForRequest:request];
	return [NSURLConnection canHandleRequest:request];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return [self webp_canonicalRequestForRequest:request];
}

+ (NSURLRequest *)webp_canonicalRequestForRequest:(NSURLRequest *)request {
	NSURL *url = request.URL;
	NSMutableURLRequest * const modifiedRequest = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
    NSString *mimeType = @"image/webp";
	[modifiedRequest addValue:mimeType forHTTPHeaderField:@"Accept"];
	[self setProperty:WebpURLRequestHandledValue forKey:WebpURLRequestHandledKey inRequest:modifiedRequest];
	return modifiedRequest;
}


- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
	if ((self = [super initWithRequest:request cachedResponse:cachedResponse client:client])) {
		request = [self.class canonicalRequestForRequest:request];
        self.tmpRequest = request;
	}
	return self;
}

- (void)dealloc {
    [self.session invalidateAndCancel];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSHTTPURLResponse * const httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
    
    if (httpResponse.statusCode != 200) {
        completionHandler(NSURLSessionResponseCancel);
        [self p_performBlock:^{
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
        }];
        return;
    }
    
    completionHandler(NSURLSessionResponseAllow);
    [self p_didReceiveResponsefromCache:NO expectedLength:response.expectedContentLength];
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    if (error) {
        [self p_performBlock:^{
            [self.client URLProtocol:self didFailWithError:error];
        }];
    }
    else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = [NSError errorWithDomain:@"Webp_UIWebView_ERROR_DOMAIN" code:1 userInfo:@{}];
            UIImage *image = [decoder decodeWebpData:self.data];
            if (!image) {
                [self p_performBlock:^{
                    [self.client URLProtocol:self didFailWithError:error];
                }];
                return;
            }
            NSData *imagePngData = UIImagePNGRepresentation(image);
            [self p_performBlock:^{
                [self.client URLProtocol:self didLoadData:imagePngData];
                [self.client URLProtocolDidFinishLoading:self];
            }];
        });
    }
}

- (void)p_startConnection {
    [self p_performBlock:^{
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        NSURLSessionDataTask *task = [self.session dataTaskWithRequest:self.tmpRequest];
        [task resume];
    }];
}

- (void)startLoading {
    NSMutableArray *calculatedModes;
    NSString *currentMode;
    calculatedModes = [NSMutableArray array];
    [calculatedModes addObject:NSDefaultRunLoopMode];
    currentMode = [[NSRunLoop currentRunLoop] currentMode];
    if ( (currentMode != nil) && ! [currentMode isEqual:NSDefaultRunLoopMode] ) {
        [calculatedModes addObject:currentMode];
    }
    self.modes = calculatedModes;
#if defined (DEBUG) && defined (UIWEBVIEW_WEBP_DEBUG)
    NSAssert([self.modes count] > 0, @"UIWEBVIEW WEBP ERROR #11");
#endif
    self.clientThread = [NSThread currentThread];
    [self p_startConnection];
}

- (void)stopLoading {
    [self.session invalidateAndCancel];
}

- (void)p_didReceiveResponsefromCache: (BOOL)fromCache expectedLength: (long long)expectedLength{
    NSString *contentType = @"image/png";
    NSDictionary * const responseHeaderFields = @{
                                                  @"Content-Type": contentType,
                                                  @"X-Webp": @"YES",
                                                  };
    
    NSURLRequest * const request = self.request;
    NSHTTPURLResponse * const modifiedResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.0" headerFields:responseHeaderFields];
    
    if (!fromCache) {
        if (expectedLength > 0) {
            self.data = [[NSMutableData alloc] initWithCapacity:expectedLength];
        } else {
            self.data = [[NSMutableData alloc] initWithCapacity:50 * 1024];// Default to 50KB
        }
    }
    [self p_performBlock:^{
        [self.client URLProtocol:self didReceiveResponse:modifiedResponse cacheStoragePolicy:NSURLCacheStorageAllowed];
    }];
}

@end
