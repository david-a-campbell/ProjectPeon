#include <assert.h>
#include <math.h>
#include <stdio.h>
#define MIN(a,b) ((a)<(b)?(a):(b))
#include "PeonViewport.h"
static CGFloat amount;
CGFloat PeonWideScreenAmount(void) { return amount; }
int main(void) {
    const CGSize screens[]={{2853,2007},{2034,1398},{2622,1206},{1024,768},{1920,1080},{867,669}};
    const CGSize game={1024,768};
    for (unsigned i=0;i<sizeof(screens)/sizeof(*screens);i++) {
        CGSize screen=screens[i];
        amount=1; // Every device uses the same 16:9 game presentation.
        CGRect bounds=CGRectMake(17,29,screen.width,screen.height);
        CGRect viewport=PeonGameViewport(bounds,game);
        assert(fabs(viewport.size.width/viewport.size.height-16.0/9)<1e-6);
        assert(CGRectContainsRect(bounds,viewport));
        assert(fabs(CGRectGetMidX(viewport)-CGRectGetMidX(bounds))<1e-6);
        assert(fabs(CGRectGetMidY(viewport)-CGRectGetMidY(bounds))<1e-6);
        assert(fabs(viewport.size.width-screen.width)<1e-6 || fabs(viewport.size.height-screen.height)<1e-6);
        if (i < 2) { // Both Duo screens must meet the left and right edges.
            assert(fabs(CGRectGetMinX(viewport)-CGRectGetMinX(bounds))<1e-6);
            assert(fabs(CGRectGetMaxX(viewport)-CGRectGetMaxX(bounds))<1e-6);
        }
        const CGPoint targets[]={{512,384},{-1024.0/6,0},{1024+1024.0/6,768},{100,650}};
        for(unsigned j=0;j<sizeof(targets)/sizeof(*targets);j++) {
            CGPoint mapped=PeonViewPoint(targets[j],viewport,game);
            CGPoint back=PeonGamePoint(mapped,viewport,game);
            assert(hypot(back.x-targets[j].x,back.y-targets[j].y)<1e-6);
        }
        assert(fabs(PeonCartToolX(0)+1024.0/6)<1e-6);
        assert(fabs(PeonCartToolX(1024)-1024-1024.0/6)<1e-6);
        printf("%.0fx%.0f: 16:9 fit, no cropping, centered canvas, touch round trip PASS\n",screen.width,screen.height);
    }
}
