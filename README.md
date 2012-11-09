# TvT

TvT (Tanks vs. Tanks) is an in-browser 2D top-down multiplayer game inspired by [BZFlag](http://bzflag.org/). This package is comprised of both the server and client portions.

## Requirements
TvT is brought to you by the use of [Node.js](http://nodejs.org/), [CoffeeScript](http://coffeescript.org/), several packages available via [npm](https://npmjs.org/), Chrome, and other technologies.

### Make
You'll need the `make` command to build TvT at this time. For *nix-based platforms, you probably already have this, or can get it easily. For Windows, your best bet will be [Cygwin](http://www.cygwin.com/).

### Git
It's easiest to work with our software if you have Git, because you can pull the latest changes quickly and easily. Visit the [Git website](http://git-scm.com/) to [download the latest version](http://git-scm.com/downloads). Note that this is probably easier on *nix-based platforms.

### Node.js
This is the first thing that should be installed. A [convenient tutorial is available](https://github.com/joyent/node/wiki/Installation) for your reading pleasure. You should grab the latest Node.js, although we have only tested with `v0.8.12`.

### npm
In almost all circumstances, all new Node.js installations come with npm. So you're good to go there!

### Everything Else
Once you've gotten Node.js and npm, installing TvT's other dependencies becomes easy! If you don't have Git, you'll need to get a tarball from GitHub instead and unpack it.

    git clone git://github.com/dvicory/TvT.git
    cd TvT
    npm install .

`npm install .` will take a look at `package.json` and go ahead and grab everything you need to build TvT and run a TvT server.

## Usage
At this point, you'll only have TvT's dependencies setup. In the TvT directory you need to:

    make
    make install

This will compile TvT's CoffeeScript into JavaScript and get the modules ready for the browser. It is installed locally and not into any system directories.
