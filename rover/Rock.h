//
//  Rock.h
//  rover
//
//  Created by David Campbell on 6/30/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//
#import "Box2DSprite.h"
#import "PRTriangulator.h"
@class PRFilledPolygon;

@interface Rock : Box2DSprite
{
    b2World *world;
    id<PRTriangulator> triangulator;
}
@property (nonatomic, retain) id dictionary;
-(id)initWithWorld:(b2World*)theWorld andDict:(id)dict;
@property (nonatomic, retain) PRFilledPolygon *filledPolygon1;
@property (nonatomic, retain) PRFilledPolygon *filledPolygon2;

-(void)resetRock;
@end
