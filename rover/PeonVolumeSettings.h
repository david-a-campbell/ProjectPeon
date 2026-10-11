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
#import <CoreImage/CoreImage.h>
#import "../mac/PeonBitmapFont.h"

// Blur a bitmap-font mask once, rather than outlining it with shifted glyphs.
// This uses UIKit/Core Image, so creating a settings row does not disturb GL state.
static CCSprite *PeonSettingsTextGlow(CCLabelBMFont *label) {
    CGFloat padding=12, density=CC_CONTENT_SCALE_FACTOR();
    CGSize size=CGSizeMake(ceil(label.contentSize.width*label.scale+padding*2),ceil(label.contentSize.height*label.scale+padding*2));
    NSString *key=[NSString stringWithFormat:@"peon-settings-glow-%@-%.3f",label.string,label.scale];
    CCTexture2D *texture=[[CCTextureCache sharedTextureCache] textureForKey:key];
    if (!texture) {
        UIImage *atlas=[UIImage imageWithContentsOfFile:[[CCFileUtils sharedFileUtils] fullPathForFilename:@"font52.png"]];
        UIGraphicsBeginImageContextWithOptions(size,NO,density);
        for (CCSprite *glyph in label.children) {
            if (!glyph.visible || glyph.contentSize.width==0) continue;
            CGFloat sourceDensity=CGImageGetWidth(atlas.CGImage)/glyph.texture.contentSize.width;
            CGRect source=glyph.textureRect;
            source=CGRectMake(source.origin.x*sourceDensity,source.origin.y*sourceDensity,source.size.width*sourceDensity,source.size.height*sourceDensity);
            CGImageRef image=CGImageCreateWithImageInRect(atlas.CGImage,source);
            CGRect box=glyph.boundingBox;
            CGRect target=CGRectMake(padding+box.origin.x*label.scale,padding+(label.contentSize.height-CGRectGetMaxY(box))*label.scale,box.size.width*label.scale,box.size.height*label.scale);
            [[UIImage imageWithCGImage:image] drawInRect:target]; CGImageRelease(image);
        }
        UIImage *mask=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext();
        CIFilter *blur=[CIFilter filterWithName:@"CIGaussianBlur"];
        [blur setValue:[CIImage imageWithCGImage:mask.CGImage] forKey:kCIInputImageKey];
        [blur setValue:@(3*density) forKey:kCIInputRadiusKey];
        CIContext *context=[CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@YES}];
        CGImageRef blurred=[context createCGImage:blur.outputImage fromRect:CGRectMake(0,0,size.width*density,size.height*density)];
        UIGraphicsBeginImageContextWithOptions(size,NO,density);
        [[UIImage imageWithCGImage:blurred scale:density orientation:UIImageOrientationUp] drawInRect:CGRectMake(0,0,size.width,size.height)];
        CGContextRef drawing=UIGraphicsGetCurrentContext(); CGContextSetBlendMode(drawing,kCGBlendModeSourceIn);
        CGContextSetRGBFillColor(drawing,6/255.0,149/255.0,1,1); CGContextFillRect(drawing,CGRectMake(0,0,size.width,size.height));
        UIImage *tinted=UIGraphicsGetImageFromCurrentImageContext();
        texture=[[CCTextureCache sharedTextureCache] addCGImage:tinted.CGImage forKey:key];
        UIGraphicsEndImageContext(); CGImageRelease(blurred);
    }
    CCSprite *glow=[CCSprite spriteWithTexture:texture];
    glow.scaleX=size.width/glow.contentSize.width; glow.scaleY=size.height/glow.contentSize.height;
    glow.position=ccp(label.position.x+(0.5-label.anchorPoint.x)*label.contentSize.width*label.scale,label.position.y+(0.5-label.anchorPoint.y)*label.contentSize.height*label.scale);
    glow.opacity=128;
    return glow;
}
static void PeonRefreshChoiceSetting(CCMenu *menu, BOOL secondSelected) {
    for (CCMenuItemLabel *item in menu.children) {
        BOOL selected=(item.tag==2)==secondSelected;
        item.isEnabled=!selected;
        item.label.color=selected ? ccWHITE : ccc3(65,104,145);
        [(CCSprite *)[item getChildByTag:9777] setOpacity:selected ? 128 : 40];
    }
}

