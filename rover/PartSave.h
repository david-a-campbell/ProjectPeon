//
//  PartSave.h
//  rover
//
//  Created by David Campbell on 5/29/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CommonProtocols.h"

@class CartSave;

@interface PartSave : NSManagedObject

@property (nonatomic, retain) NSString *start;
@property (nonatomic, retain) NSString *end;
@property (nonatomic, retain) NSNumber *type;
@property (nonatomic, retain) NSNumber *modifier;
@property (nonatomic, retain) NSNumber *index;
@property (nonatomic, retain) CartSave *cart;

@end