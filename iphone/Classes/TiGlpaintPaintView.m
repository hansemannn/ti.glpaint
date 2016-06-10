/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2016 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiGlpaintPaintView.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <GLKit/GLKit.h>

#import "shaderUtil.h"
#import "fileUtil.h"
#import "debug.h"

@implementation TiGlpaintPaintView

programInfo_t program[NUM_PROGRAMS] = {
    { "point.vertsh",   "point.fragsh" }     // PROGRAM_POINT
};

#ifdef TI_USE_AUTOLAYOUT
-(void)initializeTiLayoutView
{
    [super initializeTiLayoutView];
    [self setDefaultHeight:TiDimensionAutoSize];
    [self setDefaultWidth:TiDimensionAutoSize];
}
#endif

#pragma mark Public APIs

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

#pragma mark Layout helper

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
    }
    else {
        return UIViewContentModeScaleToFill;
    }
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    for (UIView *child in [self subviews])
    {
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


@synthesize  location;
@synthesize  previousLocation;

// Implement this to override the default layer class (which is [CALayer class]).
// We do this so that our view will be backed by a layer that is capable of OpenGL ES rendering.
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

// The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithFrame:(CGRect)frame {
    
    if ((self = [super initWithFrame:frame])) {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = YES;
        // In this application, we want to retain the EAGLDrawable contents after a call to presentRenderbuffer.
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!context || ![EAGLContext setCurrentContext:context]) {
            return nil;
        }
        
        // Set the view's scale factor as you wish
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
        
        // Make sure to start with a cleared buffer
        needsErase = YES;
        brushPixelStep = 3;
        brushScale = 1;
        brushImage = @"brush.png";
    }
    
    return self;
}

// If our view is resized, we'll be asked to layout subviews.
// This is the perfect opportunity to also update the framebuffer so that it is
// the same size as our display area.
-(void)layoutSubviews
{
    [EAGLContext setCurrentContext:context];
    
    if (!initialized) {
        initialized = [self initGL];
    }
    else {
        [self resizeFromLayer:(CAEAGLLayer*)self.layer];
    }
    
    // Clear the framebuffer the first time it is allocated
    if (needsErase) {
        [self erase];
        needsErase = NO;
    }
}

- (void)setupShaders
{
    for (int i = 0; i < NUM_PROGRAMS; i++)
    {
        char *vsrc = readFile(pathForResource(program[i].vert));
        char *fsrc = readFile(pathForResource(program[i].frag));
        GLsizei attribCt = 0;
        GLchar *attribUsed[NUM_ATTRIBS];
        GLint attrib[NUM_ATTRIBS];
        GLchar *attribName[NUM_ATTRIBS] = {
            "inVertex",
        };
        const GLchar *uniformName[NUM_UNIFORMS] = {
            "MVP", "pointSize", "vertexColor", "texture",
        };
        
        // auto-assign known attribs
        for (int j = 0; j < NUM_ATTRIBS; j++)
        {
            if (strstr(vsrc, attribName[j]))
            {
                attrib[attribCt] = j;
                attribUsed[attribCt++] = attribName[j];
            }
        }
        
        glueCreateProgram(vsrc, fsrc,
                          attribCt, (const GLchar **)&attribUsed[0], attrib,
                          NUM_UNIFORMS, &uniformName[0], program[i].uniform,
                          &program[i].id);
        free(vsrc);
        free(fsrc);
        
        // Set constant/initalize uniforms
        if (i == PROGRAM_POINT)
        {
            glUseProgram(program[PROGRAM_POINT].id);
            
            // the brush texture will be bound to texture unit 0
            glUniform1i(program[PROGRAM_POINT].uniform[UNIFORM_TEXTURE], 0);
            
            // viewing matrices
            GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
            GLKMatrix4 modelViewMatrix = GLKMatrix4Identity; // this sample uses a constant identity modelView matrix
            GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
            
            glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
            
            // point size
            glUniform1f(program[PROGRAM_POINT].uniform[UNIFORM_POINT_SIZE], brushTexture.width * brushScale);
            
            // initialize brush color
            glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
        }
    }
    
    glError();
}

