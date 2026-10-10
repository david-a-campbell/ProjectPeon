#import "cocos2d.h"

@interface PeonCloseMenu : CCMenu
@property(nonatomic) NSInteger closePriority;
@end

BOOL PeonDismissOpenMenu(void);

// Use the same normal/selected sprite and tracking behavior as other game buttons.
static void PeonAddCloseButton(CCSprite *frame, BOOL wide, id target, SEL action, NSInteger priority) {
    CCSprite *up = [CCSprite spriteWithFile:@"MenuClose.png"];
    CCSprite *down = [CCSprite spriteWithFile:@"MenuCloseDown.png"];
    CCMenuItemSprite *button = [CCMenuItemSprite itemWithNormalSprite:up selectedSprite:down target:target selector:action];
    button.scale = 24.0 / button.contentSize.width;
    frame.flipX = YES;
    CGFloat xRatio = 1.0 - (wide ? 227.0 / 839.0 : 117.0 / 623.0);
    button.position = ccp(frame.contentSize.width * xRatio, frame.contentSize.height * 28.0 / 48.0);
    button.tag = 9905;
    PeonCloseMenu *menu = [PeonCloseMenu menuWithItems:button, nil];
    menu.position = CGPointZero;
    menu.closePriority = priority;
    frame.cascadeOpacityEnabled = YES;
    menu.cascadeOpacityEnabled = YES;
    [frame addChild:menu z:10 tag:9906];
}

static void PeonDisableCloseButton(CCSprite *frame) {
    CCMenu *menu = (CCMenu *)[frame getChildByTag:9906];
    CCMenuItem *button = (CCMenuItem *)[menu getChildByTag:9905];
    [button unselected];
    [button setIsEnabled:NO];
    [menu setTouchEnabled:NO];
}
