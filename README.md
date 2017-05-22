# Get Schwifty \o/

Get Schwifty is an app to run Swift on your iOS device. I created this project as an application for a scholarship to Apples WWDC 2017. Get Schwifty is also available on the [App Store](https://itunes.apple.com/de/app/get-schwifty/id1222398681?l=en&mt=8).

It is using a lexer to power syntax highlighting, a parser, abstract syntax tree to get semantic information about the source code.

If the code does not contain any errors or unimplemented features a generator is used to generate JavaScript code that is eventually evaluated in JavaScriptCore.

The project was created during my application for a scholarship at WWDC 17.

## Demo

![](img/live.gif)

## How does that work?!

It's much less magic as it seems in the first moment. I wrote a lexer which creates tokens out of the given source code. This output is also used to create syntax highlighting within a standard UITextView. The tokens are also used by a parser which creates semantic information via an abstract syntax tree.
The real magic happens with that semantic information. Since it's not possible to run compiled binaries on iOS within an app context I generate Javascript code out of the syntax tree. JavaScriptCore is a framework which is used to execute the generated code. I created handlers for calls to `print` and `alert` to be able to get some output.

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

The easiest way to get 'Get Schwifty' is by installing it from the [App Store](https://itunes.apple.com/de/app/get-schwifty/id1222398681?l=en&mt=8). If you would like to test the latest version of the app, send me a message on Twitter ([@benchr](https://twitter.com/benchr)) and I'll add you to Testflight if there are enough free slots.

## What about the license?

Currently I don't want to decide where the project is heading to, so I didn't add a license file. Feel free to clone the project, run it on your device and send contributions. I will add the license later when I decided about it.