// Create a texture from an image
- (textureInfo_t)textureFromName:(NSString *)name
{
    CGImageRef		brushImage_;
    CGContextRef	brushContext;
    GLubyte			*brushData;
    size_t			width_, height_;
    GLuint          texId;
    textureInfo_t   texture;
    
    // First create a UIImage object from the data in a image file, and then extract the Core Graphics image
    brushImage_ = [TiUtils image:name proxy:self.proxy].CGImage;
    
    // Get the width and height of the image
    width_ = CGImageGetWidth(brushImage_);
    height_ = CGImageGetHeight(brushImage_);
    
    // Make sure the image exists
    if(brushImage_) {
        // Allocate  memory needed for the bitmap context
        brushData = (GLubyte *) calloc(width_ * height_ * 4, sizeof(GLubyte));
        // Use  the bitmatp creation function provided by the Core Graphics framework.
        brushContext = CGBitmapContextCreate(brushData, width_, height_, 8, width_ * 4, CGImageGetColorSpace(brushImage_), kCGImageAlphaPremultipliedFirst);
        // After you create the context, you can draw the  image to the context.
        CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width_, (CGFloat)height_), brushImage_);
        // You don't need the context at this point, so you need to release it to avoid memory leaks.
        CGContextRelease(brushContext);
        // Use OpenGL ES to generate a name for the texture.
        glGenTextures(1, &texId);
        // Bind the texture name.
        glBindTexture(GL_TEXTURE_2D, texId);
        // Set the texture parameters to use a minifying filter and a linear filer (weighted average)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        // Specify a 2D texture image, providing the a pointer to the image data in memory
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width_, (int)height_, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
        // Release  the image data; it's no longer needed
        free(brushData);
        
        texture.id = texId;
        texture.width = (int)width_;
        texture.height = (int)height_;
    }
    
    glDisable(GL_DITHER);
    glEnable(GL_TEXTURE_2D);
//  glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    return texture;
}

