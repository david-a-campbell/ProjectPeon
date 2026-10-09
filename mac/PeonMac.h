#import "cocos2d.h"
#import "Platforms/iOS/CCTouchDispatcher.h"
@interface CCDirector (PeonPointer)
- (CCTouchDispatcher *)touchDispatcher;
@end
@interface CCRenderTexture (PeonImage)
- (NSImage *)getUIImage;
@end
BOOL PeonKeyDown(unsigned short code);
