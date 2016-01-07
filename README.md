# Bashlib #

Bashlib is a module system for bash. It contains several helpers.

An example of usage is as follow:


    SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    source "$SCRIPTDIR/bashlib/bashcore.sh"

	load_module emr
	load_module messages
	load_module functional

The documentation is contained in the modules itself.

* messages, a module for printing colored and nicely formatted messages
* functional contains various combinators
* checks contains various recognizers of types (like int, hex etc)
* bashcore creates the module system
* libtest contains a testing framework in bash
* cache let the user cache values in a concurrent safe way
* sftp has some utilities working with sftp servers
* colors contains functions for working with colors and styles in terminals
* date only has a date enumeration utility
