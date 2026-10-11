//
//  PopupGameInfo.m
//  rover
//
//  Created by David Campbell on 9/24/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "PopupGameInfo.h"

@interface PopupGameInfo () { NSUInteger debugTapCount; }
@end

@implementation PopupGameInfo

-(void)createMenu
{
    CCSprite *text = [self labelWithText:@"Credits\n\nDesign: Daniel Campbell\nProgramming: David Campbell\nAudio: Juan Sajche\nMenu Music: Juan Sajche\nGame Music: W1NGY\n\nSpecial Thanks\n\nPavan Aila\nNathan Baker\nCrage Campbell\nMike Close\nJesse Frye\nMichael Huang\nRobert Michel\nLevar Morris\nDwight Peters\nJosef Salyer\nMadhen Venkataraman\nOmar Walker"];
    [text setScale:SCREEN_SCALE];
    [text setPosition:ccp(0, 0)];
    
    [[self nodeArray] addObject:text];
#if DEBUG && !defined(PROJECTPEON_APP_STORE)
    CCLabelBMFont *label=(CCLabelBMFont *)text;
    NSRange nameRange=[label.string rangeOfString:@"David Campbell"];
    CGRect nameBounds=CGRectNull;
    for(NSUInteger index=nameRange.location; index<NSMaxRange(nameRange); index++) {
        CCNode *glyph=[label getChildByTag:index];
        if(glyph) nameBounds=CGRectUnion(nameBounds,glyph.boundingBox);
    }
    nameBounds=CGRectApplyAffineTransform(nameBounds,[label nodeToParentTransform]);
    CCMenuItem *debugTap=[CCMenuItem itemWithTarget:self selector:@selector(tapProgrammingCredit)];
    debugTap.contentSize=CGSizeMake(nameBounds.size.width+8,nameBounds.size.height+4);
#ifdef PROJECTPEON_IOS
    // Expand only the invisible hit area; the credit text and layout stay intact.
    CGSize viewSize=[CCDirector sharedDirector].view.bounds.size;
    CGFloat minimumTouch=44.0*768/MAX(1,MIN(viewSize.width,viewSize.height));
    debugTap.contentSize=CGSizeMake(MAX(nameBounds.size.width+32,minimumTouch),MAX(nameBounds.size.height+12,minimumTouch));
#endif
    debugTap.position=ccp(CGRectGetMidX(nameBounds),CGRectGetMidY(nameBounds));
    debugTap.tag=9920;
    CCMenu *tapMenu=[CCMenu menuWithItems:debugTap,nil];
    tapMenu.position=CGPointZero;
    [[self nodeArray] addObject:tapMenu];
#endif
}

-(void)tapProgrammingCredit {
#if DEBUG && !defined(PROJECTPEON_APP_STORE)
    if(++debugTapCount<10) return;
    debugTapCount=0;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PeonToggleDebugMenu" object:nil];
#endif
}

-(id)labelWithText:(NSString*)someText
{
    float factor = 4*SCREEN_SCALE;
    if (SCREEN_SCALE == 1)
    {
        factor = 1;
    }
    CCLabelBMFont *label=[CCLabelBMFont labelWithString:someText fntFile:@"font42.fnt" width:500*factor alignment:kCCTextAlignmentCenter];
    // Keep filtering inside each glyph so neighboring atlas pixels cannot bleed in.
    // Preserve the layout boxes, as with the recording toggle's ON/OFF label.
    for(CCSprite *glyph in label.children) {
        CGRect rect=glyph.textureRect;
        CGSize size=glyph.contentSize;
        [glyph setTextureRect:CGRectInset(rect,0.5,0.5) rotated:glyph.textureRectRotated untrimmedSize:size];
    }
    return label;
}

-(int)numberOfPlanks
{
    return 30;
}

@end
