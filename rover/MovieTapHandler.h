//
//  MovieTapHandler.h
//  rover
//
//  Created by David Campbell on 10/5/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "cocos2d.h"

@protocol movieTapHandlerDelegate <NSObject>
@required
-(void)movieTapHandlerWasTapped;
@end

@interface MovieTapHandler : CCLayer
@property (nonatomic, assign) id<movieTapHandlerDelegate> delegate;
@end
