//
//  SaveMenuItem.m
//  rover
//
//  Created by David Campbell on 5/30/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "SaveMenuItem.h"
#import "Constants.h"
#import "SaveManager.h"
#import "ToolTipMenu.h"
#import "SWScrollView.h"

@interface CCMenu (SaveHitTesting)
-(CCMenuItem *)itemForTouch:(UITouch *)touch;
@end

@implementation SaveMenuItem
@synthesize  index, saveDelegate;

-(id)initWithImage:(UIImage *)image andIndex:(int)indx
{
    if ((self = [super init]))
    {
        index = indx;
        [self setupImage:image];
        isExpanded = NO;
    }
    return self;
}

-(id)initAsSaveItem
{
    if ((self = [super init]))
    {
        index = 0;
        CCSprite *backing = [CCSprite spriteWithSpriteFrameName:@"blueprints_btn_new_1.png"];
        CCSprite *backingSel = [CCSprite spriteWithSpriteFrameName:@"blueprints_btn_new_sel_1.png"];
        button = [CCMenuItemSprite itemWithNormalSprite:backing selectedSprite:backingSel disabledSprite:nil target:self selector:@selector(saveCart)];
        [button setScale:2*(SCREEN_SCALE)];
        [self addChild:button];
        [self dissable];
        [self setOpacity:0];
    }
    return self;
}

-(void)dealloc
{
    [savedImage release];
    savedImage = nil;
    [super dealloc];
}

-(void)setupImage:(UIImage *)image
{
    savedImage = [[CCSprite spriteWithCGImage:[image CGImage] key:nil] retain];
    // Saved PNGs can have Retina pixel dimensions independent of their point size.
    // Fit to the preview canvas in logical points, independent of Retina scale.
    CGSize previewSize = savedImage.contentSize;
    CGFloat previewHeight = 384;
#ifdef PROJECTPEON_WIDE_UI
    previewHeight = 288;
#endif
    CGFloat previewScale = MIN(512.0 / previewSize.width, previewHeight / previewSize.height);
    [savedImage setScale:previewScale * 0.28];
    [savedImage setAnchorPoint:ccp(0,0)];
    [savedImage setPosition:ccp(24.25*0.28, 24.25*0.28)];
    CCSprite *backing = [CCSprite spriteWithSpriteFrameName:@"blueprints_loadGlow_1.png"];
    [backing setScale:0.28*CC_CONTENT_SCALE_FACTOR()];
    CCSprite *backingSel = [CCSprite spriteWithSpriteFrameName:@"blueprints_loadGlow_sel_1.png"];
    [backingSel setScale:0.28*CC_CONTENT_SCALE_FACTOR()];
#ifdef PROJECTPEON_WIDE_UI
    backing.scaleY *= 0.75;
    backingSel.scaleY *= 0.75;
#endif
    button = [CCMenuItemSprite itemWithNormalSprite:backing selectedSprite:backingSel disabledSprite:nil target:self selector:@selector(expandView)];
    [button addChild:savedImage];
    [button setAnchorPoint:ccp(0, 0)];
    CGSize frameSize = CGSizeMake(backing.contentSize.width * backing.scaleX,
                                  backing.contentSize.height * backing.scaleY);
    [button setContentSize:frameSize];
    // Center both new widescreen snapshots and existing 4:3 saves in the frame.
    savedImage.position = ccp((frameSize.width-savedImage.contentSize.width*savedImage.scaleX)/2,
                              (frameSize.height-savedImage.contentSize.height*savedImage.scaleY)/2);
    [button setPosition:ccp(-frameSize.width/2, -frameSize.height/2)];
    [self addChild:button];
    [self setOpacity:0];
    [self setupButtons];
}

-(void)setupButtons
{
    // These 106x51 assets have a transparent one-pixel border. Align their
    // visible edges to the preview, rather than leaving that border as a seam.
    CGRect actionRect = CC_RECT_PIXELS_TO_POINTS(CGRectMake(1,1,104,49));
    CCSprite *dbtn = [CCSprite spriteWithFile:@"CartDelete.png" rect:actionRect];
    CCSprite *dbtnsel = [CCSprite spriteWithFile:@"CartDeleteDown.png" rect:actionRect];
    CCSprite *sbtn = [CCSprite spriteWithFile:@"CartLoad.png" rect:actionRect];
    CCSprite *sbtnsel = [CCSprite spriteWithFile:@"CartLoadDown.png" rect:actionRect];
    deleteButton = [CCMenuItemSprite itemWithNormalSprite:dbtn selectedSprite:dbtnsel target:self selector:@selector(deleteCart)];
    saveButton = [CCMenuItemSprite itemWithNormalSprite:sbtn selectedSprite:sbtnsel target:self selector:@selector(loadCart)];
    [saveButton setAnchorPoint:ccp(0, 0)];
    [deleteButton setAnchorPoint:ccp(0, 0)];
    [saveButton setPosition:ccp(-71.75, -53.50)];
    [deleteButton setPosition:ccp(36.75, -53.50)];
    [deleteButton setScale:0.33*CC_CONTENT_SCALE_FACTOR()];
    [saveButton setScale:0.33*CC_CONTENT_SCALE_FACTOR()];
    CGFloat buttonWidth = deleteButton.boundingBox.size.width;
    CGFloat buttonHeight = saveButton.boundingBox.size.height;
    CGRect preview = savedImage.boundingBox;
    CGFloat left = button.position.x+CGRectGetMinX(preview);
    CGFloat right = button.position.x+CGRectGetMaxX(preview);
    CGFloat bottom = button.position.y+CGRectGetMinY(preview);
    saveButton.position = ccp(left,bottom-buttonHeight);
    deleteButton.position = ccp(right-buttonWidth,bottom-buttonHeight);
    [saveButton setOpacity:0];
    [deleteButton setOpacity:0];
    [deleteButton setIsEnabled:NO];
    [saveButton setIsEnabled:NO];
    [self addChild:deleteButton];
    [self addChild:saveButton];
}

