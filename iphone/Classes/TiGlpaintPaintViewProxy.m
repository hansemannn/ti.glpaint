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

- (TiGlpaintPaintView*)paintView
{
    return (TiGlpaintPaintView*)self.view;
}

#pragma mark Public APIs

- (void)initialize:(id)unused
{
    [[[self paintView] paintingView] layoutSubviews];
}

- (void)erase:(id)unused
{
    [[[self paintView] paintingView] erase];
}

- (void)setBrushColor:(id)value
{
    CGColorRef color = [[[TiUtils colorValue:value] _color] CGColor];
    const CGFloat *components = CGColorGetComponents(color);
    
    [[[self paintView] paintingView] setBrushColorWithRed:components[0] green:components[1] blue:components[2]];
}

#pragma mark Helper

USE_VIEW_FOR_CONTENT_WIDTH

USE_VIEW_FOR_CONTENT_HEIGHT

-(TiDimension)defaultAutoWidthBehavior:(id)unused
{
    return TiDimensionAutoSize;
}

-(TiDimension)defaultAutoHeightBehavior:(id)unused
{
    return TiDimensionAutoSize;
}

@end
