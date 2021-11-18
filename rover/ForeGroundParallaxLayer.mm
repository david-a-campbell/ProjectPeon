//
//  ForeGroundParallaxLayer.m
//  rover
//
//  Created by David Campbell on 6/20/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "ForeGroundParallaxLayer.h"
#import "Constants.h"

@implementation ForeGroundParallaxLayer

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

-(NSArray*)placeHolderNames
{
    return @[@"Parallax7", @"Parallax8"];
}

@end
