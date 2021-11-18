//
//  SaveManager.m
//  rover
//
//  Created by David Campbell on 5/29/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "SaveManager.h"
#import "CartSave.h"
#import "PartSave.h"
#import "AppDelegate.h"
#import "PlayerCart.h"
#import "CartPart.h"
#import "Progress.h"
#import "Planets.h"
#import "Levels.h"
#import "Constants.h"
#import "PlayerSettings.h"
#import "Purchases.h"
#import "UIDevice-Hardware.h"

@implementation SaveManager
@synthesize creationDelegate, offset;

-(id)init
{
    if ((self = [super init]))
    {
        AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        context = [app managedObjectContext];
    }
    return self;
}

-(void)dealloc
{
    [self releaseSavedData];
    [super dealloc];
}

-(void)saveContext
{
    NSError *error;
    if (![context save:&error])
    {
        NSLog(@"Whoops, couldn't save score: %@", [error localizedDescription]);
    }
}

-(void)loadSavedData
{
    [self releaseSavedData];
    savedData = [[NSMutableArray alloc] init];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CartSave" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *temp;
    if (!(temp = [context executeFetchRequest:fetchRequest error:&error]))
    {
        NSLog(@"Whoops, couldn't load cart data: %@", [error localizedDescription]);
    }else {
        [savedData addObjectsFromArray:temp];
    }
    [fetchRequest release];
}

-(void)releaseSavedData
{
    if (savedData != nil)
    {
        [savedData release];
        savedData = nil;
    }    
}

+(SaveManager*)sharedManager
{
    static SaveManager *sharedManager;
    @synchronized(self)
    {
        if (!sharedManager)
        {
            sharedManager = [[SaveManager alloc] init];
        }
        return sharedManager;
    }
}

-(UIImage *)imageForIndex:(int)index
{
    CartSave *cart = [savedData objectAtIndex:index];
    return [cart image];
}

-(int)numberOfSavedCarts
{
    return [savedData count];
}

-(void)deleteCartAtIndex:(int)index
{
    CartSave *savedCart = (CartSave*)[savedData objectAtIndex:index];
    [context deleteObject:savedCart];
    [self saveContext];
    [savedData removeObjectAtIndex:index];
}

-(void)loadCartAtIndex:(int)index
{
    CartSave *cart = [savedData objectAtIndex:index];
    [creationDelegate deleteAllCartParts];
    NSArray *parts = [[cart cartParts] allObjects];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
    NSArray *sortDes = [NSArray arrayWithObjects:sorter, nil];
    parts = [parts sortedArrayUsingDescriptors:sortDes];
    [sorter release];
    for (PartSave *part in parts)
    {
        CGPoint start = CGPointFromString([part start]);
        CGPoint end = CGPointFromString([part end]);
        start = [self convertToActionSpace:start];
        end = [self convertToActionSpace:end];
        switch ([part type].intValue)
        {
            case kBarPartType:
                [creationDelegate createBarWithStart:start andEnd:end];
                break;
            case kMotorPartType:
                [creationDelegate createMotorWithStart:start andEnd:end andType:kMotorPartType];
                break;
            case kMotor50PartType:
                [creationDelegate createMotorWithStart:start andEnd:end andType:kMotor50PartType];
                break;
            case kShockPartType:
                [creationDelegate createShockWithStart:start andEnd:end];
                break;
            case kBoosterPartType:
                [creationDelegate createBoosterWithStart:start andEnd:end andType:kBoosterPartType];
                break;
            case kBooster50PartType:
                [creationDelegate createBoosterWithStart:start andEnd:end andType:kBooster50PartType];
                break;
            case kWheelPartType:
                [creationDelegate createWheelWithStart:start andEnd:end];
                break;
            default:
                break;
        }
    }
}

