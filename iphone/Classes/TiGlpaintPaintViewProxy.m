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

- (void)setBrush:(id)args
{
    ENSURE_TYPE(args, NSDictionary);
    
    id tintColor = [args valueForKey:@"tintColor"];
    id opacity = [args valueForKey:@"opacity"];
    id image = [args valueForKey:@"image"];
    id scale = [args valueForKey:@"scale"];
  //  id pixelStep = [args valueForKey:@"pixelStep"];
    
    ENSURE_TYPE(tintColor, NSString);
    ENSURE_TYPE(opacity, NSNumber);
    ENSURE_TYPE(image, NSString);
    ENSURE_TYPE(scale, NSNumber);
  //  ENSURE_TYPE(pixelStep, NSNumber);
    
    const CGFloat *components = CGColorGetComponents([[[TiUtils colorValue:tintColor] _color] CGColor]);
    [(TiGlpaintPaintView*)[self view] setBrushColorWithRed:components[0] green:components[1] blue:components[2] opacity:[TiUtils floatValue:opacity def:1.0]];
    
    [(TiGlpaintPaintView*)[self view] setBrushImage:[TiUtils stringValue:image]];
    [(TiGlpaintPaintView*)[self view] setBrushScale:[TiUtils floatValue:scale]];
  //  [(TiGlpaintPaintView*)[self view] setBrushPixelStep:[TiUtils floatValue:pixelStep]];
}

- (void)setErasing:(id)value
{
    ENSURE_TYPE(value, NSNumber);
    [(TiGlpaintPaintView*)[self view] setErasing:[TiUtils boolValue:value]];
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
