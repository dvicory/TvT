(function(){var require = function (file, cwd) {
    var resolved = require.resolve(file, cwd || '/');
    var mod = require.modules[resolved];
    if (!mod) throw new Error(
        'Failed to resolve module ' + file + ', tried ' + resolved
    );
    var cached = require.cache[resolved];
    var res = cached? cached.exports : mod();
    return res;
};

require.paths = [];
require.modules = {};
require.cache = {};
require.extensions = [".js",".coffee",".json"];

require._core = {
    'assert': true,
    'events': true,
    'fs': true,
    'path': true,
    'vm': true
};

require.resolve = (function () {
    return function (x, cwd) {
        if (!cwd) cwd = '/';
        
        if (require._core[x]) return x;
        var path = require.modules.path();
        cwd = path.resolve('/', cwd);
        var y = cwd || '/';
        
        if (x.match(/^(?:\.\.?\/|\/)/)) {
            var m = loadAsFileSync(path.resolve(y, x))
                || loadAsDirectorySync(path.resolve(y, x));
            if (m) return m;
        }
        
        var n = loadNodeModulesSync(x, y);
        if (n) return n;
        
        throw new Error("Cannot find module '" + x + "'");
        
        function loadAsFileSync (x) {
            x = path.normalize(x);
            if (require.modules[x]) {
                return x;
            }
            
            for (var i = 0; i < require.extensions.length; i++) {
                var ext = require.extensions[i];
                if (require.modules[x + ext]) return x + ext;
            }
        }
        
        function loadAsDirectorySync (x) {
            x = x.replace(/\/+$/, '');
            var pkgfile = path.normalize(x + '/package.json');
            if (require.modules[pkgfile]) {
                var pkg = require.modules[pkgfile]();
                var b = pkg.browserify;
                if (typeof b === 'object' && b.main) {
                    var m = loadAsFileSync(path.resolve(x, b.main));
                    if (m) return m;
                }
                else if (typeof b === 'string') {
                    var m = loadAsFileSync(path.resolve(x, b));
                    if (m) return m;
                }
                else if (pkg.main) {
                    var m = loadAsFileSync(path.resolve(x, pkg.main));
                    if (m) return m;
                }
            }
            
            return loadAsFileSync(x + '/index');
        }
        
        function loadNodeModulesSync (x, start) {
            var dirs = nodeModulesPathsSync(start);
            for (var i = 0; i < dirs.length; i++) {
                var dir = dirs[i];
                var m = loadAsFileSync(dir + '/' + x);
                if (m) return m;
                var n = loadAsDirectorySync(dir + '/' + x);
                if (n) return n;
            }
            
            var m = loadAsFileSync(x);
            if (m) return m;
        }
        
        function nodeModulesPathsSync (start) {
            var parts;
            if (start === '/') parts = [ '' ];
            else parts = path.normalize(start).split('/');
            
            var dirs = [];
            for (var i = parts.length - 1; i >= 0; i--) {
                if (parts[i] === 'node_modules') continue;
                var dir = parts.slice(0, i + 1).join('/') + '/node_modules';
                dirs.push(dir);
            }
            
            return dirs;
        }
    };
})();

require.alias = function (from, to) {
    var path = require.modules.path();
    var res = null;
    try {
        res = require.resolve(from + '/package.json', '/');
    }
    catch (err) {
        res = require.resolve(from, '/');
    }
    var basedir = path.dirname(res);
    
    var keys = (Object.keys || function (obj) {
        var res = [];
        for (var key in obj) res.push(key);
        return res;
    })(require.modules);
    
    for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        if (key.slice(0, basedir.length + 1) === basedir + '/') {
            var f = key.slice(basedir.length);
            require.modules[to + f] = require.modules[basedir + f];
        }
        else if (key === basedir) {
            require.modules[to] = require.modules[basedir];
        }
    }
};

(function () {
    var process = {};
    var global = typeof window !== 'undefined' ? window : {};
    var definedProcess = false;
    
    require.define = function (filename, fn) {
        if (!definedProcess && require.modules.__browserify_process) {
            process = require.modules.__browserify_process();
            definedProcess = true;
        }
        
        var dirname = require._core[filename]
            ? ''
            : require.modules.path().dirname(filename)
        ;
        
        var require_ = function (file) {
            var requiredModule = require(file, dirname);
            var cached = require.cache[require.resolve(file, dirname)];

            if (cached && cached.parent === null) {
                cached.parent = module_;
            }

            return requiredModule;
        };
        require_.resolve = function (name) {
            return require.resolve(name, dirname);
        };
        require_.modules = require.modules;
        require_.define = require.define;
        require_.cache = require.cache;
        var module_ = {
            id : filename,
            filename: filename,
            exports : {},
            loaded : false,
            parent: null
        };
        
        require.modules[filename] = function () {
            require.cache[filename] = module_;
            fn.call(
                module_.exports,
                require_,
                module_,
                module_.exports,
                dirname,
                filename,
                process,
                global
            );
            module_.loaded = true;
            return module_.exports;
        };
    };
})();


require.define("path",function(require,module,exports,__dirname,__filename,process,global){function filter (xs, fn) {
    var res = [];
    for (var i = 0; i < xs.length; i++) {
        if (fn(xs[i], i, xs)) res.push(xs[i]);
    }
    return res;
}

// resolves . and .. elements in a path array with directory names there
// must be no slashes, empty elements, or device names (c:\) in the array
// (so also no leading and trailing slashes - it does not distinguish
// relative and absolute paths)
function normalizeArray(parts, allowAboveRoot) {
  // if the path tries to go above the root, `up` ends up > 0
  var up = 0;
  for (var i = parts.length; i >= 0; i--) {
    var last = parts[i];
    if (last == '.') {
      parts.splice(i, 1);
    } else if (last === '..') {
      parts.splice(i, 1);
      up++;
    } else if (up) {
      parts.splice(i, 1);
      up--;
    }
  }

  // if the path is allowed to go above the root, restore leading ..s
  if (allowAboveRoot) {
    for (; up--; up) {
      parts.unshift('..');
    }
  }

  return parts;
}

// Regex to split a filename into [*, dir, basename, ext]
// posix version
var splitPathRe = /^(.+\/(?!$)|\/)?((?:.+?)?(\.[^.]*)?)$/;

// path.resolve([from ...], to)
// posix version
exports.resolve = function() {
var resolvedPath = '',
    resolvedAbsolute = false;

for (var i = arguments.length; i >= -1 && !resolvedAbsolute; i--) {
  var path = (i >= 0)
      ? arguments[i]
      : process.cwd();

  // Skip empty and invalid entries
  if (typeof path !== 'string' || !path) {
    continue;
  }

  resolvedPath = path + '/' + resolvedPath;
  resolvedAbsolute = path.charAt(0) === '/';
}

// At this point the path should be resolved to a full absolute path, but
// handle relative paths to be safe (might happen when process.cwd() fails)

// Normalize the path
resolvedPath = normalizeArray(filter(resolvedPath.split('/'), function(p) {
    return !!p;
  }), !resolvedAbsolute).join('/');

  return ((resolvedAbsolute ? '/' : '') + resolvedPath) || '.';
};

// path.normalize(path)
// posix version
exports.normalize = function(path) {
var isAbsolute = path.charAt(0) === '/',
    trailingSlash = path.slice(-1) === '/';

// Normalize the path
path = normalizeArray(filter(path.split('/'), function(p) {
    return !!p;
  }), !isAbsolute).join('/');

  if (!path && !isAbsolute) {
    path = '.';
  }
  if (path && trailingSlash) {
    path += '/';
  }
  
  return (isAbsolute ? '/' : '') + path;
};


// posix version
exports.join = function() {
  var paths = Array.prototype.slice.call(arguments, 0);
  return exports.normalize(filter(paths, function(p, index) {
    return p && typeof p === 'string';
  }).join('/'));
};


exports.dirname = function(path) {
  var dir = splitPathRe.exec(path)[1] || '';
  var isWindows = false;
  if (!dir) {
    // No dirname
    return '.';
  } else if (dir.length === 1 ||
      (isWindows && dir.length <= 3 && dir.charAt(1) === ':')) {
    // It is just a slash or a drive letter with a slash
    return dir;
  } else {
    // It is a full dirname, strip trailing slash
    return dir.substring(0, dir.length - 1);
  }
};


exports.basename = function(path, ext) {
  var f = splitPathRe.exec(path)[2] || '';
  // TODO: make this comparison case-insensitive on windows?
  if (ext && f.substr(-1 * ext.length) === ext) {
    f = f.substr(0, f.length - ext.length);
  }
  return f;
};


exports.extname = function(path) {
  return splitPathRe.exec(path)[3] || '';
};

});

require.define("__browserify_process",function(require,module,exports,__dirname,__filename,process,global){var process = module.exports = {};

process.nextTick = (function () {
    var canSetImmediate = typeof window !== 'undefined'
        && window.setImmediate;
    var canPost = typeof window !== 'undefined'
        && window.postMessage && window.addEventListener
    ;

    if (canSetImmediate) {
        return window.setImmediate;
    }

    if (canPost) {
        var queue = [];
        window.addEventListener('message', function (ev) {
            if (ev.source === window && ev.data === 'browserify-tick') {
                ev.stopPropagation();
                if (queue.length > 0) {
                    var fn = queue.shift();
                    fn();
                }
            }
        }, true);

        return function nextTick(fn) {
            queue.push(fn);
            window.postMessage('browserify-tick', '*');
        };
    }

    return function nextTick(fn) {
        setTimeout(fn, 0);
    };
})();

process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];

process.binding = function (name) {
    if (name === 'evals') return (require)('vm')
    else throw new Error('No such module. (Possibly not yet loaded)')
};

(function () {
    var cwd = '/';
    var path;
    process.cwd = function () { return cwd };
    process.chdir = function (dir) {
        if (!path) path = require('path');
        cwd = path.resolve(dir, cwd);
    };
})();

});

