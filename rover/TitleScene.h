//
//  TitleScene.h
//  rover
//
//  Created by David Campbell on 9/24/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "cocos2d.h"
#import "PopupMenu.h"
#import <MediaPlayer/MediaPlayer.h>
#import "MovieTapHandler.h"

@interface TitleScene : CCScene <popupMenuDelegate, movieTapHandlerDelegate>
@property (nonatomic, retain) MPMoviePlayerController *movieController;
@property (nonatomic, assign) MovieTapHandler *movieTapHandler;
@end
