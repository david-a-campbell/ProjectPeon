#import "../PeonDebugSettings.h"

int main(void) {
    @autoreleasepool {
        NSString *suite=[@"PeonDebugGateTest." stringByAppendingString:[[NSUUID UUID] UUIDString]];
        NSUserDefaults *defaults=[[NSUserDefaults alloc] initWithSuiteName:suite];
        NSArray *options=@[@"PeonShowPhysicsObjects",@"PeonDisableShipFinishTrigger",@"PeonTeleportCart",@"PeonUnlockAllLevels",@"PeonFreePan"];
        // Simulate preferences left by an earlier development installation.
        [defaults setBool:YES forKey:@"PeonDebugMenuVisible"];
        [defaults setBool:NO forKey:@"PeonHideFPS"];
        for(NSString *key in options) [defaults setBool:YES forKey:key];
        PeonSetDebugMenuVisible(defaults,YES);
#if DEBUG && !defined(PROJECTPEON_APP_STORE)
        NSCAssert([defaults boolForKey:@"PeonDebugMenuVisible"],@"Development debug reveal was blocked");
#else
        NSCAssert(![defaults boolForKey:@"PeonDebugMenuVisible"],@"Release allowed debug reveal");
        NSCAssert([defaults boolForKey:@"PeonHideFPS"],@"Release left FPS enabled");
        for(NSString *key in options) NSCAssert(![defaults boolForKey:key],@"Release left a debug option enabled");
#endif
        PeonSetDebugMenuVisible(defaults,NO);
        NSCAssert(![defaults boolForKey:@"PeonDebugMenuVisible"],@"Debug hide failed");
#if DEBUG && !defined(PROJECTPEON_APP_STORE)
        NSCAssert(![defaults boolForKey:@"PeonHideFPS"],@"Debug hide reset FPS");
        for(NSString *key in options) NSCAssert([defaults boolForKey:key],@"Debug hide reset an option");
        PeonSetDebugMenuVisible(defaults,YES);
        for(NSString *key in options) NSCAssert([defaults boolForKey:key],@"Debug reveal reset an option");
#else
        for(NSString *key in options) NSCAssert(![defaults boolForKey:key],@"Release left an option enabled");
#endif
        [defaults removePersistentDomainForName:suite];
        [defaults release];
        puts("Debug build gate passed");
    }
    return 0;
}
