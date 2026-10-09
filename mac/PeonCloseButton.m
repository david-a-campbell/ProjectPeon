#import "PeonCloseButton.h"
#import "PeonMac.h"
@implementation PeonCloseMenu
-(void)registerWithTouchDispatcher {
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:self.closePriority swallowsTouches:YES];
}
@end
