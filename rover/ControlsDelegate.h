//
//  ControlsDelegate.h
//  rover
//
//  Created by David Campbell on 6/29/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ControlsDelegate <NSObject>
@required
-(void)enableControls;
-(void)dissableControls;
@optional
@end
