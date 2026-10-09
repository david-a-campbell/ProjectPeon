// Regression: the original polygon used 64-bit CGPoint memory as GL_FLOAT data.
#import "PRFilledPolygon.h"
#import "kazmath/GL/matrix.h"
#import "kazmath/mat4.h"
#include <stdio.h>
BOOL PeonKeyDown(unsigned short code) { return NO; }
int main(void) {
    @autoreleasepool {
        CGLPixelFormatAttribute attributes[]={kCGLPFAAllowOfflineRenderers,0};
        CGLPixelFormatObj format; CGLContextObj context; GLint count;
        if(CGLChoosePixelFormat(attributes,&format,&count)!=kCGLNoError || !format) return 2;
        if(CGLCreateContext(format,NULL,&context)!=kCGLNoError) return 2;
        CGLDestroyPixelFormat(format); CGLSetCurrentContext(context);
        GLuint framebuffer,output;
        glGenFramebuffers(1,&framebuffer); glBindFramebuffer(GL_FRAMEBUFFER,framebuffer);
        glGenTextures(1,&output); glBindTexture(GL_TEXTURE_2D,output);
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,128,128,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
        glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,output,0);
        if(glCheckFramebufferStatus(GL_FRAMEBUFFER)!=GL_FRAMEBUFFER_COMPLETE) return 2;
        glViewport(0,0,128,128); glClearColor(0,0,0,1); glClear(GL_COLOR_BUFFER_BIT);
        kmMat4 projection; kmMat4OrthographicProjection(&projection,0,128,0,128,-1,1);
        kmGLMatrixMode(KM_GL_PROJECTION); kmGLLoadMatrix(&projection);
        kmGLMatrixMode(KM_GL_MODELVIEW); kmGLLoadIdentity();
        unsigned char red[16]={255,0,0,255,255,0,0,255,255,0,0,255,255,0,0,255};
        CCTexture2D *texture=[[[CCTexture2D alloc] initWithData:red pixelFormat:kCCTexture2DPixelFormat_RGBA8888 pixelsWide:2 pixelsHigh:2 contentSize:CGSizeMake(2,2)] autorelease];
        NSArray *points=@[[NSValue valueWithCGPoint:CGPointMake(16,16)],[NSValue valueWithCGPoint:CGPointMake(112,16)],[NSValue valueWithCGPoint:CGPointMake(16,112)]];
        PRFilledPolygon *polygon=[PRFilledPolygon filledPolygonWithPoints:points andTexture:texture];
        [polygon draw]; glFinish();
        unsigned char inside[4],outside[4];
        glReadPixels(32,32,1,1,GL_RGBA,GL_UNSIGNED_BYTE,inside);
        glReadPixels(120,120,1,1,GL_RGBA,GL_UNSIGNED_BYTE,outside);
        BOOL passed=inside[0]>240 && inside[1]<10 && outside[0]<10;
        printf("Terrain triangle: %s (inside %u,%u,%u; outside %u,%u,%u)\n",passed?"PASS":"FAIL",inside[0],inside[1],inside[2],outside[0],outside[1],outside[2]);
        return passed?0:1;
    }
}
