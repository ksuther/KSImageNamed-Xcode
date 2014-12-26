# KSImageNamed-Xcode
---

## What is this?

Can't remember whether that image you just added to the project was called `button-separator-left` or `button-left-separator`? Now you don't have to, because this will autocomplete your `imageNamed:` calls like you'd expect. Just type in `[NSImage imageNamed:` or `[UIImage imageNamed:` and all the images in your project will conveniently appear in the autocomplete menu. You'll even get a handy preview of the image you're about to select.

![Screenshot](https://raw.github.com/ksuther/KSImageNamed-Xcode/master/screenshot.gif)

## How do I use it?

Build the KSImageNamed target in the Xcode project and the plug-in will automatically be installed in `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`. Relaunch Xcode and `imageNamed:` will magically start autocompleting your images.

## What does this work with?

Developed and tested against Xcode 6 and 6.1. It will probably work with Xcode 5.1.1 also.

## How do I include file extensions when autocompleting?

Enter the following command and relaunch Xcode:  
`defaults write com.apple.dt.Xcode KSShowExtensionInImageCompletion -bool YES`

## Possible future improvements

Ideas for people who might want to hack on this:

1. Only include images that are in the current project. Currently all images in the workspace are shown.
2. Show an image preview and dimensions when clicking on an imageNamed: string in the editor
3. Switch to ARC since garbage collection support has been dropped

## License

MIT License

    Copyright (c) 2013 Kent Sutherland
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to use,
    copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
    Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
