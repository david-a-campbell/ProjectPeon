#import "PeonUIAudit.h"
#if PEON_DEVELOPMENT_AUDIT
#import "ToolTipMenu.h"
#import "PopupMenu.h"
#import "SaveMenu.h"
#import "SaveMenuItem.h"
#import "LevelScoreDisplay.h"
#import "Constants.h"
#import "GameManager.h"

@interface NSObject (TerrainUIAudit)
+(CCNode *)endOfMap:(NSString *)map;
@end

@interface PopupMenu (UIAudit)
-(void)switchToMenu:(PopupType)type;
-(void)showPreviousMenu;
@end

@interface LevelScoreDisplay (UIAudit)
-(void)slideMenuIn;
@end
@interface ToolTipMenu (UIAudit)
-(id)initForToolType:(ToolType)type;
@end
@interface SaveMenu (UIAudit)
-(void)setupScrollview;
-(void)setOpacity:(GLubyte)opacity;
@end
@interface SaveMenuItem (UIAudit)
-(void)expandView;
@end
// The results fixture exercises the actual presentation without writing scores.
@interface PeonAuditScore : LevelScoreDisplay
@end
@implementation PeonAuditScore
-(void)saveData {}
@end

// A deterministic, non-destructive walkthrough: no cart saves, deletes, purchases,
// unlocks or score writes. Runs only when explicitly enabled on a Debug launch.
static CCNode *PeonUIAuditFixtureTick(CCNode *scene, NSString **label) {
    if(!PeonUIAuditEnabled() || ![[NSProcessInfo processInfo].environment[@"PEON_UI_AUDIT_FIXTURES"] boolValue]) return nil;
    static NSTimeInterval started=0;
    static NSInteger previous=-1;
    static CCNode *fixture=nil;
    static NSString *name=nil;
    NSTimeInterval now=[NSDate timeIntervalSinceReferenceDate];
    if(!started) {
        started=now;
        for(NSString *atlas in @[@"menuItemsAtlas.plist",@"popupBacking.plist",@"spriteAtlas.plist",@"spriteAtlas2.plist"])
            [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:atlas];
    }
#ifdef PROJECTPEON_IOS
    static BOOL auditedTiltPan=NO;
    if (!auditedTiltPan && [[NSProcessInfo processInfo].environment[@"PEON_TILT_PAN_AUDIT"] boolValue]) {
        auditedTiltPan=YES;
        CCNode *controls=[NSClassFromString(@"ControlsLayer") node];
        [controls performSelector:@selector(debugAuditTiltPan)];
    }
#endif
    NSInteger phase=(NSInteger)((now-started)/4);
    if([CCDirector sharedDirector].isPaused) { started+=now-(started+4*phase); *label=nil; return nil; }
    if(phase==previous) { *label=name; return fixture; }
    previous=phase;
    if ([[NSProcessInfo processInfo].environment[@"PEON_UI_AUDIT_DEBUG"] boolValue]) {
        static NSDictionary *savedDebug=nil;
        static BOOL debugFinished=NO;
        if (debugFinished) { *label=nil; return nil; }
        NSArray *keys=@[@"PeonDebugMenuVisible",@"PeonHideFPS",@"PeonShowPhysicsObjects",@"PeonDisableShipFinishTrigger",@"PeonTeleportCart",@"PeonUnlockAllLevels",@"PeonFreePan"];
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        if (!savedDebug) {
            NSMutableDictionary *saved=[NSMutableDictionary dictionary];
            for (NSString *key in keys) saved[key]=[defaults objectForKey:key] ?: [NSNull null];
            savedDebug=[saved copy];
            for (NSString *key in keys) [defaults setBool:[key isEqualToString:@"PeonHideFPS"] forKey:key];
        }
        [fixture removeFromParentAndCleanup:YES]; [fixture release]; fixture=nil; [name release]; name=nil;
        if (phase>=3) {
            debugFinished=YES;
            [[GameManager sharedGameManager] setIsPaused:NO];
            for (NSString *key in keys) {
                if (savedDebug[key]==[NSNull null]) [defaults removeObjectForKey:key]; else [defaults setObject:savedDebug[key] forKey:key];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PeonDebugOptionsChanged" object:nil];
            fprintf(stderr,"PEON_DEBUG_AUDIT_PASS: ten-tap reveal/hide and option reset\n"); *label=nil; return nil;
        }
        if (phase==1) {
            [defaults setBool:NO forKey:@"PeonHideFPS"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PeonDebugOptionsChanged" object:nil];
        }
        fixture=[[PopupMenu alloc] initForType:phase==1 ? kPopupDebug : kPopupGameInfo andDelegate:nil];
        name=[[NSString stringWithFormat:@"fixture-debug-%ld",(long)phase] retain];
        [scene addChild:fixture z:1000000];
        if (phase!=1) {
            if (phase==2) for (NSString *key in keys) [defaults setBool:![key isEqualToString:@"PeonHideFPS"] forKey:key];
            id credits=[fixture valueForKey:@"currentOptions"];
            for (int tap=0;tap<9;tap++) [credits performSelector:@selector(tapProgrammingCredit)];
            NSCAssert([defaults boolForKey:@"PeonDebugMenuVisible"]==(phase==2),@"Debug toggled before ten taps");
            [credits performSelector:@selector(tapProgrammingCredit)];
            NSCAssert([defaults boolForKey:@"PeonDebugMenuVisible"]==(phase==0),@"Credits did not toggle Debug");
            if (phase==2) for (NSString *key in keys) NSCAssert([defaults boolForKey:key]==[key isEqualToString:@"PeonHideFPS"],@"Debug hide left an option active");
        }
        *label=name; return fixture;
    }
    NSString *map=[NSProcessInfo processInfo].environment[@"PEON_UI_AUDIT_MAP"];
    if (map.length) {
        if (!fixture) {
            fixture=[[NSClassFromString(@"PeonTerrainAudit") endOfMap:map] retain];
            [scene addChild:fixture z:10000000];
            name=[[@"terrain-end-" stringByAppendingString:map] retain];
        }
        *label=name; return fixture;
    }
    if ([[NSProcessInfo processInfo].environment[@"PEON_UI_AUDIT_WORKSHOP"] boolValue]) {
        if (!fixture) {
            fixture=[[PopupMenu alloc] initForType:kPopupStore andDelegate:nil];
            [scene addChild:fixture z:10000000];
            name=[@"fixture-workshop" retain];
        }
        *label=name; return fixture;
    }
    if ([[NSProcessInfo processInfo].environment[@"PEON_UI_AUDIT_SETTINGS"] boolValue]) {
        if (!fixture) {
            fixture=[[PopupMenu alloc] initForType:kPopupTypeCartCreation andDelegate:nil];
            [scene addChild:fixture z:10000000];
        } else if (phase==1 || phase==3) [(PopupMenu *)fixture switchToMenu:kPopupSettings];
        else if (phase==2) [(PopupMenu *)fixture showPreviousMenu];
        [name release]; name=[[NSString stringWithFormat:@"settings-transition-%ld",(long)MIN(phase,3)] retain];
        *label=name; return fixture;
    }
    [fixture removeFromParentAndCleanup:YES]; [fixture release]; fixture=nil;
    [name release]; name=nil;
    if(phase<8) {
        ToolType tools[]={toolTypeBar,toolTypeWheel,toolTypeMotor,toolTypeShock,toolTypeBooster,toolTypeDelete,toolTypeSave,toolTypeEdit};
        fixture=[[[ToolTipMenu alloc] initForToolType:tools[phase]] autorelease];
        name=[NSString stringWithFormat:@"fixture-tooltip-%d",tools[phase]];
    } else if(phase<12) {
        PopupType types[]={kPopupGameInfo,kPopupTitleSettings,kPopupTypeCartCreation,kPopupTypeGamePlay};
        fixture=[[[PopupMenu alloc] initForType:types[phase-8] andDelegate:nil] autorelease];
        name=[NSString stringWithFormat:@"fixture-popup-%d",types[phase-8]];
    } else if(phase<14) {
        SaveMenu *save=[SaveMenu node];
        NSString *path=[[CCFileUtils sharedFileUtils] fullPathFromRelativePath:@"MenuGridWide.png"];
        UIImage *image=[[[UIImage alloc] initWithContentsOfFile:path] autorelease];
        SaveMenuItem *item=[[[SaveMenuItem alloc] initWithImage:image andIndex:0] autorelease];
        item.saveDelegate=(id)save;
        SaveMenuItem *newItem=[[[SaveMenuItem alloc] initAsSaveItem] autorelease];
        [save setValue:[NSMutableArray arrayWithObjects:newItem,item,nil] forKey:@"saveMenuItemList"];
        [save setupScrollview]; [save setOpacity:255];
        if(phase==13) [item expandView];
        fixture=save; name=phase==12 ? @"fixture-save-row" : @"fixture-save-expanded";
    } else if(phase==14) {
        PeonAuditScore *score=[PeonAuditScore node];
        [score showScore:28 peonCount:3 totalPeons:10 timerColor:(ColorStates)0 tmerState:kState5Fade timeElapsed:26];
        [score stopAllActions]; [score slideMenuIn];
        fixture=score; name=@"fixture-results";
    } else {
        fprintf(stderr,"PEON_UI_AUDIT_DONE\n");
        name=nil; *label=nil; return nil;
    }
    [fixture retain];
    [scene addChild:fixture z:10000000];
    name=[name retain]; // Keep the label across autorelease pools.
    *label=name; return fixture;
}

#endif // PEON_DEVELOPMENT_AUDIT
