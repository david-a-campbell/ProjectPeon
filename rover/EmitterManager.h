//
//  EmitterManager.h
//  rover
//
//  Created by David Campbell on 7/7/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface EmitterManager : NSObject
{
    
}
@property (nonatomic, retain) CCArray *groundEmitters;
@property (nonatomic, retain) CCArray *splashEmitters;
+(EmitterManager*)sharedManager;

-(CCParticleSystemQuad*)getGroundEmitter:(NSString*)name;
-(CCParticleSystemQuad*)getSpashEmitter:(NSString*)name;

@end
