#import "cocos2d.h"
#import "SaveMenu.h"
#import "SaveMenuItem.h"
#import "SWScrollView.h"
#import "PeonWideScreen.h"

BOOL PeonKeyDown(unsigned short code) { return NO; }
@interface SaveMenu (InputTest)
-(void)setupScrollview;
-(void)setHandlerPriorities;
-(void)enableAllMenuItems;
@end
@interface InputItem : SaveMenuItem
@property NSInteger activations;
@end
@implementation InputItem
-(void)saveCart { self.activations++; }
-(void)expandView { self.activations++; }
@end
@interface InputView : NSObject
@property(retain) NSOpenGLContext *openGLContext;
@property(retain) NSOpenGLPixelFormat *pixelFormat;
@end
@implementation InputView
-(NSRect)bounds { return NSMakeRect(0,0,1365.333333,768); }
-(NSRect)convertRectToBacking:(NSRect)rect { return rect; }
-(NSUInteger)depthFormat { return 0; }
-(void)setEventDelegate:(id)delegate {}
-(void)setAcceptsTouchEvents:(BOOL)value {}
-(void)lockOpenGLContext {}
-(void)unlockOpenGLContext {}
@end
static UITouch *press(CCNode *node, CGPoint local) {
    UITouch *touch=[[[UITouch alloc] init] autorelease];
    touch.location=[[CCDirector sharedDirector] convertToUI:[node convertToWorldSpace:local]];
    return touch;
}
static void move(UITouch *touch, CCNode *node, CGPoint local) {
    touch.location=[[CCDirector sharedDirector] convertToUI:[node convertToWorldSpace:local]];
    [[[CCDirector sharedDirector] touchDispatcher] touchesMoved:[NSSet setWithObject:touch] withEvent:nil];
}
int main(int argc,const char **argv) {
 @autoreleasepool {
    CGLPixelFormatAttribute attributes[]={kCGLPFAAllowOfflineRenderers,0};
    CGLPixelFormatObj format; CGLContextObj context; GLint count;
    NSCAssert(CGLChoosePixelFormat(attributes,&format,&count)==kCGLNoError,@"Pixel format");
    NSCAssert(CGLCreateContext(format,NULL,&context)==kCGLNoError,@"Context");
    CGLDestroyPixelFormat(format); CGLSetCurrentContext(context);
    InputView *view=[[[InputView alloc] init] autorelease];
    NSOpenGLPixelFormatAttribute nativeAttributes[]={NSOpenGLPFAAllowOfflineRenderers,0};
    view.pixelFormat=[[[NSOpenGLPixelFormat alloc] initWithAttributes:nativeAttributes] autorelease];
    view.openGLContext=[[[NSOpenGLContext alloc] initWithCGLContextObj:context] autorelease];
    CCDirector *director=[CCDirector sharedDirector];
    [director setView:(CCGLView *)view];
    [[PeonWideScreen sharedPresentation] setCartCreation:YES];
    [CCFileUtils sharedFileUtils].searchPath=@[@(argv[1])];
    [CCFileUtils sharedFileUtils].enableFallbackSuffixes=NO;
    for(NSString *atlas in @[@"menuItemsAtlas.plist",@"popupBacking.plist"])
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:atlas];
    UIImage *image=[[[UIImage alloc] initWithContentsOfFile:[@(argv[1]) stringByAppendingPathComponent:@"MenuGridWide.png"]] autorelease];
    InputItem *cart=[[[InputItem alloc] initWithImage:image andIndex:0] autorelease];
    InputItem *save=[[[InputItem alloc] initAsSaveItem] autorelease];
    SaveMenu *menu=[SaveMenu node];
    [menu setValue:[NSMutableArray arrayWithObjects:cart,save,nil] forKey:@"saveMenuItemList"];
    [menu setupScrollview];
    [menu enableAllMenuItems];
    menu.touchEnabled=YES;
    CCNode *root=[CCNode node]; root.position=ccp(31,9); root.scale=.75;
    [root addChild:menu]; [root onEnter]; [menu setHandlerPriorities];
    SWScrollView *scroll=[menu valueForKey:@"scrollview"];
    scroll.contentSize=CGSizeMake(scroll.viewSize.width+500,146);
    CCTouchDispatcher *dispatcher=director.touchDispatcher;
    dispatcher.dispatchEvents=YES;
    for(InputItem *item in @[save,cart]) {
        CCMenuItem *button=[item valueForKey:@"button"];
        CGPoint local=[button convertToWorldSpace:ccp(button.contentSize.width/2,button.contentSize.height/2)];
        local=[scroll convertToNodeSpace:local];
        for(NSNumber *jitter in @[@0,@3,@8]) {
            NSInteger before=item.activations;
            UITouch *touch=press(scroll,local);
            [dispatcher touchesBegan:[NSSet setWithObject:touch] withEvent:nil];
            move(touch,scroll,ccp(local.x+jitter.doubleValue,local.y+2));
            [dispatcher touchesEnded:[NSSet setWithObject:touch] withEvent:nil];
            NSCAssert(item.activations==before+1,@"Save/cart tap lost to small movement");
        }
        NSInteger before=item.activations;
        CGPoint offset=scroll.contentOffset;
        UITouch *drag=press(scroll,local);
        [dispatcher touchesBegan:[NSSet setWithObject:drag] withEvent:nil];
        move(drag,scroll,ccp(local.x-30,local.y));
        NSCAssert(scroll.contentOffset.x<offset.x,@"Real drag did not scroll");
        [dispatcher touchesEnded:[NSSet setWithObject:drag] withEvent:nil];
        NSCAssert(item.activations==before,@"Dragging activated a cart/save action");
        // A cancelled drag must not leave the row permanently disabled.
        local.x-=30;
        UITouch *cancel=press(scroll,local);
        [dispatcher touchesBegan:[NSSet setWithObject:cancel] withEvent:nil];
        move(cancel,scroll,ccp(local.x-30,local.y));
        [dispatcher touchesCancelled:[NSSet setWithObject:cancel] withEvent:nil];
        NSCAssert(button.isEnabled,@"Cancelled scroll left buttons disabled");
        local.x-=30;
        UITouch *retry=press(scroll,local);
        [dispatcher touchesBegan:[NSSet setWithObject:retry] withEvent:nil];
        move(retry,scroll,ccp(local.x,local.y+8));
        [dispatcher touchesEnded:[NSSet setWithObject:retry] withEvent:nil];
        NSCAssert(item.activations==before+1,@"Tap after cancelled drag failed");
    }
    // Scrolled-out items must not intercept touches outside the clipped strip.
    scroll.contentOffset=ccp(-400,0);
    UITouch *outside=press(save,CGPointZero);
    NSCAssert(![save ccTouchBegan:outside withEvent:nil],@"Hidden save item stole outside tap");
    [root onExit]; [root cleanup];
    puts("Save and cart taps, jitter, dragging, cancellation, transformed bounds and clipping: PASS");
 }
 return 0;
}
