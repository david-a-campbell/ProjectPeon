#import "PeonRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <QuartzCore/QuartzCore.h>
int main(void) { @autoreleasepool {
 CGLPixelFormatAttribute attrs[]={kCGLPFAAllowOfflineRenderers,0}; CGLPixelFormatObj fmt; CGLContextObj ctx; GLint count;
 NSCAssert(CGLChoosePixelFormat(attrs,&fmt,&count)==0,@"Format"); NSCAssert(CGLCreateContext(fmt,NULL,&ctx)==0,@"Context"); CGLDestroyPixelFormat(fmt); CGLSetCurrentContext(ctx);
 GLuint texture,fb; glGenTextures(1,&texture); glBindTexture(GL_TEXTURE_2D,texture); glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,1024,768,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
 glGenFramebuffersEXT(1,&fb); glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,fb); glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,texture,0); glViewport(0,0,1024,768);
 NSURL *desktop=[[[NSFileManager defaultManager] URLsForDirectory:NSDesktopDirectory inDomains:NSUserDomainMask] firstObject];
 NSSet *before=[NSSet setWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:desktop.path error:NULL]];
 NSCAssert(![PeonRecorder recordingEnabled],@"Recording should default to off in a clean test domain");
 [[PeonRecorder sharedRecorder] beginGameplay];
 NSCAssert(![[[PeonRecorder sharedRecorder] valueForKey:@"capturing"] boolValue],@"Disabled recording started capturing");
 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"PeonRecordingEnabled"];
 PeonRecorder *rec=[PeonRecorder sharedRecorder]; [rec beginGameplay]; [NSThread sleepForTimeInterval:0.2]; double total=0;
 for(int i=0;i<140;i++) { glClearColor(0,0,1,1); glClear(GL_COLOR_BUFFER_BIT); glEnable(GL_SCISSOR_TEST); glScissor(0,0,1024,384); glClearColor(1,0,0,1); glClear(GL_COLOR_BUFFER_BIT); glDisable(GL_SCISSOR_TEST); double start=CACurrentMediaTime(); [rec captureFrame]; total+=CACurrentMediaTime()-start; GLint binding; glGetIntegerv(GL_FRAMEBUFFER_BINDING_EXT,&binding); NSCAssert(binding==fb,@"Framebuffer not restored"); GLint packBuffer; glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING,&packBuffer); NSCAssert(packBuffer==0,@"Pixel transfer buffer not restored"); [NSThread sleepForTimeInterval:0.018]; }
 [rec finishScorePresentation];
 NSCAssert([[rec valueForKey:@"capturing"] boolValue],@"Stopped before score presentation finished");
 [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
 [rec captureFrame];
 [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.6]];
 NSCAssert(![[rec valueForKey:@"capturing"] boolValue],@"Recording did not stop after presentation");
 [rec exportVideo]; NSURL *output=nil; NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:15];
 while(!output && deadline.timeIntervalSinceNow>0) { [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]]; for(NSString *name in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:desktop.path error:NULL]) if(![before containsObject:name] && [name hasPrefix:@"Project Peon "] && [name hasSuffix:@".mp4"]) output=[desktop URLByAppendingPathComponent:name]; }
 NSCAssert(output,@"Export missing"); AVURLAsset *asset=[AVURLAsset URLAssetWithURL:output options:nil]; AVAssetTrack *track=[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject]; NSCAssert(track.naturalSize.width==1024 && track.naturalSize.height==768 && CMTimeGetSeconds(asset.duration)>1,@"Invalid video"); NSCAssert(track.nominalFrameRate>40 && track.nominalFrameRate<=61,@"Wrong recording frame rate"); NSCAssert(glGetError()==GL_NO_ERROR,@"OpenGL capture error");
 AVAssetReader *reader=[[[AVAssetReader alloc] initWithAsset:asset error:NULL] autorelease];
 AVAssetReaderTrackOutput *samples=[AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)}];
 [reader addOutput:samples]; NSCAssert([reader startReading],@"Cannot read exported video");
 CMSampleBufferRef first=[samples copyNextSampleBuffer];
 NSCAssert(first && CMTimeCompare(CMSampleBufferGetPresentationTimeStamp(first),kCMTimeZero)==0,@"Video starts with an empty/black interval");
 if(first) CFRelease(first); [reader cancelReading];
 AVAssetImageGenerator *generator=[AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
 generator.requestedTimeToleranceBefore=kCMTimeZero; generator.requestedTimeToleranceAfter=kCMTimeZero;
 CGImageRef image=[generator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:NULL];
 NSCAssert(image,@"Video cannot be decoded");
 NSBitmapImageRep *bitmap=[[[NSBitmapImageRep alloc] initWithCGImage:image] autorelease];
 NSColor *top=[[bitmap colorAtX:100 y:50] colorUsingColorSpace:NSColorSpace.deviceRGBColorSpace];
 NSColor *bottom=[[bitmap colorAtX:100 y:660] colorUsingColorSpace:NSColorSpace.deviceRGBColorSpace];
 NSCAssert(top.blueComponent>0.8 && bottom.redComponent>0.8,@"Capture colors or vertical orientation incorrect");
 CGImageRelease(image);
 NSLog(@"PASS: 1024x768 MP4 %.2fs; average capture %.2fms",CMTimeGetSeconds(asset.duration),total/140*1000); [[NSFileManager defaultManager] removeItemAtURL:output error:NULL]; [rec beginGameplay]; [rec discard];
 [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PeonRecordingEnabled"];
 } return 0; }
