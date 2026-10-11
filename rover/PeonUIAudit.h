#import "cocos2d.h"
#import <Foundation/Foundation.h>

// Opt-in instrumentation. Shipping builds never record UI or disable auto-lock.
static inline BOOL PeonUIAuditEnabled(void) {
#if DEBUG
    return [[[NSProcessInfo processInfo] environment][@"PEON_UI_AUDIT"] boolValue];
#else
    return NO;
#endif
}

#ifdef PROJECTPEON_IOS
static void PeonAuditScreenshot(NSString *name) {
    GLint viewport[4]; glGetIntegerv(GL_VIEWPORT,viewport);
    NSUInteger width=viewport[2], height=viewport[3], stride=width*4;
    if (!width || !height) return;
    NSMutableData *pixels=[NSMutableData dataWithLength:stride*height];
    glReadPixels(viewport[0],viewport[1],(GLsizei)width,(GLsizei)height,GL_RGBA,GL_UNSIGNED_BYTE,pixels.mutableBytes);
    NSMutableData *flipped=[NSMutableData dataWithLength:pixels.length];
    for (NSUInteger row=0;row<height;row++) memcpy((char *)flipped.mutableBytes+row*stride,(char *)pixels.bytes+(height-1-row)*stride,stride);
    CGColorSpaceRef color=CGColorSpaceCreateDeviceRGB();
    CGContextRef context=CGBitmapContextCreate(flipped.mutableBytes,width,height,8,stride,color,kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGImageRef image=CGBitmapContextCreateImage(context);
    [UIImagePNGRepresentation([UIImage imageWithCGImage:image]) writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:[name stringByAppendingString:@".png"]] atomically:YES];
    CGImageRelease(image); CGContextRelease(context); CGColorSpaceRelease(color);
}
#endif

// A local request file allows a developer to capture the current frame without
// restarting the app or enabling the automatic walkthrough. Never ships.
static inline void PeonDebugSnapshotTick(CCNode *scene) {
#if DEBUG && defined(PROJECTPEON_IOS)
    static NSTimeInterval checked=0;
    NSTimeInterval now=[NSDate timeIntervalSinceReferenceDate];
    if(now-checked<0.25) return;
    checked=now;
    NSString *requestPath=[NSTemporaryDirectory() stringByAppendingPathComponent:@"PeonSnapshotRequest.txt"];
    NSString *request=[NSString stringWithContentsOfFile:requestPath encoding:NSUTF8StringEncoding error:nil];
    if(!request.length) return;
    PeonAuditScreenshot(@"PeonLiveSnapshot");
    NSDictionary *receipt=@{@"request":request,@"scene":NSStringFromClass(scene.class),@"capturedAt":@([[NSDate date] timeIntervalSince1970])};
    NSData *data=[NSJSONSerialization dataWithJSONObject:receipt options:0 error:nil];
    [data writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"PeonLiveSnapshot.json"] atomically:YES];
    [[NSFileManager defaultManager] removeItemAtPath:requestPath error:nil];
#endif
}

static inline double PeonAuditRound(double value) { return round(value*100)/100; }
static inline void PeonAuditNodes(CCNode *node, NSString *path, NSMutableArray *rows) {
    if (!node.visible || [NSStringFromClass(node.class) hasPrefix:@"CCParticle"]) return;
    if ([node conformsToProtocol:@protocol(CCRGBAProtocol)] && [(id<CCRGBAProtocol>)node opacity]==0) return;
    CGSize size=node.contentSize;
    CGPoint p=[node convertToWorldSpace:CGPointZero];
    CGPoint x=[node convertToWorldSpace:ccp(size.width,0)];
    CGPoint y=[node convertToWorldSpace:ccp(0,size.height)];
    NSMutableDictionary *row=[NSMutableDictionary dictionaryWithDictionary:@{
        @"path":path,@"class":NSStringFromClass(node.class),@"tag":@(node.tag),
        @"origin":@[@(PeonAuditRound(p.x)),@(PeonAuditRound(p.y))],
        @"axes":@[@(PeonAuditRound(x.x-p.x)),@(PeonAuditRound(x.y-p.y)),
                    @(PeonAuditRound(y.x-p.x)),@(PeonAuditRound(y.y-p.y))]}];
    if ([node isKindOfClass:[CCSprite class]] && [node numberOfRunningActions]==0) {
        CGRect crop=CC_RECT_POINTS_TO_PIXELS([(CCSprite *)node textureRect]);
        row[@"sourcePixels"]=@[@(PeonAuditRound(crop.origin.x)),@(PeonAuditRound(crop.origin.y)),@(PeonAuditRound(crop.size.width)),@(PeonAuditRound(crop.size.height))];
    }
    if ([node isKindOfClass:[CCMenu class]] || [node class]==[CCNode class]) [row removeObjectForKey:@"axes"];
    if ([node isKindOfClass:[CCLabelBMFont class]]) {
        row[@"text"]=[(CCLabelBMFont *)node string] ?: @"";
        [rows addObject:row];
        return; // Glyph atlas nodes aren't separate UI elements.
    }
    [rows addObject:row];
    NSMutableDictionary *counts=[NSMutableDictionary dictionary];
    for(CCNode *child in node.children) {
        NSString *kind=NSStringFromClass(child.class);
        NSUInteger index=[counts[kind] unsignedIntegerValue]; counts[kind]=@(index+1);
        PeonAuditNodes(child,[path stringByAppendingFormat:@"/%@[%lu]",kind,(unsigned long)index],rows);
    }
}

