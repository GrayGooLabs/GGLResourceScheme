# GGLResourceScheme

## Adds the 'rsrc:///' URL scheme to an OS X or iOS app's URL loading system, allowing direct URL access to bundle resource files.

GGLResourceScheme is a dead simple NSURLProtocol subclass that adds the `rsrc:///` URL scheme to the URL loading mechanism of an OS X or iOS app. It's not exactly rocket science, but enough people expressed amazement that this could be done that I thought I'd throw up a simple, useful example library.

### Usage

During your app's initialization, call `[GGLResourceScheme registerResourceURLScheme]`.

Then, from almost anywhere within cocoa or cocoa touch that you can use a URL, you may use an `rsrc:///BundleResourceName.ext` URL (where `BundleResourceName.ext` is the name of a file within your app's bundle resources) to gain direct access to your app's resource files.

For example, if you use a WebView for internal UI rendering, and you want to link to CSS or JavaScript files stored in your app's resources, or you want easy access to your app's images, you might load HTML that looked like this:


```html
<html>
	<head>
		<script language="javascript" src="rsrc:///common.js"></script>
		<link rel="stylesheet" type="text/css" href="rsrc:///common.css">
	</head>
	<body>
	
		<img src="rsrc:///logo.png">
	
	</body>
</html>
```

(Where `common.js`, `common.css`, and `logo.png` are all files you've included in your app's bundle resources via Xcode.)

### Installation

The easiest way to add GGLResourceScheme to you project is to simply download the `GGLResourceScheme.h` and `GGLResourceScheme.m` files from the repo, and import them into your project.

The GGLResourceScheme project itself is an Xcode project with targets to build static libraries for either OS X or iOS. An advanced user *could* add GGLResourceScheme to their project as a git submodule, and then build and link the library as a dependency, however, this is probably overkill and instructions to do so are beyond the scope of this readme.

### Three slashes

An `rsrc` can be thought of as equivalent to a `file` URL that points at your bundle's resource path instead of at the root of your drive. As with a file URL, there is no domain, only a path, (or more correctly, the domain is `localhost`) and therefor the correct format is 3 slashes after the colon. (i.e. `rsrc:///FileName.ext`) (See [This Superuser Question](http://superuser.com/questions/352133/what-is-the-reason-that-file-urls-start-with-three-slashes-file-etc) for more info on why.)

### Limitations

Under the hood, GGLResourceScheme uses the `[[NSBundle mainBundle] URLForResource:withExtension:]` method to find your bundle's resources. It should be able to find any resource that could be found by that method.

An `rsrc:///` URL simply finds the URL for the resource, and the forwards the URL loading system to the appropriate `file:///` URL. This has a few security implications. Many URL clients, including WebKit, treat `file:///` URLs as special and privileged:

In a `WebView` or `UIWebView`, a page loaded via an `http://` URL generally cannot load a local `file:///` URL. This is a desirable security feature, and the main reason `rsrc:///` URLs are designed to forward to `file:///` URls.

However, because of this security feature, in some cases URL clients will refuse to follow a redirect from a non-privileged URL to a privileged URL. In these cases, `rsrc` URLs provided by GGLResourceScheme won't work, and may fail silently. **On iOS only, a UIWebView will not allow an `rsrc:///` URL to be loaded into it's main frame.** It will still allow images, javascript, and CSS to be loaded via `rsrc` URLs, however. (This is not an issue on OS X thanks to the [WebView registerURLSchemeAsLocal:] method, which allows GGLResourceScheme to mark `rsrc` URLs themselves as privileged. Alas, no equivalent appears to exist on iOS.)

### License

GGLResourceScheme is available under a Simplified BSD License. Please see the License.txt file.

### Follow the Author

I am [@peteburtis](https://app.net/peteburtis) on app.net.