require.define("/lib/common/EventEmitter.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.4.0
(function() {
  var EventEmitter, EventEmitter2,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter2 = require('eventemitter2').EventEmitter2;

  EventEmitter = (function(_super) {

    __extends(EventEmitter, _super);

    EventEmitter.prototype.DraggedItems = {};

    EventEmitter.prototype._private = {};

    function EventEmitter(options) {
      options = pulse.util.checkParams(options, {
        owner: null,
        masterCallback: null,
        wildcard: false,
        delimiter: '.',
        maxListeners: 10
      });
      this.owner = options.owner;
      this.masterCallback = options.masterCallback;
      this._private.touchDown = false;
      EventEmitter.__super__.constructor.call(this, {
        wildcard: options.wildcard,
        delimiter: options.delimiter,
        maxListeners: options.maxListeners
      });
    }

    EventEmitter.prototype.bind = function(event, listener) {
      return this.on(event, listener);
    };

    EventEmitter.prototype.unbind = function(event) {
      return this.removeAllListeners(event);
    };

    EventEmitter.prototype.unbindFunction = function(event, listener) {
      return this.removeListener(event, listener);
    };

    EventEmitter.prototype.hasEvent = function(event) {
      if (this.listeners(event).length !== 0) {
        return true;
      }
      return false;
    };

    EventEmitter.prototype.raiseEvent = function(event, data) {
      if (event === 'touchstart' && this._private.touchDown === false) {
        this._private.touchDown = true;
      } else if (event === 'touchend' && this._private.touchDown === true) {
        this.raiseEvent('touchclick', data);
      } else if (event === 'touchclick' || event === 'mouseout') {
        this._private.touchDown = false;
      }
      this.emit(event, data);
      if (typeof this.masterCallback === 'function') {
        if (this.owner != null) {
          return this.masterCallback.call(this.owner, event, data);
        } else {
          return this.masterCallback(event, data);
        }
      }
    };

    EventEmitter.prototype.checkType = function(type) {
      var t, _i, _len, _ref;
      if (type === 'click' && pulse.util.eventSupported('touchend')) {
        return 'touchclick';
      }
      _ref = pulse.eventtranslations;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        t = _ref[_i];
        if (type === pulse.eventtranslations[t] && pulse.util.eventSupported(t)) {
          return t;
        }
      }
      return type;
    };

    return EventEmitter;

  })(EventEmitter2);

  module.exports = EventEmitter;

}).call(this);

});

