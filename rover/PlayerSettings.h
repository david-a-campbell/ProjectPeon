//
//  PlayerSettings.h
//  rover
//
//  Created by David Campbell on 6/28/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PlayerSettings : NSManagedObject

@property (nonatomic, retain) NSNumber * isRetinaEnabled;
@property (nonatomic, retain) NSNumber * showToolTips;
@property (nonatomic, retain) NSNumber * showTutorial;
@property (nonatomic, retain) NSNumber * useTouchControl;
@property (nonatomic, retain) NSNumber * musicVolume;
@property (nonatomic, retain) NSNumber * sfxVolume;

@end
