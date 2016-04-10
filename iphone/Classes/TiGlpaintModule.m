/**
 * ti.glpaint
 *
 * Created by Your Name
 * Copyright (c) 2016 Your Company. All rights reserved.
 */

#import "TiGlpaintModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiApp.h"
#import "TiUtils.h"
#import <GLKit/GLKit.h>

@implementation TiGlpaintModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"dc5c5d76-c71b-4f70-bcf0-f47b82116cb4";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"ti.glpaint";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];

	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably

	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup

-(void)dealloc
{
	// release any resources that have been retained by the module
	[super dealloc];
}

MAKE_SYSTEM_PROP(BLEND_MODE_GL_ZERO, GL_ZERO);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_ONE, GL_ONE);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_SRC_COLOR, GL_SRC_COLOR);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_ONE_MINUS_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_DST_COLOR, GL_DST_COLOR);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_DST_COLOR);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_SRC_ALPHA, GL_SRC_ALPHA);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_ONE_MINUS_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_DST_ALPHA, GL_DST_ALPHA);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_ONE_MINUS_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_CONSTANT_COLOR, GL_CONSTANT_COLOR);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_ONE_MINUS_CONSTANT_COLOR, GL_ONE_MINUS_CONSTANT_COLOR);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_CONSTANT_ALPHA, GL_CONSTANT_ALPHA);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_ONE_MINUS_CONSTANT_ALPHA, GL_ONE_MINUS_CONSTANT_ALPHA);
MAKE_SYSTEM_PROP(BLEND_MODE_GL_SRC_ALPHA_SATURATE, GL_SRC_ALPHA_SATURATE);

@end