require.define("/node_modules/eventemitter2/package.json",function(require,module,exports,__dirname,__filename,process,global){module.exports = {"main":"./lib/eventemitter2.js"}
});

require.define("/node_modules/eventemitter2/lib/eventemitter2.js",function(require,module,exports,__dirname,__filename,process,global){;!function(exports, undefined) {

  var isArray = Array.isArray ? Array.isArray : function _isArray(obj) {
    return Object.prototype.toString.call(obj) === "[object Array]";
  };
  var defaultMaxListeners = 10;

  function init() {
    this._events = {};
    if (this._conf) {
      configure.call(this, this._conf);
    }
  }

  function configure(conf) {
    if (conf) {
      
      this._conf = conf;
      
      conf.delimiter && (this.delimiter = conf.delimiter);
      conf.maxListeners && (this._events.maxListeners = conf.maxListeners);
      conf.wildcard && (this.wildcard = conf.wildcard);
      conf.newListener && (this.newListener = conf.newListener);

      if (this.wildcard) {
        this.listenerTree = {};
      }
    }
  }

  function EventEmitter(conf) {
    this._events = {};
    this.newListener = false;
    configure.call(this, conf);
  }

  //
  // Attention, function return type now is array, always !
  // It has zero elements if no any matches found and one or more
  // elements (leafs) if there are matches
  //
  function searchListenerTree(handlers, type, tree, i) {
    if (!tree) {
      return [];
    }
    var listeners=[], leaf, len, branch, xTree, xxTree, isolatedBranch, endReached,
        typeLength = type.length, currentType = type[i], nextType = type[i+1];
    if (i === typeLength && tree._listeners) {
      //
      // If at the end of the event(s) list and the tree has listeners
      // invoke those listeners.
      //
      if (typeof tree._listeners === 'function') {
        handlers && handlers.push(tree._listeners);
        return [tree];
      } else {
        for (leaf = 0, len = tree._listeners.length; leaf < len; leaf++) {
          handlers && handlers.push(tree._listeners[leaf]);
        }
        return [tree];
      }
    }

    if ((currentType === '*' || currentType === '**') || tree[currentType]) {
      //
      // If the event emitted is '*' at this part
      // or there is a concrete match at this patch
      //
      if (currentType === '*') {
        for (branch in tree) {
          if (branch !== '_listeners' && tree.hasOwnProperty(branch)) {
            listeners = listeners.concat(searchListenerTree(handlers, type, tree[branch], i+1));
          }
        }
        return listeners;
      } else if(currentType === '**') {
        endReached = (i+1 === typeLength || (i+2 === typeLength && nextType === '*'));
        if(endReached && tree._listeners) {
          // The next element has a _listeners, add it to the handlers.
          listeners = listeners.concat(searchListenerTree(handlers, type, tree, typeLength));
        }

        for (branch in tree) {
          if (branch !== '_listeners' && tree.hasOwnProperty(branch)) {
            if(branch === '*' || branch === '**') {
              if(tree[branch]._listeners && !endReached) {
                listeners = listeners.concat(searchListenerTree(handlers, type, tree[branch], typeLength));
              }
              listeners = listeners.concat(searchListenerTree(handlers, type, tree[branch], i));
            } else if(branch === nextType) {
              listeners = listeners.concat(searchListenerTree(handlers, type, tree[branch], i+2));
            } else {
              // No match on this one, shift into the tree but not in the type array.
              listeners = listeners.concat(searchListenerTree(handlers, type, tree[branch], i));
            }
          }
        }
        return listeners;
      }

      listeners = listeners.concat(searchListenerTree(handlers, type, tree[currentType], i+1));
    }

    xTree = tree['*'];
    if (xTree) {
      //
      // If the listener tree will allow any match for this part,
      // then recursively explore all branches of the tree
      //
      searchListenerTree(handlers, type, xTree, i+1);
    }
    
    xxTree = tree['**'];
    if(xxTree) {
      if(i < typeLength) {
        if(xxTree._listeners) {
          // If we have a listener on a '**', it will catch all, so add its handler.
          searchListenerTree(handlers, type, xxTree, typeLength);
        }
        
        // Build arrays of matching next branches and others.
        for(branch in xxTree) {
          if(branch !== '_listeners' && xxTree.hasOwnProperty(branch)) {
            if(branch === nextType) {
              // We know the next element will match, so jump twice.
              searchListenerTree(handlers, type, xxTree[branch], i+2);
            } else if(branch === currentType) {
              // Current node matches, move into the tree.
              searchListenerTree(handlers, type, xxTree[branch], i+1);
            } else {
              isolatedBranch = {};
              isolatedBranch[branch] = xxTree[branch];
              searchListenerTree(handlers, type, { '**': isolatedBranch }, i+1);
            }
          }
        }
      } else if(xxTree._listeners) {
        // We have reached the end and still on a '**'
        searchListenerTree(handlers, type, xxTree, typeLength);
      } else if(xxTree['*'] && xxTree['*']._listeners) {
        searchListenerTree(handlers, type, xxTree['*'], typeLength);
      }
    }

    return listeners;
  }

  function growListenerTree(type, listener) {

    type = typeof type === 'string' ? type.split(this.delimiter) : type.slice();
    
    //
    // Looks for two consecutive '**', if so, don't add the event at all.
    //
    for(var i = 0, len = type.length; i+1 < len; i++) {
      if(type[i] === '**' && type[i+1] === '**') {
        return;
      }
    }

    var tree = this.listenerTree;
    var name = type.shift();

    while (name) {

      if (!tree[name]) {
        tree[name] = {};
      }

      tree = tree[name];

      if (type.length === 0) {

        if (!tree._listeners) {
          tree._listeners = listener;
        }
        else if(typeof tree._listeners === 'function') {
          tree._listeners = [tree._listeners, listener];
        }
        else if (isArray(tree._listeners)) {

          tree._listeners.push(listener);

          if (!tree._listeners.warned) {

            var m = defaultMaxListeners;
            
            if (typeof this._events.maxListeners !== 'undefined') {
              m = this._events.maxListeners;
            }

            if (m > 0 && tree._listeners.length > m) {

              tree._listeners.warned = true;
              console.error('(node) warning: possible EventEmitter memory ' +
                            'leak detected. %d listeners added. ' +
                            'Use emitter.setMaxListeners() to increase limit.',
                            tree._listeners.length);
              console.trace();
            }
          }
        }
        return true;
      }
      name = type.shift();
    }
    return true;
  };

  // By default EventEmitters will print a warning if more than
  // 10 listeners are added to it. This is a useful default which
  // helps finding memory leaks.
  //
  // Obviously not all Emitters should be limited to 10. This function allows
  // that to be increased. Set to zero for unlimited.

  EventEmitter.prototype.delimiter = '.';

  EventEmitter.prototype.setMaxListeners = function(n) {
    this._events || init.call(this);
    this._events.maxListeners = n;
    if (!this._conf) this._conf = {};
    this._conf.maxListeners = n;
  };

  EventEmitter.prototype.event = '';

  EventEmitter.prototype.once = function(event, fn) {
    this.many(event, 1, fn);
    return this;
  };

  EventEmitter.prototype.many = function(event, ttl, fn) {
    var self = this;

    if (typeof fn !== 'function') {
      throw new Error('many only accepts instances of Function');
    }

    function listener() {
      if (--ttl === 0) {
        self.off(event, listener);
      }
      fn.apply(this, arguments);
    };

    listener._origin = fn;

    this.on(event, listener);

    return self;
  };

  EventEmitter.prototype.emit = function() {
    
    this._events || init.call(this);

    var type = arguments[0];

    if (type === 'newListener' && !this.newListener) {
      if (!this._events.newListener) { return false; }
    }

    // Loop through the *_all* functions and invoke them.
    if (this._all) {
      var l = arguments.length;
      var args = new Array(l - 1);
      for (var i = 1; i < l; i++) args[i - 1] = arguments[i];
      for (i = 0, l = this._all.length; i < l; i++) {
        this.event = type;
        this._all[i].apply(this, args);
      }
    }

    // If there is no 'error' event listener then throw.
    if (type === 'error') {
      
      if (!this._all && 
        !this._events.error && 
        !(this.wildcard && this.listenerTree.error)) {

        if (arguments[1] instanceof Error) {
          throw arguments[1]; // Unhandled 'error' event
        } else {
          throw new Error("Uncaught, unspecified 'error' event.");
        }
        return false;
      }
    }

    var handler;

    if(this.wildcard) {
      handler = [];
      var ns = typeof type === 'string' ? type.split(this.delimiter) : type.slice();
      searchListenerTree.call(this, handler, ns, this.listenerTree, 0);
    }
    else {
      handler = this._events[type];
    }

    if (typeof handler === 'function') {
      this.event = type;
      if (arguments.length === 1) {
        handler.call(this);
      }
      else if (arguments.length > 1)
        switch (arguments.length) {
          case 2:
            handler.call(this, arguments[1]);
            break;
          case 3:
            handler.call(this, arguments[1], arguments[2]);
            break;
          // slower
          default:
            var l = arguments.length;
            var args = new Array(l - 1);
            for (var i = 1; i < l; i++) args[i - 1] = arguments[i];
            handler.apply(this, args);
        }
      return true;
    }
    else if (handler) {
      var l = arguments.length;
      var args = new Array(l - 1);
      for (var i = 1; i < l; i++) args[i - 1] = arguments[i];

      var listeners = handler.slice();
      for (var i = 0, l = listeners.length; i < l; i++) {
        this.event = type;
        listeners[i].apply(this, args);
      }
      return (listeners.length > 0) || this._all;
    }
    else {
      return this._all;
    }

  };

  EventEmitter.prototype.on = function(type, listener) {
    
    if (typeof type === 'function') {
      this.onAny(type);
      return this;
    }

    if (typeof listener !== 'function') {
      throw new Error('on only accepts instances of Function');
    }
    this._events || init.call(this);

    // To avoid recursion in the case that type == "newListeners"! Before
    // adding it to the listeners, first emit "newListeners".
    this.emit('newListener', type, listener);

    if(this.wildcard) {
      growListenerTree.call(this, type, listener);
      return this;
    }

    if (!this._events[type]) {
      // Optimize the case of one listener. Don't need the extra array object.
      this._events[type] = listener;
    }
    else if(typeof this._events[type] === 'function') {
      // Adding the second element, need to change to array.
      this._events[type] = [this._events[type], listener];
    }
    else if (isArray(this._events[type])) {
      // If we've already got an array, just append.
      this._events[type].push(listener);

      // Check for listener leak
      if (!this._events[type].warned) {

        var m = defaultMaxListeners;
        
        if (typeof this._events.maxListeners !== 'undefined') {
          m = this._events.maxListeners;
        }

        if (m > 0 && this._events[type].length > m) {

          this._events[type].warned = true;
          console.error('(node) warning: possible EventEmitter memory ' +
                        'leak detected. %d listeners added. ' +
                        'Use emitter.setMaxListeners() to increase limit.',
                        this._events[type].length);
          console.trace();
        }
      }
    }
    return this;
  };

  EventEmitter.prototype.onAny = function(fn) {

    if(!this._all) {
      this._all = [];
    }

    if (typeof fn !== 'function') {
      throw new Error('onAny only accepts instances of Function');
    }

    // Add the function to the event listener collection.
    this._all.push(fn);
    return this;
  };

  EventEmitter.prototype.addListener = EventEmitter.prototype.on;

  EventEmitter.prototype.off = function(type, listener) {
    if (typeof listener !== 'function') {
      throw new Error('removeListener only takes instances of Function');
    }

    var handlers,leafs=[];

    if(this.wildcard) {
      var ns = typeof type === 'string' ? type.split(this.delimiter) : type.slice();
      leafs = searchListenerTree.call(this, null, ns, this.listenerTree, 0);
    }
    else {
      // does not use listeners(), so no side effect of creating _events[type]
      if (!this._events[type]) return this;
      handlers = this._events[type];
      leafs.push({_listeners:handlers});
    }

    for (var iLeaf=0; iLeaf<leafs.length; iLeaf++) {
      var leaf = leafs[iLeaf];
      handlers = leaf._listeners;
      if (isArray(handlers)) {

        var position = -1;

        for (var i = 0, length = handlers.length; i < length; i++) {
          if (handlers[i] === listener ||
            (handlers[i].listener && handlers[i].listener === listener) ||
            (handlers[i]._origin && handlers[i]._origin === listener)) {
            position = i;
            break;
          }
        }

        if (position < 0) {
          return this;
        }

        if(this.wildcard) {
          leaf._listeners.splice(position, 1)
        }
        else {
          this._events[type].splice(position, 1);
        }

        if (handlers.length === 0) {
          if(this.wildcard) {
            delete leaf._listeners;
          }
          else {
            delete this._events[type];
          }
        }
      }
      else if (handlers === listener ||
        (handlers.listener && handlers.listener === listener) ||
        (handlers._origin && handlers._origin === listener)) {
        if(this.wildcard) {
          delete leaf._listeners;
        }
        else {
          delete this._events[type];
        }
      }
    }

    return this;
  };

  EventEmitter.prototype.offAny = function(fn) {
    var i = 0, l = 0, fns;
    if (fn && this._all && this._all.length > 0) {
      fns = this._all;
      for(i = 0, l = fns.length; i < l; i++) {
        if(fn === fns[i]) {
          fns.splice(i, 1);
          return this;
        }
      }
    } else {
      this._all = [];
    }
    return this;
  };

  EventEmitter.prototype.removeListener = EventEmitter.prototype.off;

  EventEmitter.prototype.removeAllListeners = function(type) {
    if (arguments.length === 0) {
      !this._events || init.call(this);
      return this;
    }

    if(this.wildcard) {
      var ns = typeof type === 'string' ? type.split(this.delimiter) : type.slice();
      var leafs = searchListenerTree.call(this, null, ns, this.listenerTree, 0);

      for (var iLeaf=0; iLeaf<leafs.length; iLeaf++) {
        var leaf = leafs[iLeaf];
        leaf._listeners = null;
      }
    }
    else {
      if (!this._events[type]) return this;
      this._events[type] = null;
    }
    return this;
  };

  EventEmitter.prototype.listeners = function(type) {
    if(this.wildcard) {
      var handlers = [];
      var ns = typeof type === 'string' ? type.split(this.delimiter) : type.slice();
      searchListenerTree.call(this, handlers, ns, this.listenerTree, 0);
      return handlers;
    }

    this._events || init.call(this);

    if (!this._events[type]) this._events[type] = [];
    if (!isArray(this._events[type])) {
      this._events[type] = [this._events[type]];
    }
    return this._events[type];
  };

  EventEmitter.prototype.listenersAny = function() {

    if(this._all) {
      return this._all;
    }
    else {
      return [];
    }

  };

  if (typeof define === 'function' && define.amd) {
    define(function() {
      return EventEmitter;
    });
  } else {
    exports.EventEmitter2 = EventEmitter; 
  }

}(typeof process !== 'undefined' && typeof process.title !== 'undefined' && typeof exports !== 'undefined' ? exports : window);

});

