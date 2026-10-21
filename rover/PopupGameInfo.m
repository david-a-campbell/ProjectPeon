//
//  PopupGameInfo.m
//  rover
//
//  Created by David Campbell on 9/24/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "PopupGameInfo.h"

#if defined(PROJECTPEON_MAC) && DEBUG && !defined(PROJECTPEON_APP_STORE)
@interface PopupGameInfo () { NSUInteger debugTapCount; }
@end
#endif

static CGRect PeonInfoTextBounds(CCLabelBMFont *label)
{
    CGRect bounds=CGRectNull;
    for (CCNode *glyph in label.children) {
        if (glyph.contentSize.width>0 && glyph.contentSize.height>0)
            bounds=CGRectUnion(bounds,glyph.boundingBox);
    }
    return CGRectApplyAffineTransform(bounds,[label nodeToWorldTransform]);
}

@implementation PopupGameInfo

-(void)createMenu
{
    CCLabelBMFont *text = [self labelWithText:@"Credits\n\nDesign: Daniel Campbell\nProgramming: David Campbell\nAudio: Juan Sajche\nMenu Music: Juan Sajche\nGame Music: W1NGY\n\nSpecial Thanks\n\nPavan Aila\nNathan Baker\nCrage Campbell\nMike Close\nJesse Frye\nMichael Huang\nRobert Michel\nLevar Morris\nDwight Peters\nJosef Salyer\nMadhen Venkataraman\nOmar Walker"];
    [text setScale:SCREEN_SCALE];
    [text setPosition:ccp(0, 0)];
    
    [[self nodeArray] addObject:text];
    CCNode *headingGlyph=[text getChildByTag:0];
    CCNode *firstCreditGlyph=[text getChildByTag:[text.string rangeOfString:@"Design:"].location];
    CGFloat sectionGap=(CGRectGetMinY(headingGlyph.boundingBox)-CGRectGetMaxY(firstCreditGlyph.boundingBox))*text.scale;
    CCLabelBMFont *footerAnchor=text;
    NSBundle *bundle=[NSBundle mainBundle];
    NSString *version=[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"Unknown";
    NSString *build=[bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *versionText=build.length ? [NSString stringWithFormat:@"Version %@ (Build %@)",version,build] : [NSString stringWithFormat:@"Version %@",version];
    CCLabelBMFont *versionLabel=[self labelWithText:versionText];
    versionLabel.scale=SCREEN_SCALE*0.7;
    versionLabel.position=ccp(0,CGRectGetMinY(PeonInfoTextBounds(footerAnchor))-sectionGap-CGRectGetMaxY(PeonInfoTextBounds(versionLabel)));
    [[self nodeArray] addObject:versionLabel];
    CGRect contentBounds=CGRectUnion(text.boundingBox,versionLabel.boundingBox);
    CGFloat centerOffset=-CGRectGetMidY(contentBounds);
    for (CCNode *node in [self nodeArray])
        node.position=ccpAdd(node.position,ccp(0,centerOffset));
#if defined(PROJECTPEON_MAC) && DEBUG && !defined(PROJECTPEON_APP_STORE)
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
    debugTap.position=ccp(CGRectGetMidX(nameBounds),CGRectGetMidY(nameBounds));
    debugTap.tag=9920;
    CCMenu *tapMenu=[CCMenu menuWithItems:debugTap,nil];
    tapMenu.position=CGPointZero;
    [[self nodeArray] addObject:tapMenu];
#endif
}

#if defined(PROJECTPEON_MAC) && DEBUG && !defined(PROJECTPEON_APP_STORE)
-(void)tapProgrammingCredit {
    if(++debugTapCount<10) return;
    debugTapCount=0;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PeonToggleDebugMenu" object:nil];
}
#endif

-(id)labelWithText:(NSString*)someText
{
    float factor = 4*SCREEN_SCALE;
    if (SCREEN_SCALE == 1)
    {
        factor = 1;
    }
    CCLabelBMFont *label=[CCLabelBMFont labelWithString:someText fntFile:@"font42.fnt" width:500*factor alignment:kCCTextAlignmentCenter];
#ifdef PROJECTPEON_MAC
    // Keep filtering inside each glyph so neighboring atlas pixels cannot bleed in.
    // Preserve the layout boxes, as with the recording toggle's ON/OFF label.
    for(CCSprite *glyph in label.children) {
        CGRect rect=glyph.textureRect;
        CGSize size=glyph.contentSize;
        [glyph setTextureRect:CGRectInset(rect,0.5,0.5) rotated:glyph.textureRectRotated untrimmedSize:size];
    }
#endif
    return label;
}

-(int)numberOfPlanks
{
    return 32;
}

@end