-(void)saveCart:(PlayerCart *)cart andImage:(UIImage *)image
{
    CartSave *savedCart = [NSEntityDescription insertNewObjectForEntityForName:@"CartSave" inManagedObjectContext:context];
    [savedCart setImage:image];
    int index = 0;
    for (CartPart *part in [cart components])
    {
        if ([part isReadyForRemoval]) {continue;}
        PartSave *savedPart = [NSEntityDescription insertNewObjectForEntityForName:@"PartSave" inManagedObjectContext:context];
        [savedPart setStart: NSStringFromCGPoint([self convertToCreationSpace:part.start])];
        [savedPart setEnd: NSStringFromCGPoint([self convertToCreationSpace:part.end])];
        [savedPart setType: [NSNumber numberWithInt: part.gameObjectType]];
        [savedPart setModifier: [NSNumber numberWithInt: part.cartPartModifier]];
        [savedPart setIndex:[NSNumber numberWithInt:index]];
        [savedCart addCartPartsObject: savedPart];
        index++;
    }
    
    [context insertObject:savedCart];
    [self saveContext];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SAVE_CART_COMPLETE object:nil];
}

-(void)saveCart
{
    [[self creationDelegate] saveCart];
}

//Progress Methods
-(Progress*)getProgressObject
{
    Progress *progress = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Progress" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *temp;
    if (!(temp = [context executeFetchRequest:fetchRequest error:&error]))
    {
        NSLog(@"Whoops, couldn't load progress data: %@", [error localizedDescription]);
    }else {
        if ([temp count] == 0)
        {
            progress = [NSEntityDescription insertNewObjectForEntityForName:@"Progress" inManagedObjectContext:context];
            [self saveContext];
        }
        else
        {
            progress = [temp objectAtIndex:0];
        }
    }
    [fetchRequest release];
    return progress;
}

-(Planets*)getPlanetObject:(int)planetNum
{
    Planets *planet = nil;
    Progress *progress = [self getProgressObject];
    for (Planets *aPlanet in [progress planets])
    {
        if ([[aPlanet planetNumber] intValue] == planetNum)
        {
            planet = aPlanet;
            break;
        }
    }
    
    if (!planet)
    {
        planet = [NSEntityDescription insertNewObjectForEntityForName:@"Planets" inManagedObjectContext:context];
        [planet setPlanetNumber:[NSNumber numberWithInt:planetNum]];
        [progress addPlanetsObject:planet];
        [self saveContext];
    }
    
    return planet;
}

-(Levels*)getLevel:(int)levelNum forPlanet:(int)planetNum
{
    Levels *level = nil;
    Planets *planet = [self getPlanetObject:planetNum];
    for (Levels *aLevel in [planet levels])
    {
        if ([[aLevel levelNumber] intValue] == levelNum)
        {
            level = aLevel;
        }
    }
    
    if (!level)
    {
        level = [NSEntityDescription insertNewObjectForEntityForName:@"Levels" inManagedObjectContext:context];
        [level setLevelNumber:[NSNumber numberWithInt:levelNum]];
        [planet addLevelsObject: level];
        [self saveContext];
    }
    
    return level;
}

-(int)getHighestPlanetUnlocked
{
    int highestPlanet = 1;
    Progress *progress = [self getProgressObject];
    for (Planets *planet in [progress planets])
    {
        if ([[planet planetNumber] intValue] > highestPlanet && [[planet isUnlocked] boolValue])
        {
            highestPlanet = [[planet planetNumber] intValue];
        }
    }
    
    if (highestPlanet == 1)
    {
        Planets *planet = [self getPlanetObject:1];
        [planet setIsUnlocked:@YES];
        [self saveContext];
    }
    
    return highestPlanet;
}

-(int)getHighestLevelUnlockedForPlanet:(int)planetNum
{    
    int highestLevelUnlocked = 0;
    
    Planets *planet = [self getPlanetObject:planetNum];
    for (Levels *level in [planet levels])
    {
        if ([[level levelNumber] intValue] > highestLevelUnlocked && [[level isUnlocked] boolValue])
        {
            highestLevelUnlocked = [[level levelNumber] intValue];
        }
    }
    
    if (planetNum == 1 && highestLevelUnlocked == 0)
    {
        Levels *level = [self getLevel:1 forPlanet:1];
        [level setIsUnlocked:@YES];
        [self saveContext];
        highestLevelUnlocked = 1;
    }
    
    return highestLevelUnlocked;
}

-(int)getPercentageScoreForPlanet:(int)planetNum Level:(int)levelNum
{
    Levels *level = [self getLevel:levelNum forPlanet:planetNum];
    return [[level percentScore] intValue];
}

-(int)getTimeScoreForPlanet:(int)planetNum Level:(int)levelNum
{
    Levels *level = [self getLevel:levelNum forPlanet:planetNum];
    return [[level timeScore] intValue];
}

