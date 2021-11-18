//
//  TexturedArea.m
//  rover
//
//  Created by David Campbell on 7/9/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "TexturedArea.h"
#import "Constants.h"

@implementation TexturedArea

-(id)initWithDict:(id)dict
{
    if ((self = [super init]))
    {
        [self setGameObjectType:kTexturedArea];
        float x = [[dict valueForKey:@"x"] floatValue];
        float y = [[dict valueForKey:@"y"] floatValue];
        [self setPosition:ccp(x, y)];
        
        [self setupTextureWithDict:dict];
    }
    return self;
}

-(void)setupTextureWithDict:(id)dict
{
    NSString *pointsString = [dict valueForKey:@"polygonPoints"];
    if (![pointsString length]){return;}
    NSString *textureString = [dict valueForKey:@"Texture"];
    if (![textureString length]) {return;}
    
    [self setupTexture:textureString withPoints:[self polygonPointsFromString:pointsString offset:CGSizeMake(0, 0) flipY:YES]];
}

@end
