/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2016 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiViewProxy.h"

@interface TiGlpaintPaintViewProxy : TiViewProxy {

}

- (void)erase:(id)unused;
- (void)setBrush:(id)args;
- (void)setErasing:(id)value;
- (void)addImage:(id)args; // [JVP]
@end
