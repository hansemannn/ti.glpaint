# Ti.GLPaint

> This module is still work in progress. The opacity currently cannot be changed and the image needs to be placed inside the module directly.

<img width="310" src="http://abload.de/img/simulatorscreenshot09b4jwb.png">

## Usage

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

paintView.addEventListener("touchesBegan", function(e) {
    Ti.API.info('Touches began');
    Ti.API.info(e);
});

paintView.addEventListener("touchesMoved", function(e) {
    Ti.API.info('Touches moved');
    Ti.API.info(e);
});

paintView.addEventListener("touchesEnded", function(e) {
    Ti.API.info('Touches ended');
    Ti.API.info(e);
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

## Copyright

&copy; 2016 by Hans Knoechel
