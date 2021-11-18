//
//  BasePopupMenu.m
//  rover
//
//  Created by David Campbell on 6/25/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "BasePopupMenu.h"
#import "CCControlExtension.h"

@implementation BasePopupMenu

-(id)initWithDelegate:(id<popupMenuDelegate>)delegate
{
    if (self = [super init])
    {
        _nodeArray = [[NSMutableArray alloc] init];
        [self setPopupDelegate:delegate];
        [self createMenu];
    }
    return self;
}

-(void)createMenu
{
    //Override in subclass
}

-(int)numberOfPlanks
{
    //Override in subclass
    return 5;
}

-(void)removeFromParent
{
    for (CCNode *node in _nodeArray)
    {
        [node removeFromParentAndCleanup:YES];
    }
}

-(void)setOpacity:(float)opacity
{
    for (CCNode *node in _nodeArray)
    {
        if ([[node class] isSubclassOfClass:[CCLayerRGBA class]])
        {
            CCLayerRGBA *layer = (CCLayerRGBA*)node;
            [layer setOpacity:opacity];
        }else if ([node conformsToProtocol:@protocol(CCRGBAProtocol)])
        {
            id<CCRGBAProtocol> item = (id<CCRGBAProtocol>)node;
            [item setOpacity:opacity];
        }
    }
}

-(void)addToNode:(CCNode *)node
{
    for (CCNode *aNode in _nodeArray)
    {
        [node addChild:aNode];
    }
}

-(void)runAction:(id)action
{
    for(CCNode *node in _nodeArray)
    {
        [node runAction:[[action copy] autorelease]];
    }
}

-(void)setHandlerPriority:(int)priority
{
    int count = 0;
    for (CCNode *node in _nodeArray)
    {
        if ([[node class] isSubclassOfClass:[CCMenu class]])
        {
            CCMenu *menu = (CCMenu*)node;
            [menu setHandlerPriority:priority-count];
            count++;
        }else if ([[node class] isSubclassOfClass:[CCControl class]])
        {
            CCControl *control = (CCControl*)node;
            [control setHandlerPriority:priority-count];
            count++;
        }
    }
}

-(void)stopAllActions
{
    for(CCNode *node in _nodeArray)
    {
        [node stopAllActions];
    }
}

-(void)setTouchEnabled:(BOOL)enabled
{
    for (CCNode *node in _nodeArray)
    {
        if ([[node class] isSubclassOfClass:[CCLayer class]])
        {
            CCLayer *layer = (CCLayer*)node;
            [layer setTouchEnabled:enabled];
        }
    }
}

-(void)dealloc
{
    [_nodeArray release];
    _nodeArray = nil;
    [super dealloc];
}
@end
