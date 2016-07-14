# A search engine for the UniOrdner

This directory contains a program suite which can collect, parse and present
`bibtex` files in the UniOrdner. They just have to follow the convention
to follow a name matching `*.uni.bib`.

The programs are very simple: They make use of the super fast
[locate Unix database](https://en.wikipedia.org/wiki/Locate_(Unix)) and are
written in `bash` or `python`. We basically make use of Python only in order
to convert data to JSON.

The web frontend is simple and not powerful at all: It only displays one single
compiled bibtex or JSON file. This is *not* what you would call a search engine.
The only interactivity are parameters which invoke a rescan of the database.
The cgi scripts typically run in fractions of a second, only the rescan takes
around 2-3 seconds to complete on around 1 million of files to index.

I developed this "engine" in 2015 in order to loosely couple these informations
to my other websites.

Dependencies:

* python-bibtexparser
* bibclean
* (GNU) parallel
