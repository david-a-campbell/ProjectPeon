#import <Foundation/Foundation.h>

static inline void PeonSetDebugMenuVisible(NSUserDefaults *defaults, BOOL visible) {
    [defaults setBool:visible forKey:@"PeonDebugMenuVisible"];
    if(visible) return;
    [defaults setBool:YES forKey:@"PeonHideFPS"];
    for(NSString *key in @[@"PeonShowPhysicsObjects",@"PeonDisableShipFinishTrigger",@"PeonTeleportCart",@"PeonUnlockAllLevels",@"PeonFreePan"])
        [defaults setBool:NO forKey:key];
}