require.define("/lib/client/Protocol.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.4.0
(function() {

  exports.VERSION = 1;

}).call(this);

});

require.define("/lib/client/World.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.4.0
(function() {
  var Camera, DynamicSprite, LocalPlayer, World,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Camera = require('./Camera');

  DynamicSprite = require('./DynamicSprite');

  LocalPlayer = require('./LocalPlayer');

  World = (function(_super) {

    __extends(World, _super);

    function World(args) {
      var setupCallback,
        _this = this;
      if (args == null) {
        args = {};
      }
      args.src = 'img/textures/other/grass.png';
      if (!(args.socket instanceof io.SocketNamespace)) {
        throw new TypeError('socket is a required key in args and must be a socket.io socket');
      }
      if (!(args.joinData instanceof Object)) {
        throw new TypeError('joinData is a required key in args and must be an object');
      }
      this.socket = args.socket;
      World.__super__.constructor.call(this, args);
      this.camera = new Camera;
      setupCallback = function() {
        _this.worldLayer = new pulse.Layer;
        _this.worldLayer.anchor = {
          x: 0,
          y: 0
        };
        _this.parent.parent.addLayer(_this.worldLayer);
        _this.socket.once('self join', function() {
          _this.localPlayer = new LocalPlayer({
            name: 'Local Player',
            world: _this
          });
          return _this.worldLayer.addNode(_this.localPlayer);
        });
        _this.socket.emit('join', args.joinData);
        _this.socket.emit('get state');
        _this.socket.on('new player', function(newPlayerData) {
          return console.log(newPlayerData);
        });
        _this.socket.on('remove player', function(removePlayerData) {
          return console.log(removePlayerData);
        });
        return _this.socket.on('update player', function(updatePlayerData) {
          return console.log(updatePlayerData);
        });
      };
      setTimeout(setupCallback, 0);
    }

    World.prototype.update = function(elapsedMS) {
      var _this = this;
      if (this.texture.percentLoaded === 100 && !(this.offscreenBackground != null)) {
        this.offscreenBackground = document.createElement('canvas');
        this.setupOffscreenBackground();
        $(window).resize(function() {
          return _this.setupOffscreenBackground();
        });
      }
      if (this.localPlayer != null) {
        this.position = this.localPlayer.position;
      }
      return World.__super__.update.call(this, elapsedMS);
    };

    World.prototype.draw = function(ctx) {
      var height, startX, startY, width;
      if (this.texture.percentLoaded !== 100 || this.size.width === 0 || this.size.height === 0) {
        return;
      }
      if (this.offscreenBackground != null) {
        startX = Math.round(this.position.x) % this.texture.width();
        startY = Math.round(this.position.y) % this.texture.height();
        if (startX < 0) {
          startX += this.texture.width();
        }
        if (startY < 0) {
          startY += this.texture.height();
        }
        width = this.parent.size.width;
        height = this.parent.size.height;
        return ctx.drawImage(this.offscreenBackground, startX, startY, width, height, 0, 0, width, height);
      }
    };

    World.prototype.setupOffscreenBackground = function() {
      var bgPattern, ctx, height, width;
      width = this.parent.size.width;
      height = this.parent.size.height;
      this.offscreenBackground.width = Math.ceil((width + this.texture.width()) / this.texture.width()) * this.texture.width();
      this.offscreenBackground.height = Math.ceil((height + this.texture.height()) / this.texture.height()) * this.texture.height();
      ctx = this.offscreenBackground.getContext('2d');
      bgPattern = ctx.createPattern(this.getCurrentFrame(), 'repeat');
      ctx.fillStyle = bgPattern;
      return ctx.fillRect(0, 0, this.offscreenBackground.width, this.offscreenBackground.height);
    };

    return World;

  })(DynamicSprite);

  module.exports = World;

}).call(this);

});

