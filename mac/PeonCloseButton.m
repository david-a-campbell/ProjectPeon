#import "PeonCloseButton.h"
#import "PeonMac.h"
@implementation PeonCloseMenu
-(void)registerWithTouchDispatcher {
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:self.closePriority swallowsTouches:YES];
}
@end

static void PeonFindCloseMenu(CCNode *node, PeonCloseMenu **best) {
    if(!node || !node.visible) return;
    if([node isKindOfClass:[PeonCloseMenu class]]) {
        PeonCloseMenu *menu=(PeonCloseMenu *)node;
        CCMenuItem *button=(CCMenuItem *)[menu getChildByTag:9905];
        if(menu.isRunning && menu.isTouchEnabled && button.isEnabled &&
           (!*best || menu.closePriority<=(*best).closePriority)) *best=menu;
    }
    for(CCNode *child in node.children) PeonFindCloseMenu(child,best);
}
BOOL PeonDismissOpenMenu(void) {
    PeonCloseMenu *menu=nil;
    CCDirector *director=[CCDirector sharedDirector];
    PeonFindCloseMenu(director.runningScene,&menu);
    PeonFindCloseMenu(director.notificationNode,&menu);
    if(!menu) return NO;
    CCMenuItem *button=(CCMenuItem *)[menu getChildByTag:9905];
    [button unselected];
    [button activate];
    return YES;
}
