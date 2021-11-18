//
//  Bridge.h
//  rover
//
//  Created by David Campbell on 6/20/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"

@interface Bridge : Box2DSprite
{
    float x;
    float y;
    float height;
    float width;
    b2World *world;
    CGPoint start;
    NSString *fileName;
    CGSize plankSize;
    float slackPercent;
}
-(id)initWithDict:(id)dict andWorld:(b2World*)theWorld;
@end
