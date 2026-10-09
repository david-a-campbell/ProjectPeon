// Small AppKit bridge for the game's image and pointer APIs. No iOS runtime required.
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreData/CoreData.h>
#define UIImage NSImage
#define UIColor NSColor
#define UIBezierPath NSBezierPath
#define UIView NSView
#define UIEvent NSEvent
#define UIImageView PeonImageView
#define UIInterfaceOrientation NSInteger
#define UIInterfaceOrientationLandscapeRight 4
#define UIInterfaceOrientationLandscapeLeft 3
#define UIUserInterfaceIdiomPad 1
#define UI_USER_INTERFACE_IDIOM() 1
#define UIImageOrientationUp 0
#define NSStringFromCGPoint NSStringFromPoint
#define CGPointFromString NSPointFromString
#define NSStringFromCGSize NSStringFromSize
#define CGSizeFromString NSSizeFromString
#define CGRectFromString NSRectFromString
#define NSStringFromCGRect NSStringFromRect
@class UITouch;
@protocol UIAccelerometerDelegate <NSObject>
@end
@interface UIAcceleration : NSObject
@property double x, y, z;
@end
@interface UIAccelerometer : NSObject
@property(assign) id delegate;
@property double updateInterval;
+ (instancetype)sharedAccelerometer;
@end
@interface UIDevice : NSObject
+ (instancetype)currentDevice;
- (NSString *)platform;
@end
@interface UIApplication : NSObject
+ (instancetype)sharedApplication;
- (id)delegate;
- (void)setIdleTimerDisabled:(BOOL)value;
- (NSInteger)statusBarOrientation;
- (CGRect)statusBarFrame;
- (BOOL)canOpenURL:(NSURL *)url;
- (BOOL)openURL:(NSURL *)url;
@end
@interface UITouch : NSObject
@property CGPoint location, previousLocation;
@property(assign) NSView *view;
@property NSUInteger tapCount;
- (CGPoint)locationInView:(NSView *)view;
- (CGPoint)previousLocationInView:(NSView *)view;
@end
@interface NSImage (PeonImage)
- (CGImageRef)CGImage;
- (instancetype)initWithCGImage:(CGImageRef)image scale:(CGFloat)scale orientation:(NSInteger)orientation;
@end
@interface PeonImageView : NSImageView
@property CGPoint center;
- (instancetype)initWithImage:(NSImage *)image;
- (void)setUserInteractionEnabled:(BOOL)enabled;
@end
@interface NSView (PeonView)
- (void)setMultipleTouchEnabled:(BOOL)enabled;
@end
@interface NSValue (PeonGeometry)
+ (instancetype)valueWithCGPoint:(CGPoint)point;
+ (instancetype)valueWithCGSize:(CGSize)size;
- (CGPoint)CGPointValue;
- (CGSize)CGSizeValue;
@end
void UIGraphicsBeginImageContext(CGSize size);
NSImage *UIGraphicsGetImageFromCurrentImageContext(void);
void UIGraphicsEndImageContext(void);
CGContextRef UIGraphicsGetCurrentContext(void);
NSData *UIImagePNGRepresentation(NSImage *image);

@protocol CCTouchDelegate <NSObject>
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
@end
#define UIScreen NSScreen
@interface NSScreen (PeonScreen)
- (CGFloat)scale;
@end
#define kCCResolutioniPadRetinaDisplay kCCResolutionMacRetinaDisplay
