#import <Foundation/Foundation.h>
#import "punkSVG.h"

@class CCSVGSource;


@interface CCSVGCache : NSObject


#pragma mark

+ (CCSVGCache *)sharedSVGCache;

+ (void)purgeSharedSVGCache;


#pragma mark

- (CCSVGSource *)addData:(NSData *)data forKey:(NSString *)key;

- (CCSVGSource *)addFile:(NSString *)name;

- (CCSVGSource *)addSource:(CCSVGSource *)source forKey:(NSString *)key;

- (CCSVGSource *)addPunk:(punkSVG*)punk withName:(NSString*)name;


#pragma mark

- (CCSVGSource *)sourceForKey:(NSString *)key;


#pragma mark

- (void)removeAllSources;

- (void)removeUnusedSources;

- (void)removeSource:(CCSVGSource *)data;

- (void)removeSourceForKey:(NSString *)key;

@end