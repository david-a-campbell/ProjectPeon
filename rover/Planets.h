//
//  Planets.h
//  rover
//
//  Created by David Campbell on 6/19/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Levels, Progress;

@interface Planets : NSManagedObject

@property (nonatomic, retain) NSNumber * planetNumber;
@property (nonatomic, retain) Progress *progress;
@property (nonatomic, retain) NSSet *levels;
@property (nonatomic, retain) NSNumber * isUnlocked;
@end

@interface Planets (CoreDataGeneratedAccessors)

- (void)addLevelsObject:(Levels *)value;
- (void)removeLevelsObject:(Levels *)value;
- (void)addLevels:(NSSet *)values;
- (void)removeLevels:(NSSet *)values;
@end
