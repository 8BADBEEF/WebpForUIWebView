#import <Foundation/Foundation.h>

@class UIImage;

@protocol WEBPURLProtocolDecoder<NSObject>
- (UIImage *)decodeWebpData: (NSData *)data;
@end

@interface WEBPURLProtocol : NSURLProtocol
+ (void)registerWebP: (id <WEBPURLProtocolDecoder>)externalDecoder;
+ (void)unregister;
@end