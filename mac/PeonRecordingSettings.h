#import "cocos2d.h"
#import "PeonRecorder.h"
#import "CCControlExtension.h"
// CCLayerColor does not refresh its vertex colors when inherited opacity changes.
// Keep this correction local to the recording switch's solid rectangles.
@interface CCLayerColor (PeonRecordingColorRefresh)
- (void)updateColor;
@end
@interface PeonRecordingSwitchFill : CCLayerColor
@end


static CCNode<CCRGBAProtocol> *PeonRecordingSwitchSprite(BOOL enabled, BOOL pressed, CGFloat scale) {
    CCNodeRGBA *container=[CCNodeRGBA node]; container.contentSize=CGSizeMake(210,26);
    container.cascadeOpacityEnabled=YES;
    // Draw exact rectangles rather than stretching a one-pixel texture.
    CCLayerColor *frame=[PeonRecordingSwitchFill layerWithColor:ccc4(210,240,255,255) width:210 height:26];
    [container addChild:frame];
    ccColor4B fill=pressed ? ccc4(45,110,145,255) : (enabled ? ccc4(25,95,130,255) : ccc4(8,30,48,255));
    CCLayerColor *inset=[PeonRecordingSwitchFill layerWithColor:fill width:204 height:20];
    inset.position=ccp(3,3);
    [container addChild:inset];
    CCLabelBMFont *text=[CCLabelBMFont labelWithString:enabled ? @"ON" : @"OFF" fntFile:@"font52.fnt"];
    // The tightly packed bitmap font bleeds neighboring glyphs under linear filtering.
    // Inset only this switch's glyph UVs, preserving their original layout boxes.
    for(CCSprite *glyph in text.children) {
        CGRect rect=glyph.textureRect;
        CGSize size=glyph.contentSize;
        [glyph setTextureRect:CGRectInset(rect,0.5,0.5) rotated:glyph.textureRectRotated untrimmedSize:size];
    }
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
