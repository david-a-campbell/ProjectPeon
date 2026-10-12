#import "cocos2d.h"

// Use the visible tutorial lettering, excluding its transparent touch padding.
// Match the header gap above and below it, then center the panel contents.
static int PeonSpaceTutorial(NSArray *nodes, CCMenuItem *tutorial,
                            CGFloat musicTop, CGFloat lastRowBottom, int oldPlanks) {
    CGFloat gap=oldPlanks*9.0-musicTop;
    CGFloat tutorialHeight=26.0*tutorial.scale;
    CGFloat groupHeight=musicTop-lastRowBottom;
    int planks=(int)ceil((groupHeight+tutorialHeight+3*gap)/18.0);
    gap=(planks*18.0-groupHeight-tutorialHeight)/3.0;
    tutorial.position=ccp(tutorial.position.x,lastRowBottom-gap-tutorialHeight/2);
    CGFloat offset=planks*9.0-gap-musicTop;
    for(CCNode *node in nodes) node.position=ccp(node.position.x,node.position.y+offset);
    return planks;
}
