/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2016 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiGlpaintPaintView.h"

@implementation TiGlpaintPaintView

#pragma mark View Lifecycle

- (void)dealloc
{
    RELEASE_TO_NIL(paintView);
    RELEASE_TO_NIL(paintSession);
    
    [super dealloc];
}

#pragma mark Layout helper

#ifdef TI_USE_AUTOLAYOUT
-(void)initializeTiLayoutView
{
    [super initializeTiLayoutView];
    [self setDefaultHeight:TiDimensionAutoFill];
    [self setDefaultWidth:TiDimensionAutoFill];
}
#endif

-(void)setWidth_:(id)width_
{
    width = TiDimensionFromObject(width_);
    [self updateContentMode];
}

-(void)setHeight_:(id)height_
{
    height = TiDimensionFromObject(height_);
    [self updateContentMode];
}

-(void)updateContentMode
{
    if (self != nil) {
        [self setContentMode:[self contentModeForPaintingView]];
    }
}

-(UIViewContentMode)contentModeForPaintingView
{
    if (TiDimensionIsAuto(width) || TiDimensionIsAutoSize(width) || TiDimensionIsUndefined(width) ||
        TiDimensionIsAuto(height) || TiDimensionIsAutoSize(height) || TiDimensionIsUndefined(height)) {
        return UIViewContentModeScaleAspectFit;
    } else {
        return UIViewContentModeScaleToFill;
    }
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    
    if (!initialized) {
        [[self paintView] initialize:frame];
        initialized = YES;
    }
    
    for (UIView *child in [self subviews]) {
        [TiUtils setView:child positionRect:bounds];
    }
    
    [super frameSizeChanged:frame bounds:bounds];
}


-(CGFloat)contentWidthForWidth:(CGFloat)suggestedWidth
{
    if (autoWidth > 0)
    {
        //If height is DIP returned a scaled autowidth to maintain aspect ratio
        if (TiDimensionIsDip(height) && autoHeight > 0) {
            return roundf(autoWidth*height.value/autoHeight);
        }
        return autoWidth;
    }
    
    CGFloat calculatedWidth = TiDimensionCalculateValue(width, autoWidth);
    if (calculatedWidth > 0)
    {
        return calculatedWidth;
    }
    
    return 0;
}

-(CGFloat)contentHeightForWidth:(CGFloat)width_
{
    if (width_ != autoWidth && autoWidth>0 && autoHeight > 0) {
        return (width_*autoHeight/autoWidth);
    }
    
    if (autoHeight > 0) {
        return autoHeight;
    }
    
    CGFloat calculatedHeight = TiDimensionCalculateValue(height, autoHeight);
    if (calculatedHeight > 0) {
        return calculatedHeight;
    }
    
    return 0;
}

-(UIViewContentMode)contentMode
{
    if (TiDimensionIsAuto(width) || TiDimensionIsAutoSize(width) || TiDimensionIsUndefined(width) ||
        TiDimensionIsAuto(height) || TiDimensionIsAutoSize(height) || TiDimensionIsUndefined(height)) {
        return UIViewContentModeScaleAspectFit;
    } else {
        return UIViewContentModeScaleToFill;
    }
}

#pragma mark Public APIs

- (RMCanvasView *)paintView
{
    if (paintView == nil) {
        paintView = [[RMGestureCanvasView alloc] initWithFrame:self.frame];
        [self addSubview:paintView];
        [[self paintSession] paintInCanvas:paintView];
        
        [paintView setDelegate:self];
    }
    
    return paintView;
}

- (RMPaintSession *)paintSession
{
    if (paintSession == nil) {
        paintSession = [[RMPaintSession alloc] initWithDefaultsWithKey:@"HISTORY"];
    }
    
    return paintSession;
}

- (void)setErasing:(BOOL)erasing
{
    if (erasing) {
        glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA);
    } else {
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    }
}

- (void)erase
{
    [[self paintView] erase];
}

- (UIImage *)takeGLSnapshot
{
    // The image size should be grabbed from your ESRenderer class.
    // That parameter is get in renderer function:
    // - (BOOL) resizeFromLayer:(CAEAGLLayer *)layer {
    // glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    GLubyte *buffer = (GLubyte *) malloc([[self paintView] backingWidth] * [[self paintView] backingHeight] * 4);
    GLubyte *buffer2 = (GLubyte *) malloc([[self paintView] backingWidth] * [[self paintView] backingHeight] * 4);
    
    glReadPixels(0, 0, [[self paintView] backingWidth], [[self paintView] backingHeight], GL_RGBA, GL_UNSIGNED_BYTE,
                 (GLvoid *)buffer);
    for (int y = 0; y < [[self paintView] backingHeight]; y++) {
        for (int x = 0; x < [[self paintView] backingWidth] * 4; x++) {
            buffer2[y * 4 * [[self paintView] backingWidth] + x] = buffer[([[self paintView] backingHeight] - y - 1) * [[self paintView] backingWidth] * 4 + x];
        }
    }
    free(buffer);
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer2,
                                                              [[self paintView] backingWidth] * [[self paintView] backingHeight] * 4,
                                                              myProviderReleaseData);
    // set up for CGImage creation
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * [[self paintView] backingWidth];
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    // Use this to retain alpha
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate([[self paintView] backingWidth], [[self paintView] backingHeight],
                                        bitsPerComponent, bitsPerPixel,
                                        bytesPerRow, colorSpaceRef,
                                        bitmapInfo, provider,
                                        NULL, NO,
                                        renderingIntent);
    // this contains our final image.
    UIImage *newUIImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    
    return newUIImage;
}

static void myProviderReleaseData (void *info,const void *data,size_t size)
{
    free((void*)data);
}

#pragma mark Delegates

- (void)canvasView:(RMCanvasView *)canvasView painted:(RMPaintStep *)step
{
    if ([[self proxy] _hasListeners:@"paintstep"]) {
        [[self proxy] fireEvent:@"paintstep" withObject:@{
            @"startX": NUMFLOAT(floorf(step.start.x)),
            @"startY": NUMFLOAT(floorf(step.start.y)),
            @"endX": NUMFLOAT(floorf(step.end.x)),
            @"endY": NUMFLOAT(floorf(step.end.y))
        }];
    }
}

@end
