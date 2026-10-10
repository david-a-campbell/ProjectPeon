#import "PeonCloseButton.h"
#import "PeonMac.h"
#import "SaveMenu.h"
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
static SaveMenu *PeonFindSaveMenu(CCNode *node) {
    if(!node || !node.visible) return nil;
    for(NSInteger index=node.children.count-1;index>=0;index--) {
        CCNode *child=[node.children objectAtIndex:index];
        SaveMenu *menu=PeonFindSaveMenu(child);
        if(menu) return menu;
    }
    if(node.isRunning && [node isKindOfClass:[SaveMenu class]] &&
       [(SaveMenu *)node isMenuDisplaying]) return (SaveMenu *)node;
    return nil;
}
BOOL PeonDismissOpenMenu(void) {
    PeonCloseMenu *menu=nil;
    CCDirector *director=[CCDirector sharedDirector];
    PeonFindCloseMenu(director.runningScene,&menu);
    PeonFindCloseMenu(director.notificationNode,&menu);
    if(!menu) {
        SaveMenu *save=PeonFindSaveMenu(director.notificationNode);
        if(!save) save=PeonFindSaveMenu(director.runningScene);
        return [save dismissFromKeyboard];
    }
    CCMenuItem *button=(CCMenuItem *)[menu getChildByTag:9905];
    [button unselected];
    [button activate];
    return YES;
}
