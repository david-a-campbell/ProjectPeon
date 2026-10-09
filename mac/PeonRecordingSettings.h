#import "cocos2d.h"
#import "PeonRecorder.h"
#import "CCControlExtension.h"
static CCNode<CCRGBAProtocol> *PeonRecordingSwitchSprite(BOOL enabled, BOOL pressed, CGFloat scale) {
    CCNodeRGBA *container=[CCNodeRGBA node]; container.contentSize=CGSizeMake(210,26);
    container.cascadeOpacityEnabled=YES;
    unsigned char pixel[]={255,255,255,255};
    CCTexture2D *texture=[[[CCTexture2D alloc] initWithData:pixel pixelFormat:kCCTexture2DPixelFormat_RGBA8888 pixelsWide:1 pixelsHigh:1 contentSize:CGSizeMake(1,1)] autorelease];
    CCSprite *frame=[CCSprite spriteWithTexture:texture];
    frame.scaleX=210; frame.scaleY=26; frame.position=ccp(105,13); frame.color=ccc3(210,240,255);
    [container addChild:frame];
    CCSprite *inset=[CCSprite spriteWithTexture:texture];
    inset.scaleX=204; inset.scaleY=20; inset.position=ccp(105,13);
    inset.color=pressed ? ccc3(45,110,145) : (enabled ? ccc3(25,95,130) : ccc3(8,30,48));
    [container addChild:inset];
    CCLabelBMFont *text=[CCLabelBMFont labelWithString:enabled ? @"ON" : @"OFF" fntFile:@"font52.fnt"];
    text.scale=scale*0.75; text.position=ccp(105,13); [container addChild:text];
    return container;
}
static void PeonAddRecordingSetting(NSMutableArray *nodes, CGFloat scale) {
    CCSprite *label=[CCSprite spriteWithFile:@"RecordGameplayLabel.png"];
    label.anchorPoint=ccp(0,0.5); label.scale=scale; label.position=ccp(-258,114);
    [nodes addObject:label];
    CCMenuItemSprite *off=[CCMenuItemSprite itemWithNormalSprite:PeonRecordingSwitchSprite(NO,NO,scale) selectedSprite:PeonRecordingSwitchSprite(NO,YES,scale)];
    CCMenuItemSprite *on=[CCMenuItemSprite itemWithNormalSprite:PeonRecordingSwitchSprite(YES,NO,scale) selectedSprite:PeonRecordingSwitchSprite(YES,YES,scale)];
    CCMenuItemToggle *toggle=[CCMenuItemToggle itemWithTarget:[PeonRecorder sharedRecorder] selector:@selector(toggleRecording:) items:off,on,nil];
    toggle.selectedIndex=[PeonRecorder recordingEnabled] ? 1 : 0;
    toggle.position=ccp(145,111); toggle.tag=9910;
    CCMenu *menu=[CCMenu menuWithItems:toggle,nil]; menu.position=CGPointZero;
    [nodes addObject:menu];
}

static void PeonAddVolumeCaption(NSMutableArray *nodes, NSString *labelFile, NSString *originalFile, CGFloat y, CGFloat scale) {
    CCSprite *label=[CCSprite spriteWithFile:labelFile];
    label.anchorPoint=ccp(0,0.5); label.scale=scale; label.position=ccp(-258,y+6);
    [nodes addObject:label];
    // Preserve the original volume-control frame while replacing its baked caption.
    CCSprite *frame=[CCSprite spriteWithFile:originalFile rect:CGRectMake(290,0,240,96)];
    frame.scale=2*scale; frame.position=ccp(145,y);
    [nodes addObject:frame];
}

static void PeonInsetVolumeSlider(CCControlSlider *slider) {
    CCSprite *progress=[slider valueForKey:@"progressSprite"];
    progress.scaleY=0.5;
    progress.position=ccp(progress.position.x,progress.position.y+3);
}