static inline void PeonAuditPanels(CCNode *node, NSMutableArray *panels) {
    if (!node.visible) return;
    NSString *kind=NSStringFromClass(node.class);
    if ([@[@"ToolTipMenu",@"PopupMenu",@"SaveMenu",@"LevelSelectMenu",@"LoadingLayer",@"LevelScoreDisplay",@"CartCreationLayer",@"TitleScene"] containsObject:kind]) {
        [panels addObject:node];
        if (![kind isEqualToString:@"CartCreationLayer"]) return;
    }
    for (CCNode *child in node.children) PeonAuditPanels(child,panels);
}

static inline void PeonUIAuditCaptureNamed(CCNode *scene, NSString *fixtureName) {
    if (!PeonUIAuditEnabled() || [CCDirector sharedDirector].isPaused) return;
#ifdef PROJECTPEON_IOS
    // Menus otherwise re-enable auto-lock; keep it disabled throughout an audit.
    [UIApplication sharedApplication].idleTimerDisabled=YES;
#endif
    static NSTimeInterval previous=0;
    NSTimeInterval now=[NSDate timeIntervalSinceReferenceDate];
    if(now-previous<0.25) return; previous=now;
    static NSMutableDictionary *candidates=nil,*since=nil,*emitted=nil;
    if(!candidates) { candidates=[[NSMutableDictionary alloc] init]; since=[[NSMutableDictionary alloc] init]; emitted=[[NSMutableDictionary alloc] init]; }
    NSMutableArray *panels=[NSMutableArray array];
    if(fixtureName) [panels addObject:scene]; else PeonAuditPanels(scene,panels);
    for(CCNode *panel in panels) {
        NSString *key=fixtureName ?: NSStringFromClass(panel.class);
        if([key isEqualToString:@"ToolTipMenu"] || [key isEqualToString:@"PopupMenu"])
            key=[key stringByAppendingFormat:@":%@",[panel valueForKey:[key isEqualToString:@"ToolTipMenu"] ? @"toolType" : @"type"]];
        if([key isEqualToString:@"SaveMenu"])
            key=[key stringByAppendingString:[panel valueForKey:@"expandedItem"] ? @":expanded" : @":row"];
        NSMutableArray *rows=[NSMutableArray array]; PeonAuditNodes(panel,key,rows);
        NSData *geometry=[NSJSONSerialization dataWithJSONObject:rows options:NSJSONWritingSortedKeys error:nil];
        BOOL terrainCapture=[key hasPrefix:@"terrain-end-"];
        if (terrainCapture && emitted[key]) continue;
        if(![candidates[key] isEqual:geometry]) {
            candidates[key]=geometry;
            if (!terrainCapture || !since[key]) since[key]=@(now);
            if (!terrainCapture) continue;
        }
        if(now-[since[key] doubleValue]<1 || [emitted[key] isEqual:geometry]) continue;
        emitted[key]=geometry;
#ifdef PROJECTPEON_IOS
        PeonAuditScreenshot(key);
#endif
#ifdef PROJECTPEON_MAC
        NSString *platform=@"mac";
#else
        NSString *platform=@"iphone";
#endif
        NSDictionary *record=@{@"platform":platform,@"screen":key,@"logicalCanvas":@[@1024,@768],
            @"presentation":@[@(1024.0*4/3),@768],@"retinaScale":@([CCDirector sharedDirector].winSizeInPixels.width/[CCDirector sharedDirector].winSize.width),@"nodes":rows};
        NSData *data=[NSJSONSerialization dataWithJSONObject:record options:NSJSONWritingSortedKeys error:nil];
        NSString *json=[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        NSString *path=[NSTemporaryDirectory() stringByAppendingPathComponent:@"PeonUIAudit.jsonl"];
        static BOOL created=NO;
        if(!created) { [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil]; created=YES; }
        NSFileHandle *file=[NSFileHandle fileHandleForWritingAtPath:path];
        [file seekToEndOfFile]; [file writeData:[[json stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]]; [file closeFile];
        fprintf(stderr,"PEON_UI_AUDIT_CAPTURE %s\n",key.UTF8String);
    }
}
