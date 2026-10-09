#import "PeonRecordingSettings.h"

@implementation PeonRecordingSwitchFill
- (void)updateDisplayedOpacity:(GLubyte)parentOpacity {
    [super updateDisplayedOpacity:parentOpacity];
    [self updateColor];
}
@end