require.define("/lib/client/Camera.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.4.0
(function() {
  var Camera,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Camera = (function() {

    function Camera() {
      this.transformView = __bind(this.transformView, this);
      Object.defineProperty(this, 'origin', {
        get: function() {
          return {
            x: $(window).width() / 2,
            y: $(window).height() / 2
          };
        }
      });
      Object.defineProperty(this, 'position', {
        get: function() {
          return this._position;
        },
        set: function(val) {
          return this._position = this.validatePosition(val);
        }
      });
      Object.defineProperty(this, 'panPosition', {
        get: function() {
          return this._panPosition;
        },
        set: function(val) {
          return this._panPosition = this.validatePosition(val);
        }
      });
      Object.defineProperty(this, 'cameraPosition', {
        get: function() {
          return {
            x: this.position.x + this.panPosition.x,
            y: this.position.y + this.panPosition.y
          };
        }
      });
      Object.defineProperty(this, 'zoom', {
        get: function() {
          return this._zoom;
        },
        set: function(val) {
          this._zoom = this.validateZoom(val);
          this._position = this.validatePosition(this._position);
          return this._panPosition = this.validatePosition(this._panPosition);
        }
      });
      Object.defineProperty(this, 'limits', {
        get: function() {
          return this._limits;
        },
        set: function(val) {
          this._limits = val;
          this._zoom = this.validateZoom(this._zoom);
          this._position = this.validatePosition(this._position);
          return this._panPosition = this.validatePosition(this._panPosition);
        }
      });
      this._zoom = 1;
      this._position = {
        x: 0,
        y: 0
      };
      this._panPosition = {
        x: 0,
        y: 0
      };
    }

    Camera.prototype.move = function(displacement) {
      var pos;
      pos = this.position;
      pos.x += displacement.x;
      pos.y += displacement.y;
      return this.position = pos;
    };

    Camera.prototype.pan = function(displacement) {
      var pPos;
      pPos = this.panPosition;
      this.panPosition.x += displacement.x;
      this.panPosition.y += displacement.y;
      return this.panPosition = pPos;
    };

    Camera.prototype.lookAt = function(position) {
      var pos;
      pos = {
        x: position.x + this.panPosition.x - this.origin.x,
        y: position.y + this.panPosition.y - this.origin.y
      };
      return this.position = pos;
    };

    Camera.prototype.transformView = function(ctx) {
      return ctx.translate(-this.cameraPosition.x, -this.cameraPosition.y);
    };

    Camera.prototype.validateZoom = function(zoom) {
      var minZoomX, minZoomY;
      if (typeof limits !== "undefined" && limits !== null) {
        minZoomX = $(window).width() / this.limits.x;
        minZoomY = $(window).height() / this.limits.y;
        return Math.max(zoom, Math.max(minZoomX, minZoomY));
      }
      return zoom;
    };

    Camera.prototype.validatePosition = function(pos) {
      return pos;
    };

    return Camera;

  })();

  module.exports = Camera;

}).call(this);

});

