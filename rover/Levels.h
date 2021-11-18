//
//  Levels.h
//  rover
//
//  Created by David Campbell on 7/5/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Planets;

@interface Levels : NSManagedObject

@property (nonatomic, retain) NSNumber * levelNumber;
@property (nonatomic, retain) NSNumber * percentScore;
@property (nonatomic, retain) NSNumber * timeScore;
@property (nonatomic, retain) NSNumber * isUnlocked;
@property (nonatomic, retain) Planets *planet;

@end
