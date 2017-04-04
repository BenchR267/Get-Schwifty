# Get Schwifty

Get Schwifty is an app to run Swift on your iOS device. I created this project as an application for a scholarship to Apples WWDC 2017. The app is currently not available on the App Store.

It is using a lexer to power syntax highlighting, a parser, abstract syntax tree to get semantic information about the source code.

If the code does not contain any errors or unimplemented features a generator is used to generate JavaScript code that is eventually evaluated in JavaScriptCore.

The project was created during my application for a scholarship at WWDC 17.

## Demo

![](img/live.gif)

## What features are implemented?

The project currently supports the following language features:

* var, let, func declarations
* if, else if and else control structures
* while loops
* simple calculation and conditional expressions
* function calls (currently without external parameters)
* recursive function calls
* simple type system

## What features are missing?

The list of missing features is too long for this page, so I will only name one of the most important ones:

* classes, structs and other complex types
* methods
* generics
* higher order functions
* framework bindings

## How can I get it?

Currently the app is only available through Testflight external testing. If you would like to test the app, send me a message on Twitter ([@benchr](https://twitter.com/benchr)) and I'll add you if there are enough free slots.

## What about the license?

Currently I don't want to decide where the project is heading to, so I didn't add a license file. Feel free to clone the project, run it on your device and send contributions. I will add the license later when I decided about it.
