#import "PeonMac.h"
#import "PeonViewport.h"
@implementation UIAcceleration
@end
@implementation UIAccelerometer
+ (instancetype)sharedAccelerometer { static id value; if (!value) value = [self new]; return value; }
@end
@implementation UIDevice
+ (instancetype)currentDevice { static id value; if (!value) value = [self new]; return value; }
- (NSString *)platform { return @"Mac"; }
@end
@implementation UIApplication
+ (instancetype)sharedApplication { static id value; if (!value) value = [self new]; return value; }
- (id)delegate { return NSApp.delegate; }
- (void)setIdleTimerDisabled:(BOOL)value {}
- (NSInteger)statusBarOrientation { return UIInterfaceOrientationLandscapeLeft; }
- (CGRect)statusBarFrame { return CGRectZero; }
- (BOOL)canOpenURL:(NSURL *)url { return [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:url] != nil; }
- (BOOL)openURL:(NSURL *)url { return [[NSWorkspace sharedWorkspace] openURL:url]; }
@end
@implementation UITouch
- (CGPoint)locationInView:(NSView *)view { return _location; }
- (CGPoint)previousLocationInView:(NSView *)view { return _previousLocation; }
@end
@implementation NSImage (PeonImage)
- (CGImageRef)CGImage { return [self CGImageForProposedRect:NULL context:nil hints:nil]; }
- (instancetype)initWithCGImage:(CGImageRef)image scale:(CGFloat)scale orientation:(NSInteger)orientation {
    return [self initWithCGImage:image size:NSMakeSize(CGImageGetWidth(image)/scale, CGImageGetHeight(image)/scale)];
}
@end
@implementation PeonImageView
- (instancetype)initWithImage:(NSImage *)image {
    if ((self = [super initWithFrame:NSMakeRect(0,0,image.size.width,image.size.height)])) { self.image = image; self.wantsLayer = YES; }
    return self;
}
- (void)setUserInteractionEnabled:(BOOL)enabled {}
- (CGPoint)center { return NSMakePoint(NSMidX(self.frame), NSMidY(self.frame)); }
- (void)setCenter:(CGPoint)p { [self setFrameOrigin:NSMakePoint(p.x-self.frame.size.width/2,p.y-self.frame.size.height/2)]; }
@end
@implementation NSView (PeonView)
- (void)setMultipleTouchEnabled:(BOOL)enabled {}
@end
@implementation NSValue (PeonGeometry)
+ (instancetype)valueWithCGPoint:(CGPoint)point { return [self valueWithPoint:point]; }
+ (instancetype)valueWithCGSize:(CGSize)size { return [self valueWithSize:size]; }
- (CGPoint)CGPointValue { return self.pointValue; }
- (CGSize)CGSizeValue { return self.sizeValue; }
@end
static __thread NSImage *drawingImage;
void UIGraphicsBeginImageContext(CGSize size) {
    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL pixelsWide:(NSInteger)size.width pixelsHigh:(NSInteger)size.height
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:32] autorelease];
    drawingImage = [[NSImage alloc] initWithSize:size];
    [drawingImage addRepresentation:bitmap];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
}
NSImage *UIGraphicsGetImageFromCurrentImageContext(void) { return drawingImage; }
void UIGraphicsEndImageContext(void) {
    [NSGraphicsContext restoreGraphicsState];
    [drawingImage autorelease]; drawingImage = nil;
}
CGContextRef UIGraphicsGetCurrentContext(void) { return [[NSGraphicsContext currentContext] CGContext]; }
NSData *UIImagePNGRepresentation(NSImage *image) {
    NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithCGImage:image.CGImage] autorelease];
    return [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
}
@implementation CCDirector (PeonPointer)
- (CCTouchDispatcher *)touchDispatcher { static id dispatcher; if (!dispatcher) dispatcher = [CCTouchDispatcher new]; return dispatcher; }
@end
@implementation CCRenderTexture (PeonImage)
- (NSImage *)getUIImage { CGImageRef cg = [self newCGImage]; NSImage *image = [[[NSImage alloc] initWithCGImage:cg size:NSZeroSize] autorelease]; CGImageRelease(cg); return image; }
@end

@implementation NSScreen (PeonScreen)
- (CGFloat)scale { return self.backingScaleFactor; }
@end
@implementation CCDirectorMac (PeonCoordinates)
- (CGPoint)convertToGL:(CGPoint)point { return [self convertToLogicalCoordinates:point]; }
- (CGPoint)convertToUI:(CGPoint)point { CGSize size=self.winSize; return PeonViewPoint(point, PeonGameViewport(self.view.bounds, size), size); }
@end
