var module = require("ti.glpaint");
var isErasing = false;
var brushes = ["brush.png", "brush2.png", "brush3.png", "brush4.png", "brush5.png"];

var win = Ti.UI.createWindow({
    backgroundColor: "#fff",
    translucent: false,
    title: "Ti.GLPaint"
});

var paintView = module.createPaintView({

});

// Receive the current painting step
/*paintView.addEventListener("paintstep", function(e) {
    Ti.API.warn("From: " + e.startX + "/" + e.startY + " to " + e.endX + "/" + e.endY);
});*/

// Select brush
var brushSelect = Ti.UI.createButton({title: "Select Brush"});
brushSelect.addEventListener("click", function(e) {
    var options = Ti.UI.createOptionDialog({
        options: brushes
    });
    options.addEventListener("click", function(e) {
        if (e.index == brushes.length) {
            return;
        }
        
        paintView.setBrushColor("red");
        paintView.setBrushImage(brushes[e.index]);
    });
    options.show();
});

// Clear painting area
var clearButton = Ti.UI.createButton({title: "Clear"});
clearButton.addEventListener("click", function(e) {
    // paintView.setErasing(isErasing);
    paintView.erase();
});

var snapshotButton = Ti.UI.createButton({
    title: "Take snapshot",
    bottom: 30
});

snapshotButton.addEventListener("click", function() {
    var image = paintView.takeGLSnapshot();
    var win2 = Ti.UI.createWindow({title: "Snapshot", backgroundColor: "#333", translucent: false});
    win2.add(Ti.UI.createImageView({image: image}));
    nav.openWindow(win2);
});

win.add(paintView);
win.setLeftNavButton(clearButton);
win.setRightNavButton(brushSelect);
win.add(snapshotButton);

// Initial brush setup after the view has been added to it's super-view
paintView.applyProperties({
    brushColor: "green",
    brushImage: "brush.png",
//    brushScale: 1,
//    brushPixelStep: 1
})

var nav = Ti.UI.iOS.createNavigationWindow({window: win});
nav.open();