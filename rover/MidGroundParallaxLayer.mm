//
//  MidGroundParallaxLayer.m
//  rover
//
//  Created by David Campbell on 8/2/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "MidGroundParallaxLayer.h"

@implementation MidGroundParallaxLayer

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

-(NSArray *)layerPrefixes
{
    return @[@"MidGroundLayer", @"NearGroundLayer1", @"NearGroundLayer2"];
}

-(NSString*)placeHolderName
{
    return  @"MidGroundPlaceholders";
}

@end