require.define("/lib/client/DynamicSprite.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.4.0
(function() {
  var DynamicSprite,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  DynamicSprite = (function(_super) {

    __extends(DynamicSprite, _super);

    function DynamicSprite(args) {
      var _this = this;
      if (args == null) {
        args = {};
      }
      if (args.world != null) {
        this.world = args.world;
      }
      DynamicSprite.__super__.constructor.call(this, args);
      this.worldInfo = {
        position: {
          x: 0,
          y: 0
        },
        rotation: 0,
        velocity: {
          x: 0,
          y: 0
        },
        maxVelocity: 0,
        velocityFactor: 0,
        angularVelocity: 0,
        maxAngularVelocity: 0,
        angularVelocityFactor: 0
      };
      $(window).resize(function() {
        return _this.updated = true;
      });
    }

    DynamicSprite.prototype.update = function(elapsedMS) {
      if (this.worldInfo.angularVelocityFactor !== 0 || this.worldInfo.velocityFactor !== 0) {
        this.updateVelocity();
      }
      if (this.worldInfo.angularVelocityFactor !== 0) {
        this.worldInfo.rotation += this.worldInfo.angularVelocity * (elapsedMS / 1000);
        if (this.worldInfo.rotation > Math.PI) {
          this.worldInfo.rotation = this.worldInfo.rotation - 2 * Math.PI;
        }
        if (this.worldInfo.rotation < -Math.PI) {
          this.worldInfo.rotation = 2 * Math.PI + this.worldInfo.rotation;
        }
        this.rotation = this.worldInfo.rotation * (180 / Math.PI);
      }
      if (this.worldInfo.velocityFactor !== 0) {
        this.worldInfo.position.x += this.worldInfo.velocity.x * (elapsedMS / 1000);
        this.worldInfo.position.y += this.worldInfo.velocity.y * (elapsedMS / 1000);
        this.position = this.worldInfo.position;
      }
      return DynamicSprite.__super__.update.call(this, elapsedMS);
    };

    DynamicSprite.prototype.draw = function(ctx) {
      if (this.world.camera != null) {
        return DynamicSprite.__super__.draw.call(this, ctx, this.world.camera.transformView);
      } else {
        return DynamicSprite.__super__.draw.call(this, ctx);
      }
    };

    DynamicSprite.prototype.updateVelocity = function() {
      this.worldInfo.velocity.x = Math.cos(this.worldInfo.rotation + (Math.PI / 2)) * this.worldInfo.velocityFactor * this.worldInfo.maxVelocity;
      this.worldInfo.velocity.y = Math.sin(this.worldInfo.rotation + (Math.PI / 2)) * this.worldInfo.velocityFactor * this.worldInfo.maxVelocity;
    };

    return DynamicSprite;

  })(pulse.Sprite);

  module.exports = DynamicSprite;

}).call(this);

});