-(void)addScore:(int)score forLevel:(int)levelNum onPlanet:(int)planetNum
{
    //Unlock the next level or planet
    if(score >= UnlockScore)
    {
        if (levelNum < [self numberOfLevelsForPlanetNumber:planetNum])
        {
            [[self getLevel:levelNum+1 forPlanet:planetNum] setIsUnlocked:@YES];
        }else // unlock next planet and the first level on that planet
        {
            [[self getPlanetObject:planetNum+1] setIsUnlocked:@YES];
            [[self getLevel:1 forPlanet:planetNum+1] setIsUnlocked:@YES];
        }
    }
    
    if ([self getPercentageScoreForPlanet:planetNum Level:levelNum]>=score)
    {
        return;
    }
    Levels *level = [self getLevel:levelNum forPlanet:planetNum];
    [level setPercentScore:[NSNumber numberWithInt:score]];

    [self saveContext];
}

-(void)addTime:(int)time forLevel:(int)levelNum onPlanet:(int)planetNum
{
    float currentBestTime = [self getTimeScoreForPlanet:planetNum Level:levelNum];
    if (currentBestTime<=time && currentBestTime !=0)
    {
        return;
    }
    Levels *level = [self getLevel:levelNum forPlanet:planetNum];
    [level setTimeScore:[NSNumber numberWithInt:time]];
    
    [self saveContext];
}

//For Debugging
-(void)forceLockState:(BOOL)unlocked forLevel:(int)levelNum planet:(int)planetNum
{
    Levels *level = [self getLevel:levelNum forPlanet:planetNum];
    [level setIsUnlocked:[NSNumber numberWithBool:unlocked]];
    [self saveContext];
}

//PlayerSettings Methods
-(void)setShowToolTipsState:(BOOL)value
{
    PlayerSettings *playerSettings = [self getPlayerSettingsObject];
    [playerSettings setShowToolTips:[NSNumber numberWithBool:value]];
    
    [self saveContext];
}

-(BOOL)getShowToolTipsState
{
    PlayerSettings *playerSettings = [self getPlayerSettingsObject];
    return [[playerSettings showToolTips] boolValue];
}

-(void)setShowTutorialState:(BOOL)value
{
    PlayerSettings *playerSettings = [self getPlayerSettingsObject];
    [playerSettings setShowTutorial:[NSNumber numberWithBool:value]];
    
    [self saveContext];
}

-(BOOL)getShowTutorialState
{
    PlayerSettings *playerSettings = [self getPlayerSettingsObject];
    return [[playerSettings showTutorial] boolValue];
}

-(void)setIsRetinaEnabled:(BOOL)value
{
    PlayerSettings *playerSettings = [self getPlayerSettingsObject];
    [playerSettings setIsRetinaEnabled:[NSNumber numberWithBool:value]];
    
    [self saveContext];
}

-(BOOL)isRetinaEnabled
{
    PlayerSettings *playerSettings = [self getPlayerSettingsObject];
    return [[playerSettings isRetinaEnabled] boolValue];
}

-(void)setUseTouchControl:(BOOL)value
{
    PlayerSettings *playerSettings = [self getPlayerSettingsObject];
    [playerSettings setUseTouchControl:[NSNumber numberWithBool:value]];
    
    [self saveContext];
    [[NSNotificationCenter defaultCenter] postNotificationName: NOTIFICATION_CONTROL_TYPE_CHANGED object:nil];
}

-(BOOL)useTouchControl
{
    PlayerSettings *playerSettings = [self getPlayerSettingsObject];
    return [[playerSettings useTouchControl] boolValue];
}

-(void)setMusicVolume:(float)musicVolume
{
    PlayerSettings *playerSettings = [self getPlayerSettingsObject];
    [playerSettings setMusicVolume:[NSNumber numberWithFloat:musicVolume]];
    
    [self saveContext];
}

-(float)getMusicVolume
{
    PlayerSettings *playerSettings = [self getPlayerSettingsObject];
    return [[playerSettings musicVolume] floatValue];
}

-(void)setSfxVolume:(float)sfxVolume
{
    PlayerSettings *playerSettings = [self getPlayerSettingsObject];
    [playerSettings setSfxVolume:[NSNumber numberWithFloat:sfxVolume]];
    
    [self saveContext];
}

