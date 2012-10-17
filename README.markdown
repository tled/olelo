README
======

Ōlelo is a wiki that stores pages in a [Git][] repository.
See the demo installation at <http://www.gitwiki.org/>.

Features
--------

A lot of the features are implemented as plugins.

- Edit, move or delete pages
- Support for hierarchical wikis (directory structure)
- Upload files
- History (also as RSS/Atom changelog)
- Access control lists
- Support for multiple text engines (Creole, Markdown, Textile, ...)
- Section editing for creole markup
- Embedded LaTeX/Graphviz graphics
- Syntax highlighting (embedded code blocks)
- Image resizing, SVG to bitmap conversion
- Auto-generated table of contents
- Templates via include-tag
- XML tag soup can be used to extend Wiki syntax
- View pages as S5 presentation

Installation
------------

First, you have to install the [Gem][] dependencies via `gem`:

    gem install creole
    gem install rugged -v 0.17.0b6 # IMPORTANT: NEWEST BETA!
    gem install mimemagic
    gem install slim
    gem install rack
    gem install unicorn

### Optional:

    gem install redcarpet
    gem install RedCloth
    gem install rubypants
    gem install evaluator
    gem install org-ruby
    gem install yajl-ruby
    gem install nokogiri

Then, run the program using the command in the application directory:

    unicorn

Point your web browser at <http://localhost:8080>.

Git-Wiki automatically creates a repository in the directory `./.wiki`.
For production purposes, I recommend that you deploy the wiki with Unicorn.
I tested other webservers like thin, rainbows, webrick and mongrel.
Git-Wiki works with all of them thanks to rack.

Configuration
-------------

You might want to deploy the wiki on a server and want to tweak some settings.
Just copy the default configuration config/config.yml.default to config/config.yml.
You can specify a different configuration file via the environment variable WIKI_CONFIG.

    export WIKI_CONFIG=/home/user/wiki_config.yml

Dependencies
------------

- [Nokogiri][]
- [Slim][]
- [Rugged][]
- [Rack][]
- [MimeMagic][]

### Optional Dependencies

- [Pygments][] for syntax highlighting
- [ImageMagick][] for image scaling and svg rendering
- [RubyPants][] to fix punctuation

### Dependencies for page rendering

At least one of these renderers should be installed:

- [creole][] for creole wikitext rendering
  (`creole` Gem from [gemcutter][])
- [RedCarpet][] for Markdown rendering
- [RedCloth][] for Textile rendering
- [org-ruby][] for org-mode rendering

[creole]:http://github.com/minad/creole
[mimemagic]:http://github.com/minad/mimemagic
[Gem]:http://rubygems.org
[Git]:http://www.git-scm.org
[rack]:http://rack.rubyforge.org/
[org-ruby]:http://orgmode.org/worg/org-tutorials/org-ruby.php
[GraphViz]:http://www.graphviz.org
[SLIM]:http://github.com/stonean/slim
[nokogiri]:http://nokogiri.org/
[LaTeX]:www.latex-project.org
[pygments]:http://pygments.org/
[RedCarpet]:http://github.com/tanoku/redcarpet
[RedCloth]:http://redcloth.org/
[ImageMagick]:http://www.imagemagick.org/
[gitrb]:http://github.com/minad/gitrb/
[gemcutter]:http://gemcutter.org/
[RubyPants]:http://chneukirchen.org/blog/static/projects/rubypants.html
