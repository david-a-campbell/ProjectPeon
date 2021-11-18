//
//  BoostDustProtocol.h
//  rover
//
//  Created by David Campbell on 7/4/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BoostDustProtocol <NSObject>
@required
-(void)createDustForGround:(b2Fixture*)fixture point:(b2Vec2)point;
@end