require.define("/lib/client/LocalPlayer.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.4.0
(function() {
  var DynamicSprite, LocalPlayer,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  DynamicSprite = require('./DynamicSprite');

  LocalPlayer = (function(_super) {

    __extends(LocalPlayer, _super);

    function LocalPlayer(args) {
      this.handleKeyUp = __bind(this.handleKeyUp, this);

      this.handleKeyDown = __bind(this.handleKeyDown, this);
      if (args == null) {
        args = {};
      }
      args.src = 'img/textures/custom/tank_rogue.png';
      LocalPlayer.__super__.constructor.call(this, args);
      this.size = {
        width: 124,
        height: 153
      };
      this.worldInfo.maxVelocity = 150;
      this.worldInfo.maxAngularVelocity = Math.PI / 4;
      this.events.bind('keydown', this.handleKeyDown);
      this.events.bind('keyup', this.handleKeyUp);
    }

    LocalPlayer.prototype.handleKeyDown = function(e) {
      if (e.key === 'W') {
        this.worldInfo.velocityFactor = -1;
      }
      if (e.key === 'S') {
        this.worldInfo.velocityFactor = 1;
      }
      if (e.key === 'A') {
        this.worldInfo.angularVelocityFactor = -1;
      }
      if (e.key === 'D') {
        this.worldInfo.angularVelocityFactor = 1;
      }
      if (this.worldInfo.velocityFactor !== 0) {
        this.updateVelocity();
      }
      if (this.worldInfo.angularVelocityFactor !== 0) {
        this.worldInfo.angularVelocity = this.worldInfo.angularVelocityFactor * this.worldInfo.maxAngularVelocity;
      }
    };

    LocalPlayer.prototype.handleKeyUp = function(e) {
      if (e.key === 'W' || e.key === 'S') {
        this.worldInfo.velocityFactor = 0;
      }
      if (e.key === 'A' || e.key === 'D') {
        this.worldInfo.angularVelocityFactor = 0;
      }
    };

    LocalPlayer.prototype.update = function(elapsedMS) {
      LocalPlayer.__super__.update.call(this, elapsedMS);
      if (this.world.camera != null) {
        return this.world.camera.lookAt(this.position);
      }
    };

    return LocalPlayer;

  })(DynamicSprite);

  module.exports = LocalPlayer;

}).call(this);

});