static CCMenu *PeonAddChoiceSetting(NSMutableArray *nodes,id target,CGFloat y,CGFloat scale,NSString *title,NSArray *choices,SEL firstAction,SEL secondAction,BOOL secondSelected) {
    CCLabelBMFont *caption=[CCLabelBMFont labelWithString:title fntFile:@"font52.fnt"];
    PeonInsetBitmapGlyphs(caption);
    caption.scale=scale; caption.anchorPoint=ccp(1,0.5); caption.position=ccp(-4,y+6);
    // Keep the glow's own alpha when the popup fades its top-level nodes.
    CCLayerRGBA *captionGlows=[CCLayerRGBA node]; captionGlows.cascadeOpacityEnabled=YES;
    [nodes addObject:captionGlows];
    [captionGlows addChild:PeonSettingsTextGlow(caption)];
    [nodes addObject:caption];
    if ([title isEqualToString:@"boost:"]) { caption.tag=9780; captionGlows.tag=9781; }
    NSMutableArray *items=[NSMutableArray array];
    for (NSUInteger index=0;index<2;index++) {
        CCLabelBMFont *label=[CCLabelBMFont labelWithString:choices[index] fntFile:@"font52.fnt"];
        PeonInsetBitmapGlyphs(label); label.scale=scale;
        CCMenuItemLabel *item=[CCMenuItemLabel itemWithLabel:label target:target selector:index ? secondAction : firstAction];
        label.anchorPoint=ccp(index ? 1 : 0,0.5);
        item.tag=(int)index+1;
        // Align the outside text edges with the volume frames above.
        CGFloat edge=145+(index ? 106 : -106)*scale;
        item.contentSize=CGSizeMake(160*scale,90*scale);
        label.position=ccp(index ? item.contentSize.width : 0,item.contentSize.height/2+6);
        CCSprite *glow=PeonSettingsTextGlow(label); glow.tag=9777;
        [item addChild:glow z:-1];
        item.position=ccp(edge+(index ? -1 : 1)*item.contentSize.width/2,0);
        [items addObject:item];
    }
    CCMenu *menu=[CCMenu menuWithArray:items]; menu.position=ccp(0,y);
    PeonRefreshChoiceSetting(menu,secondSelected); [nodes addObject:menu];
    return menu;
}
static void PeonRefreshBoostSideMenu(CCMenu *menu) {
    PeonRefreshChoiceSetting(menu,[[SaveManager sharedManager] boostButtonOnRight]);
}
// Keep the saved side while disabling every part of the row in Tilt mode.
static void PeonRefreshBoostAvailability(NSArray *nodes) {
    BOOL enabled=[[SaveManager sharedManager] useTouchControl];
    for (CCNode *node in nodes) {
        if (node.tag==9780) [(CCLabelBMFont *)node setColor:enabled ? ccWHITE : ccc3(100,100,100)];
        if (node.tag==9781) for (CCSprite *glow in node.children) glow.opacity=enabled ? 128 : 0;
        if (node.tag!=9782) continue;
        CCMenu *menu=(CCMenu *)node;
        PeonRefreshBoostSideMenu(menu);
        if (!enabled) for (CCMenuItemLabel *item in menu.children) {
            item.isEnabled=NO; item.label.color=ccc3(100,100,100);
            [(CCSprite *)[item getChildByTag:9777] setOpacity:0];
        }
    }
}
static void PeonAddBoostSideSetting(NSMutableArray *nodes,id target,CGFloat y,CGFloat scale) {
    CCMenu *menu=PeonAddChoiceSetting(nodes,target,y,scale,@"boost:",@[@"left",@"right"],@selector(boostLeftSelected:),@selector(boostRightSelected:),[[SaveManager sharedManager] boostButtonOnRight]);
    menu.tag=9782;
    PeonRefreshBoostAvailability(nodes);
}
#endif
