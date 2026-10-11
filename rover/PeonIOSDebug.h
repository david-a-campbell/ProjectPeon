#import "cocos2d.h"
#ifdef PROJECTPEON_IOS
@interface PeonIOSDebugLayer : CCLayer {
    CCMenu *debugEntry;
    CCLayerColor *debugBacking;
    CCMenu *levelNavigation;
    CCLayerColor *navigationBacking;
    BOOL navigatingLevel;
    CCLabelTTF *toast;
    CCLayerColor *toastBacking;
    UITouch *panTouch;
    CGPoint previousPanPoint;
}
-(void)toggleDebug:(NSNotification *)notification;
-(void)openDebug;
-(void)optionsChanged;
@end
static inline void PeonIOSDebugAttach(CCNode *scene) {
    if (![scene getChildByTag:9930]) {
        PeonIOSDebugLayer *layer=[PeonIOSDebugLayer node];
        layer.tag=9930;
        [scene addChild:layer z:2000000];
    }
}
#endif