-(CGRect)selectionBounds
{
    return CGRectUnion(button.boundingBox, CGRectUnion(saveButton.boundingBox, deleteButton.boundingBox));
}

-(void)minimize
{
    [[self saveDelegate] minimizeSelected];
    [self collapseView];
}

-(void)expandView
{
    if (isExpanded) {return;}
    isExpanded = YES;
    //[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:1 swallowsTouches:YES];
    [self setTouchEnabled:YES];
    [saveDelegate expandViewSelected:self];
    CCScaleTo *scale = [CCScaleTo actionWithDuration:0.3 scale:3];
    CCMoveBy *move = [CCMoveBy actionWithDuration:0.3 position:ccp(0, -300)];
    CCSpawn *spawn = [CCSpawn actions:scale, move, nil];
    id seq = [CCSequence actions:spawn, [CCCallFunc actionWithTarget:self selector:@selector(expandComplete)],nil];
    [self runAction:seq];
}

-(void)expandComplete
{
    CCFadeTo *fade = [CCFadeTo actionWithDuration:0.2 opacity:255];
    [deleteButton runAction:[[fade copy]autorelease]];
    [saveButton runAction:fade];
    [deleteButton setIsEnabled:YES];
    [saveButton setIsEnabled:YES];
    [saveDelegate expandViewComplete];
}

-(void)collapseView
{
    [deleteButton setIsEnabled:NO];
    [saveButton setIsEnabled:NO];
    CCFadeTo *fade = [CCFadeTo actionWithDuration:0.2 opacity:0];
    [deleteButton runAction:[[fade copy]autorelease]];
    [saveButton runAction:fade];
    CCScaleTo *scale = [CCScaleTo actionWithDuration:0.3 scale:1];
    CCMoveBy *move = [CCMoveBy actionWithDuration:0.3 position:ccp(0, 300)];
    CCSpawn *spawn = [CCSpawn actions:scale, move, nil];
    id seq = [CCSequence actions:spawn, [CCCallFunc actionWithTarget:self selector:@selector(colapseComplete)], nil];
    [self runAction:seq];
}

-(void)colapseComplete
{
//    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-502 swallowsTouches:NO];
    [self setTouchEnabled:YES];
    [button setIsEnabled:YES];
    isExpanded = NO;
}

-(void)cleanup
{
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [super cleanup];
}

-(void)saveCart
{
    if ([[SaveManager sharedManager] numberOfSavedCarts] >= 50)
    {
        [ToolTipMenu displayWithMessage:@"You have reached the limit.\n\nDelete one to continue." plankCount:6];
        return;
    }
    [self dissable];
    [saveDelegate cartSaveSelected];
}

-(void)deleteCart
{
    [self setTouchEnabled:NO];
    [saveDelegate dissableAllMenuItems];
    [[SaveManager sharedManager] deleteCartAtIndex:index];
    CCFadeTo *fade = [CCFadeTo actionWithDuration:0.3f opacity:0];
    [self runAction:[CCSequence actions:fade, [CCCallFunc actionWithTarget:self selector:@selector(deleteReady)],nil]];
}

-(void)deleteReady
{
    [saveDelegate deleteCartSelected:index];
}

-(void)loadCart
{
    [self collapseView];
    [[SaveManager sharedManager] loadCartAtIndex:index];
    [saveDelegate loadCartSelected];
}

-(void)enable
{
    [button setIsEnabled:YES];
}

-(void)dissable
{
    [button setIsEnabled:NO];
}

-(void)setOpacity:(GLubyte)opacity
{
    [savedImage setOpacity:opacity];
    [button setOpacity:opacity];
    [super setOpacity:opacity];
    [saveButton setOpacity:0];
    [deleteButton setOpacity:0];
}

-(void)registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-502 swallowsTouches:NO];
}

-(CCMenuItem *)itemForTouch:(UITouch *)touch
{
    // CCMenu does not know that the thumbnail row is clipped by its scroll view.
    // Expanded previews intentionally extend below that row.
    if (!isExpanded) {
        for (CCNode *ancestor=self.parent; ancestor; ancestor=ancestor.parent) {
            if ([ancestor isKindOfClass:[SWScrollView class]]) {
                CGSize size=((SWScrollView *)ancestor).viewSize;
                if (!CGRectContainsPoint(CGRectMake(0,0,size.width,size.height),
                                         [ancestor convertTouchToNodeSpace:touch])) return nil;
                break;
            }
        }
    }
    return [super itemForTouch:touch];
}

@end
