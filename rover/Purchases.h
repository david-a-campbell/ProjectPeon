//
//  Purchases.h
//  rover
//
//  Created by David Campbell on 7/17/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Purchases : NSManagedObject

@property (nonatomic, retain) NSNumber * hasBooster50;
@property (nonatomic, retain) NSNumber * hasMotor50;

@end
