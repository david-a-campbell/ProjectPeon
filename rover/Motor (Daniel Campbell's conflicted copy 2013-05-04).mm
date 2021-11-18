//
//  Motor.m
//  rover
//
//  Created by David Campbell on 3/11/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Motor.h"
#import "SimpleQueryCallback.h"
#import "Box2DHelpers.h"

#define MAX_REVS_SEC 0.7f
#define TORQUE 400.0f

@implementation Motor

-(void)dealloc
{
    [MotorHub release];
    MotorHub = nil;
    [super dealloc];
}

-(id)initWithStart:(CGPoint)touchStartLocation andEnd:(CGPoint)touchEndLocation andCart:(PlayerCart *)theCart
{
    if ((self = [super initWithStart:touchStartLocation andEnd:touchEndLocation andCart:theCart]))
    {
        gameObjectType = kMotorPartType;
    }
    return self;
}

-(void)setRotation:(float)rotation
{
    [super setRotation:rotation];
    [MotorHub setRotation:-rotation];
}

-(void)setupImage
{
    //[self setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"wheelTire.png"]];
    MotorHub = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"wheelHub.png"]];
    [self addChild:MotorHub];
    [MotorHub setPosition:ccp([self boundingBox].size.height/2.0f,[self boundingBox].size.width/2.0f)];
    [self addPivotIndicator];
    
    [self setPosition:start];
    float diameter = ccpDistance(start, end)*2.0f;
    [self setScale:diameter/[self boundingBox].size.height];
}

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    if (body!=nil) 
    {
        float maxRevs = MAX_REVS_SEC*(MAX_WHEEL_LENGTH/(ccpDistance(start, end)));
        float maxMotorSpeed = (M_PI*2)*maxRevs;
        float accelerationY = [acceleration y];
        UIInterfaceOrientation currentOrientation =  [[UIApplication sharedApplication] statusBarOrientation];
        if (currentOrientation == UIInterfaceOrientationLandscapeLeft)
        {
            accelerationY *= -1;
        }
        
        float32 accelerationFraction = accelerationY*3;
        if (accelerationFraction < -1) {
            accelerationFraction = -1;
        } else if (accelerationFraction > 1) {
            accelerationFraction = 1;
        }
        
        if (abs(body->GetAngularVelocity()) < maxMotorSpeed || [self acc:accelerationFraction isOppositeToVel:body->GetAngularVelocity()])
        {
            body->ApplyTorque(body->GetMass()*accelerationFraction*TORQUE);
        }
    }
}

-(BOOL)acc:(float)acc isOppositeToVel:(float) vel
{
    if ((acc < 0 && vel > 0) || (acc > 0 && vel < 0))
    {
        return YES;
    }
    return NO;
}

-(void)highlightMe
{
    [super highlightMe];
    [MotorHub setColor:highlightedColor];
}

-(void)unHighlightMe
{
    [super unHighlightMe];
    [MotorHub setColor:originalColor];
}

-(BOOL)shouldRemoveFromAccelerationArray
{
    return isReadyForRemoval;
}

