#import <Foundation/Foundation.h>

// Release binaries must ignore persisted debug preferences and reveal requests.
static inline BOOL PeonDebugBuildEnabled(void) {
#if DEBUG && !defined(PROJECTPEON_APP_STORE)
    return YES;
#else
    return NO;
#endif
}

static inline void PeonSetDebugMenuVisible(NSUserDefaults *defaults, BOOL visible) {
    visible=visible && PeonDebugBuildEnabled();
    [defaults setBool:visible forKey:@"PeonDebugMenuVisible"];
    if(visible) return;
    [defaults setBool:YES forKey:@"PeonHideFPS"];
    for(NSString *key in @[@"PeonShowPhysicsObjects",@"PeonDisableShipFinishTrigger",@"PeonTeleportCart",@"PeonUnlockAllLevels",@"PeonFreePan"])
        [defaults setBool:NO forKey:key];
}
