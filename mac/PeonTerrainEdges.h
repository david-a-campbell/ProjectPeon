#import <Cocoa/Cocoa.h>
#import "cocos2d.h"

// Transparent padding is part of the texture, but is not a usable tile join.
static inline CGRect PeonTerrainVisibleRectWithMinimum(NSString *file, CGRect fallback, size_t minimumPixels) {
    NSString *path=[[CCFileUtils sharedFileUtils] fullPathFromRelativePath:file];
    NSImage *image=[[[NSImage alloc] initWithContentsOfFile:path] autorelease];
    CGImageRef source=[image CGImageForProposedRect:NULL context:nil hints:nil];
    if(!source) return fallback;
    size_t width=CGImageGetWidth(source),height=CGImageGetHeight(source);
    unsigned char *pixels=(unsigned char *)calloc(width*height,4);
    CGColorSpaceRef color=CGColorSpaceCreateDeviceRGB();
    CGContextRef context=CGBitmapContextCreate(pixels,width,height,8,width*4,color,
        kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(color);
    if(!context) { free(pixels); return fallback; }
    CGContextDrawImage(context,CGRectMake(0,0,width,height),source);
    size_t first=width,last=0;
    for(size_t x=0;x<width;x++) {
        size_t occupied=0;
        for(size_t y=0;y<height;y++) if(pixels[(y*width+x)*4+3]) occupied++;
        // Ignore the thin ground tail left beyond a cropped tree canopy.
        if(occupied>=MAX((size_t)1,minimumPixels)) { first=MIN(first,x); last=MAX(last,x); }
    }
    CGContextRelease(context); free(pixels);
    if(first==width) return fallback;
    return CGRectMake(first,0,last-first+1,height);
}

static inline CGRect PeonTerrainVisibleRect(NSString *file, CGRect fallback) {
    return PeonTerrainVisibleRectWithMinimum(file,fallback,(size_t)fallback.size.height/20);
}