-(void)draw
{
    [super draw];
    //// Color Declarations
    UIColor* color5 = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    UIColor* color6 = [UIColor colorWithRed: 0.102 green: 0.102 blue: 0.102 alpha: 1];
    UIColor* color7 = [UIColor colorWithRed: 0.2 green: 0.2 blue: 0.2 alpha: 1];
    
    //// spoke
    {
        //// Bezier Drawing
        UIBezierPath* bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint: CGPointMake(176.38, 227.95)];
        [bezierPath addCurveToPoint: CGPointMake(162, 225.99) controlPoint1: CGPointMake(171.5, 227.95) controlPoint2: CGPointMake(166.67, 227.29)];
        [bezierPath addCurveToPoint: CGPointMake(156.44, 201.76) controlPoint1: CGPointMake(166.44, 217.74) controlPoint2: CGPointMake(164.16, 207.37)];
        [bezierPath addCurveToPoint: CGPointMake(145.34, 198.15) controlPoint1: CGPointMake(153.19, 199.39) controlPoint2: CGPointMake(149.35, 198.15)];
        [bezierPath addCurveToPoint: CGPointMake(131.78, 203.86) controlPoint1: CGPointMake(140.18, 198.15) controlPoint2: CGPointMake(135.33, 200.21)];
        [bezierPath addCurveToPoint: CGPointMake(123.08, 176.64) controlPoint1: CGPointMake(126.44, 195.73) controlPoint2: CGPointMake(123.45, 186.39)];
        [bezierPath addCurveToPoint: CGPointMake(126.13, 176.89) controlPoint1: CGPointMake(124.09, 176.81) controlPoint2: CGPointMake(125.11, 176.89)];
        [bezierPath addCurveToPoint: CGPointMake(144.11, 163.83) controlPoint1: CGPointMake(134.35, 176.89) controlPoint2: CGPointMake(141.57, 171.64)];
        [bezierPath addCurveToPoint: CGPointMake(134.81, 141.18) controlPoint1: CGPointMake(146.98, 155) controlPoint2: CGPointMake(142.92, 145.37)];
        [bezierPath addCurveToPoint: CGPointMake(157.74, 124.62) controlPoint1: CGPointMake(140.85, 133.67) controlPoint2: CGPointMake(148.73, 127.98)];
        [bezierPath addCurveToPoint: CGPointMake(176.38, 140.38) controlPoint1: CGPointMake(159.25, 133.58) controlPoint2: CGPointMake(167.15, 140.38)];
        [bezierPath addCurveToPoint: CGPointMake(195.03, 124.62) controlPoint1: CGPointMake(185.61, 140.38) controlPoint2: CGPointMake(193.51, 133.58)];
        [bezierPath addCurveToPoint: CGPointMake(217.96, 141.18) controlPoint1: CGPointMake(204.04, 127.98) controlPoint2: CGPointMake(211.91, 133.67)];
        [bezierPath addCurveToPoint: CGPointMake(208.65, 163.82) controlPoint1: CGPointMake(209.85, 145.37) controlPoint2: CGPointMake(205.78, 155)];
        [bezierPath addCurveToPoint: CGPointMake(226.63, 176.89) controlPoint1: CGPointMake(211.19, 171.64) controlPoint2: CGPointMake(218.42, 176.89)];
        [bezierPath addCurveToPoint: CGPointMake(229.68, 176.64) controlPoint1: CGPointMake(227.65, 176.89) controlPoint2: CGPointMake(228.67, 176.81)];
        [bezierPath addCurveToPoint: CGPointMake(220.99, 203.85) controlPoint1: CGPointMake(229.32, 186.38) controlPoint2: CGPointMake(226.33, 195.73)];
        [bezierPath addCurveToPoint: CGPointMake(207.43, 198.15) controlPoint1: CGPointMake(217.44, 200.21) controlPoint2: CGPointMake(212.59, 198.15)];
        [bezierPath addCurveToPoint: CGPointMake(196.32, 201.76) controlPoint1: CGPointMake(203.42, 198.15) controlPoint2: CGPointMake(199.58, 199.39)];
        [bezierPath addCurveToPoint: CGPointMake(190.77, 225.99) controlPoint1: CGPointMake(188.6, 207.37) controlPoint2: CGPointMake(186.33, 217.73)];
        [bezierPath addCurveToPoint: CGPointMake(176.38, 227.95) controlPoint1: CGPointMake(186.1, 227.29) controlPoint2: CGPointMake(181.27, 227.95)];
        [bezierPath closePath];
        [color7 setFill];
        [bezierPath fill];
        
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
        [bezier2Path moveToPoint: CGPointMake(195.95, 126.32)];
        [bezier2Path addCurveToPoint: CGPointMake(216.04, 140.83) controlPoint1: CGPointMake(203.73, 129.47) controlPoint2: CGPointMake(210.59, 134.42)];
        [bezier2Path addCurveToPoint: CGPointMake(207.46, 164.21) controlPoint1: CGPointMake(208.3, 145.62) controlPoint2: CGPointMake(204.57, 155.3)];
        [bezier2Path addCurveToPoint: CGPointMake(226.63, 178.14) controlPoint1: CGPointMake(210.17, 172.54) controlPoint2: CGPointMake(217.88, 178.14)];
        [bezier2Path addCurveToPoint: CGPointMake(228.36, 178.07) controlPoint1: CGPointMake(227.21, 178.14) controlPoint2: CGPointMake(227.78, 178.12)];
        [bezier2Path addCurveToPoint: CGPointMake(220.75, 201.9) controlPoint1: CGPointMake(227.8, 186.55) controlPoint2: CGPointMake(225.2, 194.68)];
        [bezier2Path addCurveToPoint: CGPointMake(207.43, 196.89) controlPoint1: CGPointMake(217.1, 198.68) controlPoint2: CGPointMake(212.4, 196.89)];
        [bezier2Path addCurveToPoint: CGPointMake(195.59, 200.74) controlPoint1: CGPointMake(203.16, 196.89) controlPoint2: CGPointMake(199.06, 198.22)];
        [bezier2Path addCurveToPoint: CGPointMake(188.98, 225.17) controlPoint1: CGPointMake(187.79, 206.41) controlPoint2: CGPointMake(185.21, 216.62)];
        [bezier2Path addCurveToPoint: CGPointMake(176.39, 226.7) controlPoint1: CGPointMake(184.87, 226.18) controlPoint2: CGPointMake(180.65, 226.7)];
        [bezier2Path addCurveToPoint: CGPointMake(163.8, 225.17) controlPoint1: CGPointMake(172.12, 226.7) controlPoint2: CGPointMake(167.9, 226.18)];
        [bezier2Path addCurveToPoint: CGPointMake(157.18, 200.75) controlPoint1: CGPointMake(167.57, 216.63) controlPoint2: CGPointMake(164.98, 206.41)];
        [bezier2Path addCurveToPoint: CGPointMake(145.34, 196.89) controlPoint1: CGPointMake(153.71, 198.23) controlPoint2: CGPointMake(149.62, 196.89)];
        [bezier2Path addCurveToPoint: CGPointMake(132.02, 201.9) controlPoint1: CGPointMake(140.38, 196.89) controlPoint2: CGPointMake(135.67, 198.69)];
        [bezier2Path addCurveToPoint: CGPointMake(124.42, 178.07) controlPoint1: CGPointMake(127.57, 194.68) controlPoint2: CGPointMake(124.98, 186.55)];
        [bezier2Path addCurveToPoint: CGPointMake(126.13, 178.15) controlPoint1: CGPointMake(124.99, 178.12) controlPoint2: CGPointMake(125.56, 178.15)];
        [bezier2Path addCurveToPoint: CGPointMake(145.31, 164.21) controlPoint1: CGPointMake(134.9, 178.15) controlPoint2: CGPointMake(142.6, 172.55)];
        [bezier2Path addCurveToPoint: CGPointMake(136.73, 140.83) controlPoint1: CGPointMake(148.2, 155.3) controlPoint2: CGPointMake(144.48, 145.62)];
        [bezier2Path addCurveToPoint: CGPointMake(156.82, 126.32) controlPoint1: CGPointMake(142.18, 134.42) controlPoint2: CGPointMake(149.04, 129.47)];
        [bezier2Path addCurveToPoint: CGPointMake(176.38, 141.63) controlPoint1: CGPointMake(159.02, 135.13) controlPoint2: CGPointMake(167.06, 141.63)];
        [bezier2Path addCurveToPoint: CGPointMake(195.95, 126.32) controlPoint1: CGPointMake(185.71, 141.63) controlPoint2: CGPointMake(193.75, 135.12)];
        [bezier2Path closePath];
        [bezier2Path moveToPoint: CGPointMake(193.98, 122.92)];
        [bezier2Path addCurveToPoint: CGPointMake(176.38, 139.12) controlPoint1: CGPointMake(193.24, 131.99) controlPoint2: CGPointMake(185.65, 139.12)];
        [bezier2Path addCurveToPoint: CGPointMake(158.79, 122.92) controlPoint1: CGPointMake(167.12, 139.12) controlPoint2: CGPointMake(159.53, 131.99)];
        [bezier2Path addCurveToPoint: CGPointMake(132.85, 141.65) controlPoint1: CGPointMake(148.37, 126.46) controlPoint2: CGPointMake(139.37, 133.06)];
        [bezier2Path addCurveToPoint: CGPointMake(142.92, 163.44) controlPoint1: CGPointMake(141.31, 145.13) controlPoint2: CGPointMake(145.79, 154.59)];
        [bezier2Path addCurveToPoint: CGPointMake(126.13, 175.64) controlPoint1: CGPointMake(140.5, 170.9) controlPoint2: CGPointMake(133.57, 175.64)];
        [bezier2Path addCurveToPoint: CGPointMake(121.79, 175.1) controlPoint1: CGPointMake(124.7, 175.64) controlPoint2: CGPointMake(123.24, 175.46)];
        [bezier2Path addCurveToPoint: CGPointMake(131.65, 205.89) controlPoint1: CGPointMake(121.9, 186.55) controlPoint2: CGPointMake(125.53, 197.15)];
        [bezier2Path addCurveToPoint: CGPointMake(145.34, 199.4) controlPoint1: CGPointMake(135.11, 201.64) controlPoint2: CGPointMake(140.19, 199.4)];
        [bezier2Path addCurveToPoint: CGPointMake(155.7, 202.77) controlPoint1: CGPointMake(148.94, 199.4) controlPoint2: CGPointMake(152.57, 200.5)];
        [bezier2Path addCurveToPoint: CGPointMake(160.1, 226.73) controlPoint1: CGPointMake(163.36, 208.34) controlPoint2: CGPointMake(165.23, 218.9)];
        [bezier2Path addCurveToPoint: CGPointMake(176.38, 229.21) controlPoint1: CGPointMake(165.24, 228.34) controlPoint2: CGPointMake(170.71, 229.21)];
        [bezier2Path addCurveToPoint: CGPointMake(192.67, 226.73) controlPoint1: CGPointMake(182.06, 229.21) controlPoint2: CGPointMake(187.53, 228.34)];
        [bezier2Path addCurveToPoint: CGPointMake(197.06, 202.77) controlPoint1: CGPointMake(187.54, 218.9) controlPoint2: CGPointMake(189.41, 208.34)];
        [bezier2Path addCurveToPoint: CGPointMake(207.43, 199.4) controlPoint1: CGPointMake(200.2, 200.5) controlPoint2: CGPointMake(203.83, 199.4)];
        [bezier2Path addCurveToPoint: CGPointMake(221.12, 205.89) controlPoint1: CGPointMake(212.58, 199.4) controlPoint2: CGPointMake(217.66, 201.64)];
        [bezier2Path addCurveToPoint: CGPointMake(230.97, 175.09) controlPoint1: CGPointMake(227.24, 197.15) controlPoint2: CGPointMake(230.87, 186.55)];
        [bezier2Path addCurveToPoint: CGPointMake(226.64, 175.64) controlPoint1: CGPointMake(229.53, 175.46) controlPoint2: CGPointMake(228.07, 175.64)];
        [bezier2Path addCurveToPoint: CGPointMake(209.85, 163.43) controlPoint1: CGPointMake(219.19, 175.64) controlPoint2: CGPointMake(212.27, 170.9)];
        [bezier2Path addCurveToPoint: CGPointMake(219.92, 141.65) controlPoint1: CGPointMake(206.97, 154.59) controlPoint2: CGPointMake(211.46, 145.13)];
        [bezier2Path addCurveToPoint: CGPointMake(193.98, 122.92) controlPoint1: CGPointMake(213.4, 133.06) controlPoint2: CGPointMake(204.4, 126.46)];
        [bezier2Path addLineToPoint: CGPointMake(193.98, 122.92)];
        [bezier2Path closePath];
        [color5 setFill];
        [bezier2Path fill];
    }
    
    
    //// Bezier 3 Drawing
    UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
    [bezier3Path moveToPoint: CGPointMake(342.14, 119.89)];
    [bezier3Path addLineToPoint: CGPointMake(326.25, 113.53)];
    [bezier3Path addCurveToPoint: CGPointMake(319.24, 98.85) controlPoint1: CGPointMake(324.15, 108.51) controlPoint2: CGPointMake(321.81, 103.61)];
    [bezier3Path addLineToPoint: CGPointMake(324.33, 82.51)];
    [bezier3Path addCurveToPoint: CGPointMake(235.61, 11.01) controlPoint1: CGPointMake(303.68, 49.8) controlPoint2: CGPointMake(272.53, 24.39)];
    [bezier3Path addLineToPoint: CGPointMake(220.28, 19.72)];
    [bezier3Path addCurveToPoint: CGPointMake(205.19, 16.26) controlPoint1: CGPointMake(215.34, 18.34) controlPoint2: CGPointMake(210.31, 17.17)];
    [bezier3Path addLineToPoint: CGPointMake(195.28, 1.64)];
    [bezier3Path addCurveToPoint: CGPointMake(175.82, 0.56) controlPoint1: CGPointMake(188.89, 0.93) controlPoint2: CGPointMake(182.4, 0.56)];
    [bezier3Path addCurveToPoint: CGPointMake(84.05, 26.45) controlPoint1: CGPointMake(142.18, 0.56) controlPoint2: CGPointMake(110.76, 10.03)];
    [bezier3Path addLineToPoint: CGPointMake(81.2, 44.54)];
    [bezier3Path addCurveToPoint: CGPointMake(69.89, 53.52) controlPoint1: CGPointMake(77.3, 47.37) controlPoint2: CGPointMake(73.52, 50.36)];
    [bezier3Path addLineToPoint: CGPointMake(51.6, 52.1)];
    [bezier3Path addCurveToPoint: CGPointMake(1.64, 154.54) controlPoint1: CGPointMake(24.69, 79.07) controlPoint2: CGPointMake(6.51, 114.74)];
    [bezier3Path addLineToPoint: CGPointMake(14.22, 168.29)];
    [bezier3Path addCurveToPoint: CGPointMake(14.03, 176.06) controlPoint1: CGPointMake(14.1, 170.86) controlPoint2: CGPointMake(14.03, 173.45)];
    [bezier3Path addCurveToPoint: CGPointMake(14.16, 182.27) controlPoint1: CGPointMake(14.03, 178.14) controlPoint2: CGPointMake(14.09, 180.21)];
    [bezier3Path addLineToPoint: CGPointMake(1.45, 195.9)];
    [bezier3Path addCurveToPoint: CGPointMake(50.42, 298.82) controlPoint1: CGPointMake(5.94, 235.78) controlPoint2: CGPointMake(23.79, 271.62)];
    [bezier3Path addLineToPoint: CGPointMake(68.73, 297.58)];
    [bezier3Path addCurveToPoint: CGPointMake(79.94, 306.66) controlPoint1: CGPointMake(72.33, 300.76) controlPoint2: CGPointMake(76.07, 303.8)];
    [bezier3Path addLineToPoint: CGPointMake(82.62, 324.78)];
    [bezier3Path addCurveToPoint: CGPointMake(175.82, 351.56) controlPoint1: CGPointMake(109.63, 341.74) controlPoint2: CGPointMake(141.58, 351.56)];
    [bezier3Path addCurveToPoint: CGPointMake(193.6, 350.67) controlPoint1: CGPointMake(181.83, 351.56) controlPoint2: CGPointMake(187.75, 351.26)];
    [bezier3Path addLineToPoint: CGPointMake(203.66, 336.12)];
    [bezier3Path addCurveToPoint: CGPointMake(218.76, 332.81) controlPoint1: CGPointMake(208.78, 335.25) controlPoint2: CGPointMake(213.82, 334.14)];
    [bezier3Path addLineToPoint: CGPointMake(234.01, 341.67)];
    [bezier3Path addCurveToPoint: CGPointMake(323.42, 271.04) controlPoint1: CGPointMake(271.08, 328.64) controlPoint2: CGPointMake(302.47, 303.52)];
    [bezier3Path addLineToPoint: CGPointMake(318.48, 254.63)];
    [bezier3Path addCurveToPoint: CGPointMake(325.64, 240.03) controlPoint1: CGPointMake(321.1, 249.9) controlPoint2: CGPointMake(323.49, 245.03)];
    [bezier3Path addLineToPoint: CGPointMake(341.58, 233.82)];
    [bezier3Path addCurveToPoint: CGPointMake(351.32, 176.06) controlPoint1: CGPointMake(347.88, 215.73) controlPoint2: CGPointMake(351.32, 196.3)];
    [bezier3Path addCurveToPoint: CGPointMake(342.14, 119.89) controlPoint1: CGPointMake(351.32, 156.42) controlPoint2: CGPointMake(348.09, 137.53)];
    [bezier3Path closePath];
    [bezier3Path moveToPoint: CGPointMake(176.38, 261.92)];
    [bezier3Path addCurveToPoint: CGPointMake(90.53, 176.06) controlPoint1: CGPointMake(128.97, 261.92) controlPoint2: CGPointMake(90.53, 223.48)];
    [bezier3Path addCurveToPoint: CGPointMake(176.38, 90.2) controlPoint1: CGPointMake(90.53, 128.64) controlPoint2: CGPointMake(128.97, 90.2)];
    [bezier3Path addCurveToPoint: CGPointMake(262.24, 176.06) controlPoint1: CGPointMake(223.8, 90.2) controlPoint2: CGPointMake(262.24, 128.64)];
    [bezier3Path addCurveToPoint: CGPointMake(176.38, 261.92) controlPoint1: CGPointMake(262.24, 223.48) controlPoint2: CGPointMake(223.8, 261.92)];
    [bezier3Path closePath];
    [color6 setFill];
    [bezier3Path fill];
}


@end
