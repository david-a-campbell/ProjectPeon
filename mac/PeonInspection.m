#import "PeonInspection.h"
#import <OpenGL/gl.h>
static NSString *requestedPath;
void PeonRequestScreenshot(NSString *path) {
    [requestedPath release]; requestedPath=[path copy];
}
BOOL PeonCaptureScreenshot(NSString *path) {
    GLint viewport[4], pack, readBuffer;
    glGetIntegerv(GL_VIEWPORT,viewport);
    glGetIntegerv(GL_PACK_ALIGNMENT,&pack);
    glGetIntegerv(GL_READ_BUFFER,&readBuffer);
    NSInteger w=viewport[2],h=viewport[3];
    if(w<=0 || h<=0) return NO;
    NSMutableData *pixels=[NSMutableData dataWithLength:w*h*4];
    glPixelStorei(GL_PACK_ALIGNMENT,1);
    glReadPixels(viewport[0],viewport[1],(GLsizei)w,(GLsizei)h,GL_RGBA,GL_UNSIGNED_BYTE,pixels.mutableBytes);
    glPixelStorei(GL_PACK_ALIGNMENT,pack);
    glReadBuffer(readBuffer);
    NSBitmapImageRep *image=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:w pixelsHigh:h bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:w*4 bitsPerPixel:32] autorelease];
    for(NSInteger y=0;y<h;y++) memcpy(image.bitmapData+y*w*4,(char *)pixels.bytes+(h-1-y)*w*4,w*4);
    return [[image representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToFile:path atomically:YES];
}
void PeonCaptureRequestedScreenshot(void) {
    if(!requestedPath) return;
    if(!PeonCaptureScreenshot(requestedPath)) NSLog(@"Unable to save camera screenshot: %@",requestedPath);
    [requestedPath release]; requestedPath=nil;
}
