//
//  CCTMXMapInfo+TMXParserExt.h
//  rover
//
//  Created by David Campbell on 3/4/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "CCTMXXMLParser.h"
/**
 * Extends the parser method within CCTMXMapInfo, so that polygonPoints
 * are added to an object's dictionary.
 *
 * Usage: [CCTMXMapInfo applyParserExtension];
 *
 * @see http://robnapier.net/blog/hijacking-methodexchangeimplementations-502
 */
@interface CCTMXMapInfo (TMXParserExt)
+(void) applyParserExtension;
@end