-(float)getSfxVolume
{
    PlayerSettings *playerSettings = [self getPlayerSettingsObject];
    return [[playerSettings sfxVolume] floatValue];
}

//Progress Methods
-(PlayerSettings*)getPlayerSettingsObject
{
    PlayerSettings *playerSettings = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PlayerSettings" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *temp;
    if (!(temp = [context executeFetchRequest:fetchRequest error:&error]))
    {
        NSLog(@"Whoops, couldn't load player settings data: %@", [error localizedDescription]);
    }else {
        if ([temp count] == 0)
        {
            playerSettings = [self createPlayerSettingsData];
        }
        else {playerSettings = [temp objectAtIndex:0];}
    }
    [fetchRequest release];
    return playerSettings;
}

-(PlayerSettings*)createPlayerSettingsData
{
    PlayerSettings *playerSettings = [NSEntityDescription insertNewObjectForEntityForName:@"PlayerSettings" inManagedObjectContext:context];
    [playerSettings setShowToolTips:@YES];
    [playerSettings setShowTutorial:@YES];
    BOOL retinaOn = YES;
    if ([self isOlderiPad3] || !IS_RETINA)
    {
        retinaOn = NO;
    }
    [playerSettings setIsRetinaEnabled:[NSNumber numberWithBool:retinaOn]];
    [playerSettings setUseTouchControl:@NO];
    [playerSettings setMusicVolume:[NSNumber numberWithFloat:0.75f]];
    [playerSettings setSfxVolume:[NSNumber numberWithFloat:0.25f]];
    [self saveContext];
    return playerSettings;
}

//Purchases

-(BOOL)hasBooster50Unlocked
{
  return YES;
}

-(BOOL)hasMotor50Unlocked
{
  return YES;
}

-(BOOL)hasAnyPurchases
{
    return [self hasBooster50Unlocked] || [self hasMotor50Unlocked];
}

-(Purchases*)getPurchasesObject
{
    Purchases *purchases = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Purchases" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *temp;
    if (!(temp = [context executeFetchRequest:fetchRequest error:&error]))
    {
        NSLog(@"Whoops, couldn't load purchases data: %@", [error localizedDescription]);
    }else {
        if ([temp count] == 0)
        {
            purchases = [self createPurchasesData];
        }
        else {purchases = [temp objectAtIndex:0];}
    }
    [fetchRequest release];
    return purchases;
}

-(Purchases*)createPurchasesData
{
    Purchases *purchases = [NSEntityDescription insertNewObjectForEntityForName:@"Purchases" inManagedObjectContext:context];
    [purchases setHasBooster50:@NO];
    [purchases setHasMotor50:@NO];
    [self saveContext];
    return purchases;
}

//Utility
-(int)numberOfLevelsForPlanetNumber:(int)planetNum
{
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"PlanetList.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:@"PlanetList" ofType:@"plist"];
    }
    
    NSDictionary *plistDictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    if (plistDictionary == nil) {
        CCLOG(@"Error reading PlanetList.plist");
        return 0; // No Plist Dictionary or file found
    }
    
    NSArray *planetData = [plistDictionary objectForKey:[NSString stringWithFormat:@"Planet%i", planetNum]];
    return [planetData count];
}

-(int)numberOfPlanets
{
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"PlanetList.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:@"PlanetList" ofType:@"plist"];
    }
    
    NSDictionary *plistDictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    if (plistDictionary == nil) {
        CCLOG(@"Error reading PlanetList.plist");
        return 0; // No Plist Dictionary or file found
    }
    
    return [plistDictionary count];
}

-(CGPoint)convertToCreationSpace:(CGPoint)location
{
    CGPoint createLoc = ccp(location.x+offset.x, location.y+offset.y);
    return createLoc;
}

-(CGPoint)convertToActionSpace:(CGPoint)location
{
    CGPoint createLoc = ccp(location.x-offset.x, location.y-offset.y);
    return createLoc;
}

-(BOOL)isOlderiPad3
{
    NSString *device = [[UIDevice currentDevice] platform];
    if ([device isEqualToString:@"iPad3,1"] || [device isEqualToString:@"iPad3,2"] || [device isEqualToString:@"iPad3,3"])
    {
        return YES;
    }
    return NO;
}
@end
