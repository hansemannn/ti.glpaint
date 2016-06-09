/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2016 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiGlpaintPaintView.h"
#import "TiGlpaintPaintViewProxy.h"
#import "TiUtils.h"

@implementation TiGlpaintPaintViewProxy

#pragma mark Public APIs

- (void)erase:(id)unused
{
    ENSURE_ARG_COUNT(unused, 0);
    [(TiGlpaintPaintView*)[self view] erase];
}

- (void)setBrushColor:(id)value
{
    ENSURE_SINGLE_ARG(value, NSString);
    
    [[(TiGlpaintPaintView*)[self view] paintView] setBrushColor:[[TiUtils colorValue:value] _color]];
}

- (void)setBrushImage:(id)value
{
    ENSURE_SINGLE_ARG(value, NSString);
    
    [[(TiGlpaintPaintView*)[self view] paintView] setBrush:[TiUtils image:value proxy:self]];
}

- (void)setBrushScale:(id)value
{
    ENSURE_SINGLE_ARG(value, NSNumber);
    
    [[(TiGlpaintPaintView*)[self view] paintView] setBrushScale:[TiUtils floatValue:value def:2.0]];
}

- (void)setBrushPixelStep:(id)value
{
    ENSURE_SINGLE_ARG(value, NSNumber);
    
    [[(TiGlpaintPaintView*)[self view] paintView] setBrushPixelStep:[TiUtils floatValue:value def:1.0]];
}

- (void)setErasing:(id)value
{
    ENSURE_TYPE(value, NSNumber);
    [(TiGlpaintPaintView*)[self view] setErasing:[TiUtils boolValue:value]];
}

- (TiBlob*)takeGLSnapshot:(id)unused
{
    UIImage *image = [(TiGlpaintPaintView*)[self view] takeGLSnapshot];
    
    TiBlob *blob = [[[TiBlob alloc] _initWithPageContext:[self pageContext]] autorelease];
    [blob setImage:image];

    return blob;
}

#pragma mark Helper

USE_VIEW_FOR_CONTENT_WIDTH

USE_VIEW_FOR_CONTENT_HEIGHT

-(TiDimension)defaultAutoWidthBehavior:(id)unused
{
    return TiDimensionAutoFill;
}

-(TiDimension)defaultAutoHeightBehavior:(id)unused
{
    return TiDimensionAutoFill;
}

@end
