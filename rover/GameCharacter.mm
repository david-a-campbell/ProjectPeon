//  GameCharacter.m
//  SpaceViking

#import "GameCharacter.h"

@implementation GameCharacter
@synthesize characterHealth;
@synthesize characterState; 

-(void) dealloc { 
    [super dealloc];
}

-(int)getWeaponDamage {
    // Default to zero damage
    CCLOG(@"getWeaponDamage should be overriden");
    return 0;
}

@end