- (BOOL)initGL
{
    // Generate IDs for a framebuffer object and a color renderbuffer
    glGenFramebuffers(1, &viewFramebuffer);
    glGenRenderbuffers(1, &viewRenderbuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    // This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
    // allowing us to draw into a buffer that will later be rendered to screen wherever the layer is (which corresponds with our view).
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    
    // Setup the view port in Pixels
    glViewport(0, 0, backingWidth, backingHeight);
    
    // Create a Vertex Buffer Object to hold our data
    glGenBuffers(1, &vboId);
    
    // Load the brush texture
    brushTexture = [self textureFromName:brushImage];
    
    // Load shaders
    [self setupShaders];
    
    // Enable blending and set a blending function appropriate for premultiplied alpha pixel data
    glEnable(GL_BLEND);
    //    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    // Playback recorded path, which is "Shake Me"
    NSMutableArray* recordedPaths = [NSMutableArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Recording" ofType:@"data"]];
    if([recordedPaths count])
        [self performSelector:@selector(playback:) withObject:recordedPaths afterDelay:0.2];
    
    return YES;
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
    // Allocate color buffer backing based on the current layer size
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"Failed to make complete framebuffer objectz %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    
    // Update projection matrix
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity; // this sample uses a constant identity modelView matrix
    GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    glUseProgram(program[PROGRAM_POINT].id);
    glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
    
    // Update viewport
    glViewport(0, 0, backingWidth, backingHeight);
    
    return YES;
}

// Releases resources when they are not longer needed.
- (void)dealloc
{
    // Destroy framebuffers and renderbuffers
    if (viewFramebuffer) {
        glDeleteFramebuffers(1, &viewFramebuffer);
        viewFramebuffer = 0;
    }
    if (viewRenderbuffer) {
        glDeleteRenderbuffers(1, &viewRenderbuffer);
        viewRenderbuffer = 0;
    }
    if (depthRenderbuffer)
    {
        glDeleteRenderbuffers(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
    // texture
    if (brushTexture.id) {
        glDeleteTextures(1, &brushTexture.id);
        brushTexture.id = 0;
    }
    // [JVP] if addImge solution uses imageTexture, we should prolly dealloc here
    if (imageTexture.id) {
        glDeleteTextures(1, &imageTexture.id);
        imageTexture.id = 0;
    }
    // vbo
    if (vboId) {
        glDeleteBuffers(1, &vboId);
        vboId = 0;
    }
    
    // tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    
    [super dealloc];
}

// Erases the screen
- (void)erase
{
    [EAGLContext setCurrentContext:context];
    
    // Clear the buffer
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Display the buffer
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

// Drawings a line onscreen based on where the user touches
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
    static GLfloat*		vertexBuffer = NULL;
    static NSUInteger	vertexMax = 64;
    NSUInteger			vertexCount = 0,
    count,
    i;
    
    [EAGLContext setCurrentContext:context];
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    
    // Convert locations from Points to Pixels
    CGFloat scale = self.contentScaleFactor;
    start.x *= scale;
    start.y *= scale;
    end.x *= scale;
    end.y *= scale;
    
    // Allocate vertex array buffer
    if(vertexBuffer == NULL)
        vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
    
    // Add points to the buffer so there are drawing points every X pixels
    count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / brushPixelStep), 1);
    for(i = 0; i < count; ++i) {
        if(vertexCount == vertexMax) {
            vertexMax = 2 * vertexMax;
            vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
        }
        
        vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
        vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
        vertexCount += 1;
    }
    
    // Load data to the Vertex Buffer Object
    glBindBuffer(GL_ARRAY_BUFFER, vboId);
    glBufferData(GL_ARRAY_BUFFER, vertexCount*2*sizeof(GLfloat), vertexBuffer, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    // Draw
    glUseProgram(program[PROGRAM_POINT].id);
    glDrawArrays(GL_POINTS, 0, (int)vertexCount);
    
    // Display the buffer
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

// Reads previously recorded points and draws them onscreen. This is the Shake Me message that appears when the application launches.
- (void)playback:(NSMutableArray*)recordedPaths
{
    // NOTE: Recording.data is stored with 32-bit floats
    // To make it work on both 32-bit and 64-bit devices, we make sure we read back 32 bits each time.
    
    Float32 x[1], y[1];
    CGPoint point1, point2;
    
    NSData*				data = [recordedPaths objectAtIndex:0];
    NSUInteger			count = [data length] / (sizeof(Float32)*2), // each point contains 64 bits (32-bit x and 32-bit y)
    i;
    
    // Render the current path
    for(i = 0; i < count - 1; i++) {
        [data getBytes:&x range:NSMakeRange(8*i, sizeof(Float32))]; // read 32 bits each time
        [data getBytes:&y range:NSMakeRange(8*i+sizeof(Float32), sizeof(Float32))];
        point1 = CGPointMake(x[0], y[0]);
        
        [data getBytes:&x range:NSMakeRange(8*(i+1), sizeof(Float32))];
        [data getBytes:&y range:NSMakeRange(8*(i+1)+sizeof(Float32), sizeof(Float32))];
        point2 = CGPointMake(x[0], y[0]);
        
        [self renderLineFromPoint:point1 toPoint:point2];
    }
    
    // Render the next path after a short delay
    [recordedPaths removeObjectAtIndex:0];
    if([recordedPaths count])
        [self performSelector:@selector(playback:) withObject:recordedPaths afterDelay:0.01];
}


// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGRect				bounds = [self bounds];
    UITouch*            touch = [[event touchesForView:self] anyObject];
    firstTouch = YES;
    // Convert touch point from UIView referential to OpenGL one (upside-down flip)
    location = [touch locationInView:self];
    location.y = bounds.size.height - location.y;
    [self.proxy fireEvent:@"touchesBegan"];
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSMutableDictionary *jsEvent = [NSMutableDictionary dictionary];
    CGRect				bounds = [self bounds];
    UITouch*			touch = [[event touchesForView:self] anyObject];
    
    // Convert touch point from UIView referential to OpenGL one (upside-down flip)
    if (firstTouch) {
        firstTouch = NO;
        previousLocation = [touch previousLocationInView:self];
        previousLocation.y = bounds.size.height - previousLocation.y;
    } else {
        location = [touch locationInView:self];
        location.y = bounds.size.height - location.y;
        previousLocation = [touch previousLocationInView:self];
        previousLocation.y = bounds.size.height - previousLocation.y;
    }
    
    // Render the stroke
    [self renderLineFromPoint:previousLocation toPoint:location];
    [self.proxy fireEvent:@"touchesMoved"];
    
}

// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSMutableDictionary *jsEvent = [NSMutableDictionary dictionary];
    CGRect				bounds = [self bounds];
    UITouch*            touch = [[event touchesForView:self] anyObject];
    if (firstTouch) {
        firstTouch = NO;
        previousLocation = [touch previousLocationInView:self];
        previousLocation.y = bounds.size.height - previousLocation.y;
        [self renderLineFromPoint:previousLocation toPoint:location];
        [self.proxy fireEvent:@"touchesEnded"];
    }
}

// Handles the end of a touch event.
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // If appropriate, add code necessary to save the state of the application.
    // This application is not saving state.
}

- (void)setBrushColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue opacity:(CGFloat)opacity
{
    // Update the brush color
    brushColor[0] = red * opacity;
    brushColor[1] = green * opacity;
    brushColor[2] = blue * opacity;
    brushColor[3] = opacity;
    
    if (initialized) {
        glUseProgram(program[PROGRAM_POINT].id);
        glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
    }
}

- (void)setBrushImage:(NSString*)image
{
    RELEASE_TO_NIL(brushImage);
    brushImage = [image retain];
    brushTexture = [self textureFromName:brushImage];
    
    if (initialized) {
        glUseProgram(program[PROGRAM_POINT].id);
        glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
    }
}

- (void)setBrushScale:(CGFloat)scale
{
    brushScale = scale;
    
    if (initialized) {
        glUseProgram(program[PROGRAM_POINT].id);
        glUniform1f(program[PROGRAM_POINT].uniform[UNIFORM_POINT_SIZE], brushTexture.width * brushScale);
    }
}

- (void)setErasing:(BOOL)erasing
{
    if (erasing) {
        glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA);
    } else {
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    }
}

