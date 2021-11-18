//
//  CartSave.m
//  rover
//
//  Created by David Campbell on 5/29/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "CartSave.h"
#import "PartSave.h"


@implementation CartSave

@dynamic image;
@dynamic cartParts;

@end


@implementation ImageToDataTransformer
+ (BOOL)allowsReverseTransformation {
	return YES;
}

+ (Class)transformedValueClass 
{
	return [NSData class];
}

- (id)transformedValue:(id)value 
{
	NSData *data = UIImagePNGRepresentation((UIImage *)value);
	return data;
}

- (id)reverseTransformedValue:(id)value 
{
	UIImage *uiImage = [[UIImage alloc] initWithData:value];
	return [uiImage autorelease];
}

@end