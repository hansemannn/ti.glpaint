// This is a test harness for your module
// You should do something interesting in this harness
// to test out the module and to provide instructions
// to users on how to use it by example.


// open a single window
var win = Ti.UI.createWindow({
	backgroundColor:'white'
});
var label = Ti.UI.createLabel();
win.add(label);
win.open();

// TODO: write your module tests here
var ti_glpaint = require('ti.glpaint');
Ti.API.info("module is => " + ti_glpaint);

label.text = ti_glpaint.example();

Ti.API.info("module exampleProp is => " + ti_glpaint.exampleProp);
ti_glpaint.exampleProp = "This is a test value";

if (Ti.Platform.name == "android") {
	var proxy = ti_glpaint.createExample({
		message: "Creating an example Proxy",
		backgroundColor: "red",
		width: 100,
		height: 100,
		top: 100,
		left: 150
	});

	proxy.printMessage("Hello world!");
	proxy.message = "Hi world!.  It's me again.";
	proxy.printMessage("Hello world!");
	win.add(proxy);
}

