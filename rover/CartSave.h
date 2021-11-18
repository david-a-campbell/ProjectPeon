//
//  CartSave.h
//  rover
//
//  Created by David Campbell on 5/29/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PartSave;

@interface CartSave : NSManagedObject

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSSet *cartParts;
@end

@interface CartSave (CoreDataGeneratedAccessors)

- (void)addCartPartsObject:(PartSave *)value;
- (void)removeCartPartsObject:(PartSave *)value;
- (void)addCartParts:(NSSet *)values;
- (void)removeCartParts:(NSSet *)values;
@end


@interface ImageToDataTransformer : NSValueTransformer 
{
}
@end