//
//  CompositeSprite.h
//  rover
//
//  Created by David Campbell on 7/13/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"

@interface CompositeSprite : Box2DSprite
{
    b2World *world;
    int compositeSpriteID;
    BOOL isSatellite;
    b2Body *anchorBody;
    b2Vec2 originalPosition;
}
@property (nonatomic, retain) id dictionary;
-(id)initWithWorld:(b2World *)theWorld andDict:(id)dict objectGroup:(CCTMXObjectGroup *)spriteObjects;
-(void)reset;
@end
