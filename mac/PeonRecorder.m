#import "PeonRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <VideoToolbox/VideoToolbox.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
// Keep readback small and bound encoding to one pending frame. Never wait for the encoder.
@implementation PeonRecorder {
    dispatch_queue_t queue;
    dispatch_semaphore_t slot;
    AVAssetWriter *writer;
    CMTime firstFrameTime;
    BOOL sessionStarted;
    AVAssetWriterInput *input;
    AVAssetWriterInputPixelBufferAdaptor *adaptor;
    NSURL *file;
    BOOL capturing;
    CFTimeInterval started;
    int64_t lastCaptureTick;
    GLuint framebuffer,texture;
    GLuint transfers[2],fences[2];
    BOOL pending[2];
    CMTime timestamps[2];
    NSUInteger generation,transferGeneration[2];
}
+ (instancetype)sharedRecorder { static id instance; static dispatch_once_t once; dispatch_once(&once,^{instance=[self new];}); return instance; }
- (id)init { if((self=[super init])) { queue=dispatch_queue_create("com.projectpeon.recorder",DISPATCH_QUEUE_SERIAL); slot=dispatch_semaphore_create(1); } return self; }
- (void)discard {
    capturing=NO; generation++;
    dispatch_async(queue,^{
        [writer cancelWriting]; [writer release]; writer=nil;
        [input release]; input=nil; [adaptor release]; adaptor=nil;
        if(file) [[NSFileManager defaultManager] removeItemAtURL:file error:NULL];
        [file release]; file=nil;
    });
}
- (void)beginGameplay {
    [self discard]; started=CACurrentMediaTime(); lastCaptureTick=-1; capturing=YES;
    dispatch_async(queue,^{
        file=[[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Peon-%@.mp4",NSUUID.UUID.UUIDString]]] retain];
        writer=[[AVAssetWriter alloc] initWithURL:file fileType:AVFileTypeMPEG4 error:NULL];
        input=[[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:@{AVVideoCodecKey:AVVideoCodecTypeH264,AVVideoWidthKey:@1024,AVVideoHeightKey:@768,AVVideoEncoderSpecificationKey:@{(id)kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder:@YES},AVVideoCompressionPropertiesKey:@{AVVideoAverageBitRateKey:@4000000,AVVideoExpectedSourceFrameRateKey:@60,AVVideoMaxKeyFrameIntervalKey:@120}}] retain];
        input.expectsMediaDataInRealTime=YES;
        adaptor=[[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:input sourcePixelBufferAttributes:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA),(id)kCVPixelBufferWidthKey:@1024,(id)kCVPixelBufferHeightKey:@768}] retain];
        if([writer canAddInput:input]) [writer addInput:input];
        sessionStarted=NO;
        firstFrameTime=kCMTimeInvalid;
        [writer startWriting];
    });
}
- (void)finishGameplay { capturing=NO; }
- (void)enqueuePixels:(NSMutableData *)pixels time:(CMTime)time {
    dispatch_async(queue,^{ @autoreleasepool {
        if(writer.status==AVAssetWriterStatusWriting && input.readyForMoreMediaData) {
            CVPixelBufferRef buffer=NULL;
            if(CVPixelBufferPoolCreatePixelBuffer(NULL,adaptor.pixelBufferPool,&buffer)==kCVReturnSuccess) {
                CVPixelBufferLockBaseAddress(buffer,0);
                size_t stride=CVPixelBufferGetBytesPerRow(buffer);
                for(int y=0;y<768;y++) memcpy((char *)CVPixelBufferGetBaseAddress(buffer)+y*stride,(char *)pixels.bytes+y*1024*4,1024*4);
                CVPixelBufferUnlockBaseAddress(buffer,0);
                // GPU transfer/setup can delay the first image. Anchor the movie to that
                // image rather than leaving an empty interval at the start of the file.
                if(!sessionStarted) {
                    firstFrameTime=time;
                    [writer startSessionAtSourceTime:kCMTimeZero];
                    sessionStarted=YES;
                }
                [adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeSubtract(time,firstFrameTime)]; CVPixelBufferRelease(buffer);
            }
        }
        [pixels release]; dispatch_semaphore_signal(slot);
    }});
}
- (void)captureFrame {
    if(!capturing) return;
    GLint previousPackBuffer; glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING,&previousPackBuffer);
    // Poll previously submitted transfers. Mapping is safe only after the GPU fence signals.
    // Process in timestamp order, including when the two slots wrap around.
    int first=(pending[1] && (!pending[0] || CMTimeCompare(timestamps[1],timestamps[0])<0)) ? 1 : 0;
    for(int n=0;n<2;n++) {
        int i=(first+n)%2;
        if(!pending[i]) continue;
        if(!glTestFenceAPPLE(fences[i])) break;
        pending[i]=NO;
        if(transferGeneration[i]!=generation) continue;
        if(dispatch_semaphore_wait(slot,DISPATCH_TIME_NOW)) continue;
        glBindBuffer(GL_PIXEL_PACK_BUFFER,transfers[i]);
        const void *mapped=glMapBuffer(GL_PIXEL_PACK_BUFFER,GL_READ_ONLY);
        if(mapped) {
            NSMutableData *pixels=[[NSMutableData alloc] initWithBytes:mapped length:1024*768*4];
            glUnmapBuffer(GL_PIXEL_PACK_BUFFER);
            [self enqueuePixels:pixels time:timestamps[i]];
        } else dispatch_semaphore_signal(slot);
    }
    glBindBuffer(GL_PIXEL_PACK_BUFFER,previousPackBuffer);
    CFTimeInterval now=CACurrentMediaTime();
    int64_t tick=(int64_t)((now-started)*60);
    if(tick==lastCaptureTick) return;
    int index=!pending[0] ? 0 : (!pending[1] ? 1 : -1);
    if(index<0) return; // Both GPU transfers are busy: drop a frame rather than wait.
    lastCaptureTick=tick;
    GLint viewport[4],readFB,drawFB,oldTexture,pack;
    glGetIntegerv(GL_VIEWPORT,viewport);
    glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING_EXT,&readFB); glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING_EXT,&drawFB);
    glGetIntegerv(GL_TEXTURE_BINDING_2D,&oldTexture); glGetIntegerv(GL_PACK_ALIGNMENT,&pack);
    if(!framebuffer) {
        glGenTextures(1,&texture); glBindTexture(GL_TEXTURE_2D,texture);
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,1024,768,0,GL_BGRA,GL_UNSIGNED_BYTE,NULL);
        glGenFramebuffersEXT(1,&framebuffer); glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT,framebuffer);
        glFramebufferTexture2DEXT(GL_DRAW_FRAMEBUFFER_EXT,GL_COLOR_ATTACHMENT0_EXT,GL_TEXTURE_2D,texture,0);
        glGenBuffers(2,transfers); glGenFencesAPPLE(2,fences);
        for(int i=0;i<2;i++) { glBindBuffer(GL_PIXEL_PACK_BUFFER,transfers[i]); glBufferData(GL_PIXEL_PACK_BUFFER,1024*768*4,NULL,GL_STREAM_READ); }
    }
    glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT,framebuffer);
    // Flip and shrink on the GPU; transfer into a buffer without reading CPU memory yet.
    glBlitFramebufferEXT(viewport[0],viewport[1],viewport[0]+viewport[2],viewport[1]+viewport[3],0,768,1024,0,GL_COLOR_BUFFER_BIT,GL_LINEAR);
    glBindFramebufferEXT(GL_READ_FRAMEBUFFER_EXT,framebuffer);
    glBindBuffer(GL_PIXEL_PACK_BUFFER,transfers[index]);
    glPixelStorei(GL_PACK_ALIGNMENT,1); glReadPixels(0,0,1024,768,GL_BGRA,GL_UNSIGNED_BYTE,NULL);
    glSetFenceAPPLE(fences[index]);
    timestamps[index]=CMTimeMakeWithSeconds(now-started,600); transferGeneration[index]=generation; pending[index]=YES;
    glPixelStorei(GL_PACK_ALIGNMENT,pack); glBindBuffer(GL_PIXEL_PACK_BUFFER,previousPackBuffer);
    glBindFramebufferEXT(GL_READ_FRAMEBUFFER_EXT,readFB); glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT,drawFB); glBindTexture(GL_TEXTURE_2D,oldTexture);
}
- (void)exportVideo {
    capturing=NO;
    dispatch_async(queue,^{
        if(!writer || writer.status!=AVAssetWriterStatusWriting || !sessionStarted) return;
        AVAssetWriter *completed=writer; writer=nil;
        NSURL *source=file; file=nil;
        [input markAsFinished]; [input release]; input=nil; [adaptor release]; adaptor=nil;
        [completed finishWritingWithCompletionHandler:^{ @autoreleasepool {
            NSURL *desktop=[[[NSFileManager defaultManager] URLsForDirectory:NSDesktopDirectory inDomains:NSUserDomainMask] firstObject];
            NSDateFormatter *format=[[[NSDateFormatter alloc] init] autorelease]; format.dateFormat=@"yyyy-MM-dd HH-mm-ss";
            NSURL *output=[desktop URLByAppendingPathComponent:[NSString stringWithFormat:@"Project Peon %@-%@.mp4",[format stringFromDate:NSDate.date],[NSUUID.UUID.UUIDString substringToIndex:6]]];
            NSError *error=completed.error;
            if(completed.status==AVAssetWriterStatusCompleted && [[NSFileManager defaultManager] copyItemAtURL:source toURL:output error:&error])
                dispatch_async(dispatch_get_main_queue(),^{ [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[output]]; });
            else if(error) dispatch_async(dispatch_get_main_queue(),^{ [NSApp presentError:error]; });
            [[NSFileManager defaultManager] removeItemAtURL:source error:NULL]; [source release]; [completed release];
        }}];
    });
}
@end
