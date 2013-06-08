//
//  GLBundleResourceURLScheme.m
//  GLBundleResourceURLScheme
//
//  Created by Peter on 6/1/13.
/*
 Copyright (c) 2013, Gray Goo Labs & Pete Burtis
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#import "GGLResourceScheme.h"

#define GL_BUNDLE_RESOURCE_URL_SCHEME_DEFAULT_SCHEME @"rsrc"

NSString * const GGLResourceSchemeErrorDomain = @"GGLResourceSchemeErrorDomain";

@implementation GGLResourceScheme

NSString *GGLResourceSchemeCustomSchemeName = nil;

#pragma mark - Public API

+(void)registerResourceURLScheme
{
    [self registerClass:self];

    /*
     Don't assume WebKit is linked here... Class may be copied into a project that doesn't use WebKit.
    */
    #ifdef TARGET_OS_MAC
    Class webKitClass = NSClassFromString(@"WebView");
    if (webKitClass) {
        [webKitClass performSelector:@selector(registerURLSchemeAsLocal:) withObject:[self resourceURLSchemeName]];
    }
    #endif
}

+(void)unregisterResourceURLScheme
{
    [self unregisterClass:self];
}

+(void)setResourceURLSchemeName:(NSString *)schemeName
{
    GGLResourceSchemeCustomSchemeName = schemeName;
}

+(NSString *)resourceURLSchemeName
{
    if (GGLResourceSchemeCustomSchemeName == nil) {
        GGLResourceSchemeCustomSchemeName = GL_BUNDLE_RESOURCE_URL_SCHEME_DEFAULT_SCHEME;
    }
    return GGLResourceSchemeCustomSchemeName;
}

#pragma mark - NSURLProtocol Overrides

+(BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSURL *requestURL = request.URL;
    NSString *scheme = requestURL.scheme;
    return ([[self resourceURLSchemeName] caseInsensitiveCompare:scheme] == NSOrderedSame);
}

+(NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSURL *canonicalURL = [[NSURL alloc] initWithScheme:[self resourceURLSchemeName] host:nil path:request.URL.path];
    return [NSURLRequest requestWithURL:canonicalURL];
}

-(void)startLoading
{
    NSURL *requestURL = self.request.URL;
    NSString *path = requestURL.path;
    NSArray *pathComponents = path.pathComponents;
    
    /* 
     Look for 2 path components. First one is '/', second one is the file name.
     */
    if (pathComponents.count != 2) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%1$@ URLs must be in the format %1$@:///ResourceName.ext", [[self class] resourceURLSchemeName]]};
        NSError *error = [NSError errorWithDomain:GGLResourceSchemeErrorDomain
                                             code:1
                                         userInfo:userInfo];
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }
    
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:pathComponents[1] withExtension:nil];
    if ( ! fileURL) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Resource file '%@' not found.", pathComponents[1]]};
        NSError *error = [NSError errorWithDomain:GGLResourceSchemeErrorDomain
                                             code:2
                                         userInfo:userInfo];
        [self.client URLProtocol:self didFailWithError:error];
        return;
    }
    
    NSURLRequest *fileRequest = [NSURLRequest requestWithURL:fileURL];
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:requestURL MIMEType:nil expectedContentLength:0 textEncodingName:nil];
    
    [self.client URLProtocol:self wasRedirectedToRequest:fileRequest redirectResponse:response];
    [self.client URLProtocolDidFinishLoading:self];
}

-(void)stopLoading
{}

@end
