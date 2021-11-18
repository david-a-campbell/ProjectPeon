//
//  SkyboxParallaxLayer.m
//  rover
//
//  Created by David Campbell on 6/6/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "SkyboxParallaxLayer.h"
#import "Constants.h"

@implementation SkyboxParallaxLayer

-(void)dealloc
{
    [super dealloc];
}

- (id)initWithTileMap:(NSString*)tileMapName
{
    if ((self = [super initWithTileMapName:tileMapName]))
    {
        [self setupParallaxLayers];
    }
    return self;
}

-(void)setParallaxScaleY:(float)scaleY
{
    [parrallaxNode setScaleY:1];
}

-(void)setParallaxScaleX:(float)scaleX
{
    [parrallaxNode setScaleX:1];
}

-(NSArray*)placeHolderNames
{
    return @[@"Parallax0", @"Parallax1"];
}

@end
