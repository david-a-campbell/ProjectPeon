#pragma once
#import "cocos2d.h"
#import "CCControlExtension.h"

static void PeonAddVolumeCaption(NSMutableArray *nodes, NSString *labelFile, NSString *originalFile, CGFloat y, CGFloat scale) {
    CCSprite *label=[CCSprite spriteWithFile:labelFile];
    label.anchorPoint=ccp(0,0.5); label.scale=scale; label.position=ccp(-258,y+6);
    [nodes addObject:label];
    // Preserve the original volume-control frame while replacing its baked caption.
    CCSprite *frame=[CCSprite spriteWithFile:originalFile rect:CC_RECT_PIXELS_TO_POINTS(CGRectMake(290,0,240,96))];
    frame.scale=2*scale; frame.position=ccp(145,y);
    [nodes addObject:frame];
}

static void PeonInsetVolumeSlider(CCControlSlider *slider) {
    CCSprite *progress=[slider valueForKey:@"progressSprite"];
    progress.scaleY=0.5;
    progress.position=ccp(progress.position.x,progress.position.y+3/CC_CONTENT_SCALE_FACTOR());
}

#ifdef PROJECTPEON_IOS
#import "SaveManager.h"
#import "../mac/PeonBitmapFont.h"

static void PeonRefreshBoostSideMenu(CCMenu *menu) {
    BOOL right=[[SaveManager sharedManager] boostButtonOnRight];
    for (CCMenuItemLabel *item in menu.children) {
        BOOL selected=(item.tag==2)==right;
        item.isEnabled=!selected;
        item.label.color=selected ? ccc3(155,222,255) : ccWHITE;
    }
}

static void PeonAddBoostSideSetting(NSMutableArray *nodes,id target,CGFloat y,CGFloat scale) {
    CCLabelBMFont *caption=[CCLabelBMFont labelWithString:@"boost:" fntFile:@"font42.fnt"];
    PeonInsetBitmapGlyphs(caption);
    caption.scale=scale; caption.anchorPoint=ccp(1,0.5); caption.position=ccp(-92,y);
    [nodes addObject:caption];
    NSMutableArray *items=[NSMutableArray array];
    for (NSUInteger index=0;index<2;index++) {
        CCLabelBMFont *label=[CCLabelBMFont labelWithString:index ? @"right" : @"left" fntFile:@"font42.fnt"];
        PeonInsetBitmapGlyphs(label); label.scale=scale;
        CCMenuItemLabel *item=[CCMenuItemLabel itemWithLabel:label target:target selector:index ? @selector(boostRightSelected:) : @selector(boostLeftSelected:)];
        label.anchorPoint=ccp(0.5,0.5);
        item.tag=(int)index+1;
        item.contentSize=CGSizeMake(label.contentSize.width*scale+24,44);
        label.position=ccp(item.contentSize.width/2,item.contentSize.height/2);
        item.position=ccp(index ? 188 : 28,0);
        [items addObject:item];
    }
    CCMenu *menu=[CCMenu menuWithArray:items]; menu.position=ccp(0,y);
    PeonRefreshBoostSideMenu(menu); [nodes addObject:menu];
}
#endif
