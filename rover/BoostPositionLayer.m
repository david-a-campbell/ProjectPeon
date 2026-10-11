#import "BoostPositionLayer.h"
#ifdef PROJECTPEON_IOS
#import "SaveManager.h"
#import "Constants.h"
#import "PeonBoostPlacement.h"
#import "../mac/PeonBitmapFont.h"
#import "PeonUIAudit.h"
#if PEON_DEVELOPMENT_AUDIT
@interface PeonPlacementAuditTouch : NSObject
@property CGPoint location;
-(CGPoint)locationInView:(UIView *)view;
-(UIView *)view;
@end
@implementation PeonPlacementAuditTouch
-(CGPoint)locationInView:(UIView *)view { return self.location; }
-(UIView *)view { return nil; }
@end
#endif

@interface BoostPositionLayer () {
    CCNode *boost;
    CCSprite *normalBoost;
    CCSprite *pressedBoost;
    NSMutableArray *hiddenNodes;
    UITouch *dragTouch;
    CGPoint dragOffset;
    CGPoint dragStart;
    BOOL previousStats;
    BOOL restored;
}
@end

@implementation BoostPositionLayer
+(void)show {
    CCScene *scene=[CCDirector sharedDirector].runningScene;
    if (!scene || [scene getChildByTag:9940]) return;
    BoostPositionLayer *layer=[BoostPositionLayer node];
    [scene addChild:layer z:INT_MAX tag:9940];
}
-(id)init {
    if ((self=[super init])) {
        CCDirector *director=[CCDirector sharedDirector];
        // Title settings can open this before a level has loaded the controls atlas.
        CCSpriteFrameCache *frames=[CCSpriteFrameCache sharedSpriteFrameCache];
        if (![frames spriteFrameByName:@"controlBoost1.png"] || ![frames spriteFrameByName:@"controlBoost2.png"])
            [frames addSpriteFramesWithFile:@"menuItemsAtlas.plist"];
        CGSize size=director.winSize;
        CGRect bounds=PeonBoostBounds(size);
        hiddenNodes=[[NSMutableArray alloc] init];
        for (CCNode *node in director.runningScene.children) {
            [hiddenNodes addObject:@[node,@(node.visible)]];
            node.visible=NO;
        }
        previousStats=director.displayStats;
        director.displayStats=NO;
        CCSprite *grid=[CCSprite spriteWithFile:@"MenuGridWide.png"];
        grid.position=ccp(CGRectGetMidX(bounds),CGRectGetMidY(bounds));
        grid.scaleX=bounds.size.width/grid.contentSize.width;
        grid.scaleY=bounds.size.height/grid.contentSize.height;
        [self addChild:grid z:-1];
        boost=[CCNode node];
        normalBoost=[CCSprite spriteWithSpriteFrameName:@"controlBoost1.png"];
        pressedBoost=[CCSprite spriteWithSpriteFrameName:@"controlBoost2.png"];
        normalBoost.scale=pressedBoost.scale=SCREEN_SCALE;
        pressedBoost.visible=NO;
        [boost addChild:normalBoost]; [boost addChild:pressedBoost];
        boost.position=[[SaveManager sharedManager] boostButtonPositionForSize:size];
        [self addChild:boost];
        CCMenuItemLabel *save=[self textButton:@"Save" action:@selector(savePosition) color:ccc3(70,255,90)];
        CCMenuItemLabel *reset=[self textButton:@"Reset" action:@selector(resetPosition) color:ccWHITE];
        save.position=ccp(CGRectGetMaxX(bounds)-24-save.contentSize.width/2,size.height-24-save.contentSize.height/2);
        reset.position=ccp(CGRectGetMinX(bounds)+24+reset.contentSize.width/2,save.position.y);
        CCMenu *menu=[CCMenu menuWithItems:reset,save,nil];
        menu.position=CGPointZero; menu.touchPriority=-3001;
        [self addChild:menu];
        self.touchEnabled=YES;
    }
    return self;
}
-(CCMenuItemLabel *)textButton:(NSString *)text action:(SEL)action color:(ccColor3B)color {
    CCLabelBMFont *label=[CCLabelBMFont labelWithString:text fntFile:@"font52.fnt"];
    PeonInsetBitmapGlyphs(label); label.scale=SCREEN_SCALE*1.2; label.color=color;
    // CCMenuItemLabel supplies the same selected/unselected zoom as other menu buttons.
    CCMenuItemLabel *item=[CCMenuItemLabel itemWithLabel:label target:self selector:action];
    item.contentSize=CGSizeMake(label.contentSize.width*label.scale+48,96);
    label.anchorPoint=ccp(.5,.5);
    label.position=ccp(item.contentSize.width/2,item.contentSize.height/2);
    return item;
}
-(void)savePosition {
    [[SaveManager sharedManager] saveBoostButtonPosition:boost.position forSize:[CCDirector sharedDirector].winSize];
    [self removeFromParentAndCleanup:YES];
}
-(void)resetPosition {
    [self finishDrag];
    boost.position=PeonDefaultBoostPosition([CCDirector sharedDirector].winSize);
}
-(void)finishDrag {
    [dragTouch release]; dragTouch=nil;
    normalBoost.visible=YES; pressedBoost.visible=NO;
}
-(void)registerWithTouchDispatcher {
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-3000 swallowsTouches:YES];
}
-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    if (!dragTouch) {
        CGPoint point=[self convertTouchToNodeSpace:touch];
        if (ccpDistance(point,boost.position)<=58.75) {
            dragTouch=[touch retain]; dragStart=boost.position;
            dragOffset=ccpSub(boost.position,point);
            normalBoost.visible=NO; pressedBoost.visible=YES;
        }
    }
    return YES; // Block every underlying control, including taps on empty grid.
}
-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    if (touch==dragTouch)
        boost.position=PeonClampBoostPosition(ccpAdd([self convertTouchToNodeSpace:touch],dragOffset),[CCDirector sharedDirector].winSize);
}
-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    if (touch==dragTouch) [self finishDrag];
}
-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
    if (touch==dragTouch) { boost.position=dragStart; [self finishDrag]; }
}
-(void)onExit {
    [self finishDrag];
    if (!restored) {
        for (NSArray *entry in hiddenNodes) [(CCNode *)entry[0] setVisible:[entry[1] boolValue]];
        [CCDirector sharedDirector].displayStats=previousStats;
        restored=YES;
    }
    [super onExit];
}
#if PEON_DEVELOPMENT_AUDIT
-(void)debugAuditPositioning {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    id oldPosition=[[defaults objectForKey:@"PeonBoostButtonPosition"] retain];
    id oldSide=[[defaults objectForKey:@"PeonBoostButtonOnRight"] retain];
    SaveManager *save=[SaveManager sharedManager];
    CGSize size=[CCDirector sharedDirector].winSize;
    @try {
        [defaults removeObjectForKey:@"PeonBoostButtonPosition"];
        [defaults removeObjectForKey:@"PeonBoostButtonOnRight"];
        CGPoint start=PeonDefaultBoostPosition(size);
        NSCAssert(ccpDistance([save boostButtonPositionForSize:size],start)<.01,@"Fresh install must use left margin");
        boost.position=start;
        PeonPlacementAuditTouch *touch=[[[PeonPlacementAuditTouch alloc] init] autorelease];
        touch.location=[[CCDirector sharedDirector] convertToUI:ccpAdd(start,ccp(10,10))];
        [self ccTouchBegan:(UITouch *)touch withEvent:nil];
        NSCAssert(pressedBoost.visible && !normalBoost.visible,@"Boost pressed state missing");
        touch.location=[[CCDirector sharedDirector] convertToUI:ccpAdd(start,ccp(310,210))];
        [self ccTouchMoved:(UITouch *)touch withEvent:nil];
        CGPoint moved=ccpAdd(start,ccp(300,200));
        NSCAssert(ccpDistance(boost.position,moved)<.01,@"Drag jumped or lost offset");
        [self ccTouchEnded:(UITouch *)touch withEvent:nil];
        NSCAssert(normalBoost.visible && !pressedBoost.visible,@"Boost did not release");
        [save saveBoostButtonPosition:boost.position forSize:size];
        NSCAssert(ccpDistance([save boostButtonPositionForSize:size],moved)<.01,@"Saved position did not reload");
        NSDictionary *normalized=[defaults dictionaryForKey:@"PeonBoostButtonPosition"];
        CGSize other=CGSizeMake(1280,720); CGRect otherBounds=PeonBoostBounds(other);
        CGPoint expected=ccp(otherBounds.origin.x+[normalized[@"x"] doubleValue]*otherBounds.size.width,[normalized[@"y"] doubleValue]*other.height);
        NSCAssert(ccpDistance([save boostButtonPositionForSize:other],expected)<.01,@"Position changed after viewport resize");
        [self resetPosition];
        NSCAssert(ccpDistance(boost.position,start)<.01,@"Reset did not restore left default");
        touch.location=[[CCDirector sharedDirector] convertToUI:start];
        [self ccTouchBegan:(UITouch *)touch withEvent:nil];
        touch.location=[[CCDirector sharedDirector] convertToUI:ccp(10000,-10000)];
        [self ccTouchMoved:(UITouch *)touch withEvent:nil];
        NSCAssert(ccpDistance(boost.position,PeonClampBoostPosition(ccp(10000,-10000),size))<.01,@"Boost can be dragged offscreen");
        [self ccTouchCancelled:(UITouch *)touch withEvent:nil];
        NSCAssert(ccpDistance(boost.position,start)<.01 && normalBoost.visible,@"Cancelled drag did not recover");
        fprintf(stderr,"PEON_BOOST_POSITION_AUDIT_PASS: default, drag, pressed state, persistence, resize, reset, bounds, cancellation\n");
    } @finally {
        if(oldPosition) [defaults setObject:oldPosition forKey:@"PeonBoostButtonPosition"]; else [defaults removeObjectForKey:@"PeonBoostButtonPosition"];
        if(oldSide) [defaults setObject:oldSide forKey:@"PeonBoostButtonOnRight"]; else [defaults removeObjectForKey:@"PeonBoostButtonOnRight"];
        [oldPosition release]; [oldSide release];
        boost.position=[save boostButtonPositionForSize:size];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CONTROL_TYPE_CHANGED object:nil];
    }
}
#endif
-(void)dealloc {
    [dragTouch release]; [hiddenNodes release];
    [super dealloc];
}
@end
#endif
