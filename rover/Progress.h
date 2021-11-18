//
//  Progress.h
//  rover
//
//  Created by David Campbell on 6/19/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Progress : NSManagedObject

@property (nonatomic, retain) NSSet *planets;
@end

@interface Progress (CoreDataGeneratedAccessors)

- (void)addPlanetsObject:(NSManagedObject *)value;
- (void)removePlanetsObject:(NSManagedObject *)value;
- (void)addPlanets:(NSSet *)values;
- (void)removePlanets:(NSSet *)values;
@end
