![][demo]

# Thread Safe WebP Support for Good Old UIWebView 

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)][project]
[![](https://img.shields.io/badge/license-MIT-blue.svg)][license]
[![](https://img.shields.io/badge/swift-compatible-orange.svg)][project]

The native implementation of UIWebView on iOS doesn't support WebP. When UIWebView renders a web page that has WebP images. It shows a placeholder and nothing else.

Well, that was the case, before you found this tool.

#Usage
Step 1: Drop [WEBPURLProtocol.h][code_h] and [WEBPURLProtocol.m][code_m] into your project, Swift or ObjC.

Step 2: If you didn't have a WebP decoder already in your project. Drop [WebP.framework][framework], [UIImage+Webp.h][ui_h], [UIImage+Webp.m][ui_m], [WEBPDemoDecoder.h][decoder_h], [WEBPDemoDecoder.m][decoder_m] into your project. If you already have a WebP decoder in your project, create a new class that conforms to [WEBPURLProtocolDecoder][protocol] using the existing decoder.

Step 3: Whenever you are in the mood for rendering WebP in UIWebView, start the engine with the following code:

`[WEBPURLProtocol registerWebP:/*An instance of any class that conforms to WEBPURLProtocolDecoder*/];`

All done.

#Special Notice: Thread Safety

Behind the scene, the code that is responsible for intercepting WebP network traffic is specially tailored for thread safety concerns. As anyone with experience dealing with NSURLProtocol would agree, thread safety can be a nasty issue once the network traffic gets heavy. You can rest assured that [WEBPURLProtocol][project] has been more than battle-tested and can be safely deployed in large scale.

#Why Not Reusing NSURLSession

A new NSURLSession instance is created for each incoming WebP request. This does seem rather wasteful. However, after much testing, it occurred that sharing a single NSURLSession instance across multiple NSURLProtocol requests would lead to random timeouts and loss of data. Until a solution is found, reusing NSURLSession is not recommended.

#Compatibility
Compatible with iOS 7.0 or above.


#Example Project
Inside this repo you can find the example project. 
#License
WEBPURLProtocol is released under the MIT license. See [LICENSE][license] for details.

[code_m]: ./Webp/WEBPURLProtocol.m
[code_h]: ./Webp/WEBPURLProtocol.h
[framework]: ./WebP.framework
[ui_m]: ./Webp/UIImage%2BWebP.m
[ui_h]: ./Webp/UIImage%2BWebP.h
[decoder_m]: ./Webp/WEBPDemoDecoder.m
[decoder_h]: ./Webp/WEBPDemoDecoder.h
[protocol]: ./Webp/WEBPURLProtocol.h#L5
[project]: https://github.com/8BADBEEF/WebpForUIWebView
[demo]: ./screenshot.jpg
[license]: ./LICENSE