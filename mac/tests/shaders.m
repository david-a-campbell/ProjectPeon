// Compile every bundled shader against desktop OpenGL, without launching AppKit.
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(int argc, char **argv) {
    CGLPixelFormatAttribute attrs[] = { kCGLPFAAllowOfflineRenderers, (CGLPixelFormatAttribute)0 };
    CGLPixelFormatObj format; CGLContextObj context; GLint count;
    CGLError error = CGLChoosePixelFormat(attrs, &format, &count);
    if(error || !format) { fprintf(stderr,"No OpenGL pixel format: %s\n",CGLErrorString(error)); return 2; }
    error=CGLCreateContext(format,NULL,&context); CGLDestroyPixelFormat(format);
    if(error) { fprintf(stderr,"No OpenGL context: %s\n",CGLErrorString(error)); return 2; }
    CGLSetCurrentContext(context);
    printf("Renderer: %s\n",glGetString(GL_RENDERER));
    int failed=0;
    for(int i=1;i<argc;i++) {
        FILE *file=fopen(argv[i],"rb"); fseek(file,0,SEEK_END); long length=ftell(file); rewind(file);
        char *source=calloc(length+1,1); fread(source,1,length,file); fclose(file);
        GLenum type=strstr(argv[i],"_vert")?GL_VERTEX_SHADER:GL_FRAGMENT_SHADER;
        GLuint shader=glCreateShader(type); const GLchar *sources[]={source}; glShaderSource(shader,1,sources,NULL); glCompileShader(shader);
        GLint success; glGetShaderiv(shader,GL_COMPILE_STATUS,&success);
        if(!success) { char log[8192]; glGetShaderInfoLog(shader,sizeof(log),NULL,log); fprintf(stderr,"FAIL %s: %s\n",argv[i],log); failed++; }
        else printf("PASS %s\n",argv[i]);
        glDeleteShader(shader); free(source);
    }
    CGLSetCurrentContext(NULL); CGLDestroyContext(context); return failed?1:0;
}
