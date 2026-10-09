#import "cocos2d.h"
// Continue the flat landscape sky at each edge without changing its original center.
static inline CCNode *PeonLandscapeSkybox(CCSprite *source) {
    CCNode *sky=[CCNode node];
    sky.anchorPoint=ccp(0,0);
    sky.contentSize=source.contentSize;
    sky.scaleX=source.scaleX; sky.scaleY=source.scaleY;
    CGRect rectangles[]={CGRectMake(128,0,128,576),CGRectMake(128,0,768,576),CGRectMake(768,0,128,576)};
    CGFloat positions[]={0,128,896};
    for(int i=0;i<3;i++) {
        CCSprite *part=[CCSprite spriteWithTexture:source.texture rect:rectangles[i]];
        part.anchorPoint=ccp(0,0); part.position=ccp(positions[i],0);
        part.flipX=(i!=1);
        [sky addChild:part];
    }
    return sky;
}