// TODO: Not working, yet
- (void)setBrushPixelStep:(CGFloat)pixelStep
{
    brushPixelStep = pixelStep;
    
    if (initialized) {
        glUseProgram(program[PROGRAM_POINT].id);
        glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
    }
}

// [JVP] borrowed texImage2D from opengl module and modified to use args as dictionary directly
-(void)texImage2D:(id)args
{
    
    ENSURE_ARG_COUNT(args, 7)

    GLint level = (GLint)[TiUtils intValue:[args valueForKey:@"level"] def:0];
    GLint internalFormat = (GLint)[TiUtils intValue:[args valueForKey:@"internalFormat"] def:0];
    GLsizei inputImageWidth = (GLsizei)[TiUtils intValue:[args valueForKey:@"width"] def:0];
    GLsizei inputImageHeight = (GLsizei)[TiUtils intValue:[args valueForKey:@"height"] def:0];
    GLint borderWidth = (GLint)[TiUtils intValue:[args valueForKey:@"border"] def:0];
    GLenum imageType = (GLenum)[TiUtils intValue:[args valueForKey:@"type"] def:0];
    
    // Load the image from the file path
    NSString *imagePath = [args valueForKey:@"file"];
    NSData *texData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:imagePath]];

    UIImage *image = [[UIImage alloc] initWithData:texData];
    
    if (image == nil) {
        NSLog(@"File error in texImage2D: %s", [imagePath UTF8String]);
    }

    NSLog(@"1 in texImage2D %d %x %d %d %d %d %s", level, internalFormat, inputImageWidth, inputImageHeight, borderWidth, imageType, [imagePath UTF8String]);
    
    // Set the image context definition using width and height
    GLuint imageWidth = (inputImageWidth == 0) ? CGImageGetWidth(image.CGImage) : inputImageWidth;
    GLuint imageHeight = (inputImageHeight == 0) ? CGImageGetHeight(image.CGImage) : inputImageHeight;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    GLubyte* imageData = malloc( imageHeight * imageWidth * 4 );
    CGContextRef imageContext = CGBitmapContextCreate( imageData, imageWidth, imageHeight, 8, 4 * imageWidth, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );

    // Flip the Y-axis
    CGContextTranslateCTM (imageContext, 0, imageHeight);
    CGContextScaleCTM (imageContext, 1.0, -1.0);
    
    // Draw the image in the context
    CGColorSpaceRelease( colorSpace );
    CGContextClearRect( imageContext, CGRectMake( 0, 0, imageWidth, imageHeight ) );
    CGContextDrawImage( imageContext, CGRectMake( 0, 0, imageWidth, imageHeight ), image.CGImage );

    glTexImage2D(GL_TEXTURE_2D, level, internalFormat, imageWidth, imageHeight, borderWidth, internalFormat, imageType, imageData);

    NSLog(@"in texImage2D %d %x %d %d %d %d %s %x", level, internalFormat, imageWidth, imageHeight, borderWidth, imageType, [imagePath UTF8String], glGetError());
    CGContextRelease(imageContext);
    free(imageData);
    [image release];
    [texData release];

}

-(void)addImage:(id)args
{
    // [JVP] imageTexture is declared in header file
    glGenTextures(1, &imageTexture.id);
    glBindTexture(GL_TEXTURE_2D, imageTexture.id);
    
    // [JVP] For now trying to use texImage2D method borrowed from opengl module, however
    // perhaps should consider instead modifying the textureFromName method already in
    // this module to handle both the "brush" image and the image to be loaded here
    
    NSMutableDictionary *texImage2Dargs = [NSMutableDictionary dictionary];
    [texImage2Dargs setObject:@0 forKey:@"level"];
    [texImage2Dargs setObject:@GL_RGBA forKey:@"internalFormat"];
    [texImage2Dargs setObject:[args valueForKey:@"width"] forKey:@"width"];
    [texImage2Dargs setObject:[args valueForKey:@"height"] forKey:@"height"];
    [texImage2Dargs setObject:@0 forKey:@"border"];
    [texImage2Dargs setObject:@GL_UNSIGNED_BYTE forKey:@"type"];
    [texImage2Dargs setObject:[args valueForKey:@"image"] forKey:@"file"];
    [self texImage2D:texImage2Dargs];
    
    // [JVP] Not sure what needs to be done here exactly...
    // trying differnet things from online exmaples - this prolly needs to be reconsidered
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, imageTexture.id, 0);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glActiveTexture(GL_TEXTURE1); // is this required? using GL_TEXTURE1 to try to differentiate from GL_TEXTURE0 that the brush should be using - no luck yet
    
    glBindTexture(GL_TEXTURE_2D, imageTexture.id);
    
}




- (BOOL)canBecomeFirstResponder {
    return YES;
}

@end
