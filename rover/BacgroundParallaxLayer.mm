//
//  BacgroundParallaxLayer.m
//  rover
//
//  Created by David Campbell on 3/17/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "BacgroundParallaxLayer.h"
#import "Constants.h"

@implementation BacgroundParallaxLayer

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
    return @[@"Parallax2Sprites", @"Parallax2", @"Parallax3Sprites", @"Parallax3", @"Parallax4Sprites", @"Parallax4", @"Parallax5Sprites", @"Parallax5", @"Parallax6Sprites", @"Parallax6"];
}

@end
