/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2016 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiUIView.h"
#import "RMPaint/RMPaint.h"

@interface TiGlpaintPaintView : TiUIView<RMCanvasViewDelegate> {
    TiDimension width;
    TiDimension height;
    CGFloat autoHeight;
    CGFloat autoWidth;
    
    BOOL initialized;
    
    RMCanvasView *paintView;
    RMPaintSession *paintSession;
}

- (RMCanvasView*)paintView;
- (RMPaintSession*)paintSession;

- (void)erase;
- (void)setErasing:(BOOL)erasing;
- (UIImage*)takeGLSnapshot;

// - (void)setBrushScale:(CGFloat)scale;
// - (void)setBrushPixelStep:(CGFloat)pixelStep;

@end
