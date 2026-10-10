#pragma once
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include <vector>

// TMX polygon coordinates use a downward Y axis. Keep the bottom closure and
// distant terrain intact, replacing only the floor across the starting block.
static NSString *PeonStartingGroundOutline(NSString *outline, CGPoint origin,
                                          CGFloat right, CGFloat surface) {
    std::vector<CGPoint> points;
    for (NSString *pair in [outline componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]) {
        NSArray *xy = [pair componentsSeparatedByString:@","];
        if (xy.count == 2) points.push_back(CGPointMake([xy[0] doubleValue], [xy[1] doubleValue]));
    }
    if (points.size() < 4) return outline;
    // Only the ground rising from the map's bottom-left is a starting floor;
    // ceilings, islands and later terrain pieces must retain their geometry.
    if (fabs(origin.y) > 0.01 || fabs(origin.x + points[0].x) > 8 ||
        fabs(points[0].y) > 0.01 || fabs(points[1].x-points[0].x) > 8 ||
        fabs(origin.y-points[1].y-surface) > 8) return outline;
    CGFloat localRight = right-origin.x;
    // Follow only the first surface leaving the starting area. Later cave
    // floors can loop back under the same X coordinates and must stay intact.
    size_t join = 2;
    while (join + 1 < points.size() && points[join].x < localRight+256) ++join;
    if (join + 1 >= points.size()) return outline;
    CGPoint before = points[join-1], after = points[join];
    CGFloat joinX = fmax(localRight+256, before.x);
    CGFloat joinY = before.y + (after.y-before.y)*(joinX-before.x)/(after.x-before.x);
    NSMutableString *result = [NSMutableString stringWithFormat:@"%.6f,%.6f %.6f,%.6f %.6f,%.6f %.6f,%.6f",
        points[0].x, points[0].y, points[1].x, origin.y-surface,
        localRight, origin.y-surface, joinX, joinY];
    for (size_t i = join; i < points.size(); ++i)
        if (i != join || fabs(points[i].x-joinX) > 0.0001)
            [result appendFormat:@" %.6f,%.6f",points[i].x,points[i].y];
    return result;
}