require.define("/lib/client/Client.js",function(require,module,exports,__dirname,__filename,process,global){// Generated by CoffeeScript 1.4.0
(function() {
  var EventEmitter, Protocol, World,
    __hasProp = {}.hasOwnProperty;

  EventEmitter = require('../common/EventEmitter');

  Protocol = require('./Protocol');

  World = require('./World');

  pulse.EventManager = EventEmitter;

  pulse.ready(function() {
    var asset, assetBundle, assetManager;
    asset = new pulse.Texture('/img/textures/other/grass.png');
    assetBundle = new pulse.AssetBundle;
    assetManager = new pulse.AssetManager;
    assetBundle.addAsset(asset);
    console.log('outside function');
    assetManager.events.on('complete', function() {
      var count, engine, layer, scene, socket;
      console.log('within anonymous function');
      engine = new pulse.Engine({
        gameWindow: 'gameWindow',
        size: {
          width: $(window).width(),
          height: $(window).height()
        }
      });
      scene = new pulse.Scene({
        name: 'Main'
      });
      layer = new pulse.Layer;
      layer.anchor = {
        x: 0,
        y: 0
      };
      scene.addLayer(layer);
      engine.scenes.addScene(scene);
      engine.scenes.activateScene(scene);
      $(window).resize(function() {
        var key, _ref, _results;
        engine.size = {
          width: $(window).width(),
          height: $(window).height()
        };
        $('#gameWindow > div').width($(window).width());
        $('#gameWindow > div').height($(window).height());
        $('#gameWindow canvas').attr('width', $(window).width());
        $('#gameWindow canvas').attr('height', $(window).height());
        _ref = engine.scenes.scenes;
        _results = [];
        for (key in _ref) {
          if (!__hasProp.call(_ref, key)) continue;
          scene = _ref[key];
          scene._private.defaultSize = {
            width: $(window).width(),
            height: $(window).height()
          };
          _results.push((function() {
            var _ref1, _results1;
            _ref1 = scene.layers;
            _results1 = [];
            for (key in _ref1) {
              if (!__hasProp.call(_ref1, key)) continue;
              layer = _ref1[key];
              _results1.push(layer.size = {
                width: $(window).width(),
                height: $(window).height()
              });
            }
            return _results1;
          })());
        }
        return _results;
      });
      count = 0;
      engine.go(20);
      socket = io.connect("" + window.location.protocol + "//" + window.location.host);
      socket.on('error', function(err) {
        if (typeof world !== "undefined" && world !== null) {
          layer.removeNode(world);
          delete world;
        }
        return console.error(err);
      });
      socket.on('connect', function() {
        var joinData, world,
          _this = this;
        socket.once('protocol', function(serverVersion) {
          if (serverVersion !== Protocol.VERSION) {
            throw new TypeError("Protocol version mismatch (server: " + serverVersion + ", client: " + Protocol.VERSION + ").");
          }
        });
        joinData = {
          callsign: "random callsign " + (Math.floor(Math.random() * 101)),
          team: 'red',
          tag: 'some tag'
        };
        world = new World({
          name: 'World',
          socket: socket,
          joinData: joinData
        });
        return layer.addNode(world);
      });
      return socket.on('disconnect', function() {
        if (typeof world !== "undefined" && world !== null) {
          layer.removeNode(world);
          delete world;
        }
      });
    });
    return assetManager.addBundle(assetBundle, 'mainAssets');
  });

}).call(this);

});
require("/lib/client/Client.js");
})();
