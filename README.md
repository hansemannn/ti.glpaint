# Ti.GLPaint

> This module is still work in progress. The opacity currently cannot be changed and the image needs to be placed inside the module directly.

<img width="310" src="http://abload.de/img/simulatorscreenshot09b4jwb.png">

## Example

```js
var module = require("ti.glpaint");
var win = Ti.UI.createWindow({
    backgroundColor: "#fff"
});
var paintView = module.createPaintView({
    brush: {
        opacity: 10,
        tintColor: "red",
        image: "brush.png"
    },
    top: 100
});

var btn1 = Ti.UI.createButton({
    title: "Change to green color",
    top: 30
});

var btn2 = Ti.UI.createButton({
    title: "Erase",
    top: 50
});

btn1.addEventListener("click", function() {
    paintView.setBrush({
    opacity: 5,
        tintColor: "green",
        image: "brush2.png"
    });
});

btn2.addEventListener("click", function() {
    paintView.erase();
});

win.add(paintView);
win.add(btn1);
win.add(btn2);
win.open();
```

## Blend Modes
You can change the blend mode by setting the `blendMode` property like this: `paintView.setBlendMode(module.BLEND_MODE_GL_SRC_COLOR);`.
Available constants are:
```
BLEND_MODE_GL_ZERO
BLEND_MODE_GL_ONE
BLEND_MODE_GL_SRC_COLOR
BLEND_MODE_GL_ONE_MINUS_SRC_COLOR
BLEND_MODE_GL_DST_COLOR
BLEND_MODE_GL_ONE_MINUS_DST_COLOR
BLEND_MODE_GL_SRC_ALPHA
BLEND_MODE_GL_ONE_MINUS_SRC_ALPHA
BLEND_MODE_GL_DST_ALPHA
BLEND_MODE_GL_ONE_MINUS_DST_ALPHA
BLEND_MODE_GL_CONSTANT_COLOR
BLEND_MODE_GL_ONE_MINUS_CONSTANT_COLOR
BLEND_MODE_GL_CONSTANT_ALPHA
BLEND_MODE_GL_ONE_MINUS_CONSTANT_ALPHA
BLEND_MODE_GL_SRC_ALPHA_SATURATE
```

## Copyright

&copy; 2016 Appcelerator, Inc.