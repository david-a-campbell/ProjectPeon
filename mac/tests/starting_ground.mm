#import <Foundation/Foundation.h>
#import "PeonStartingGround.h"
static NSArray *pairs(NSString *outline) { return [outline componentsSeparatedByString:@" "]; }
int main(int argc, const char **argv) {
 @autoreleasepool {
  int maps=0, floors=0;
  for (int planet=1; planet<=3; ++planet) for (int level=1; level<=12; ++level) {
   NSString *path=[NSString stringWithFormat:@"%s/Planet%d/planet%dLevel%d.tmx",argv[1],planet,planet,level];
   NSXMLDocument *xml=[[[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] options:0 error:nil] autorelease];
   NSXMLElement *map=xml.rootElement;
   double height=[[map attributeForName:@"height"].stringValue doubleValue]*[[map attributeForName:@"tileheight"].stringValue doubleValue];
   NSXMLElement *spawn=[[xml nodesForXPath:@"//object[@type='CartPlayerSprite']" error:nil] firstObject];
   double offsetX=0, offsetY=0;
   for (NSXMLElement *property in [spawn nodesForXPath:@"properties/property" error:nil]) {
    NSString *name=[property attributeForName:@"name"].stringValue;
    double value=[[property attributeForName:@"value"].stringValue doubleValue];
    if([name isEqualToString:@"OffsetX"]) offsetX=value;
    if([name isEqualToString:@"OffsetY"]) offsetY=value;
   }
   double right=[[spawn attributeForName:@"x"].stringValue doubleValue]+offsetX+512+1365.333333;
   double surface=height-[[spawn attributeForName:@"y"].stringValue doubleValue]-768+offsetY+126;
   int changed=0;
   for (NSXMLElement *ground in [xml nodesForXPath:@"//object[@type='TexturedGround']" error:nil]) {
    NSString *old=[[[ground nodesForXPath:@"polygon" error:nil] firstObject] attributeForName:@"points"].stringValue;
    if (!old) continue;
    CGPoint origin=CGPointMake([[ground attributeForName:@"x"].stringValue doubleValue],height-[[ground attributeForName:@"y"].stringValue doubleValue]);
    NSString *updated=PeonStartingGroundOutline(old,origin,right,surface);
    if ([old isEqualToString:updated]) continue;
    changed++; floors++;
    NSArray *newPairs=pairs(updated), *oldPairs=pairs(old);
    NSArray *first=[newPairs[1] componentsSeparatedByString:@","], *end=[newPairs[2] componentsSeparatedByString:@","];
    NSCAssert(fabs(origin.y-[first[1] doubleValue]-surface)<0.001,@"Left floor height");
    NSCAssert(fabs(origin.y-[end[1] doubleValue]-surface)<0.001,@"Right floor height");
    NSCAssert(fabs(origin.x+[end[0] doubleValue]-right)<0.001,@"Platform width");
    // Lower cave/switchback vertices beneath the starting footprint must
    // survive. Earth 12 returns under the spawn thousands of pixels below it.
    BOOL reachedFarTerrain=NO;
    for(NSString *pair in oldPairs) {
     NSArray *xy=[pair componentsSeparatedByString:@","];
     double x=origin.x+[xy[0] doubleValue], y=origin.y-[xy[1] doubleValue];
     if(x>right+512) reachedFarTerrain=YES;
     if(!reachedFarTerrain || x>right || y>=surface-768) continue;
     BOOL found=NO;
     for(NSString *candidate in newPairs) {
      NSArray *newXY=[candidate componentsSeparatedByString:@","];
      if(fabs([xy[0] doubleValue]-[newXY[0] doubleValue])<0.001 &&
         fabs([xy[1] doubleValue]-[newXY[1] doubleValue])<0.001) { found=YES; break; }
     }
     NSCAssert(found,@"Lower terrain underneath the starting area was removed in %@",path);
    }
    // The remaining terrain must be an unchanged suffix of the map outline.
    NSUInteger suffix=newPairs.count-4;
    NSCAssert(suffix>0 && suffix<oldPairs.count,@"Terrain suffix");
    for(NSUInteger i=0;i<suffix;i++) {
     NSArray *a=[newPairs[4+i] componentsSeparatedByString:@","], *b=[oldPairs[oldPairs.count-suffix+i] componentsSeparatedByString:@","];
     NSCAssert(fabs([a[0] doubleValue]-[b[0] doubleValue])<0.001 && fabs([a[1] doubleValue]-[b[1] doubleValue])<0.001,@"Distant terrain changed");
    }
    for(NSUInteger i=1;i<newPairs.count;i++) {
     NSArray *a=[newPairs[i-1] componentsSeparatedByString:@","], *b=[newPairs[i] componentsSeparatedByString:@","];
     NSCAssert(fabs([a[0] doubleValue]-[b[0] doubleValue])+fabs([a[1] doubleValue]-[b[1] doubleValue])>0.0001,@"Duplicate point");
    }
   }
   NSCAssert(changed==1,@"Expected one starting floor in %@, got %d",path,changed);
   maps++;
  }
  printf("All %d maps: %d flat starting floors match block height/width; distant terrain preserved: PASS\n",maps,floors);
 }
 return 0;
}
