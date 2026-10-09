#import <Cocoa/Cocoa.h>
#ifdef __cplusplus
extern "C" {
#endif
void PeonRequestScreenshot(NSString *path);
BOOL PeonCaptureScreenshot(NSString *path);
void PeonCaptureRequestedScreenshot(void);
#ifdef __cplusplus
}
#endif
