# Register some mime types

MimeMagic.add('application/x-empty', :comment => 'Empty file')
MimeMagic.add('inode/directory',     :comment => 'Directory')

MimeMagic.add('text/x-creole',
              :extensions => %w(creole text),
              :parents => 'text/plain',
              :comment => 'Creole Wiki Text File')

MimeMagic.add('text/x-mediawiki',
              :extensions => %w(mediawiki mw),
              :parents => 'text/plain',
              :comment => 'MediaWiki Text File')

MimeMagic.add('text/x-markdown',
              :extensions => %w(markdown md mdown mkdn mdown),
              :parents => 'text/plain',
              :comment => 'Markdown Text File')

MimeMagic.add('text/x-textile',
              :extensions => 'textile',
              :parents => 'text/plain',
              :comment => 'Textile Text File')

MimeMagic.add('text/x-orgmode',
              :extensions => 'org',
              :parents => 'text/plain',
              :comment => 'Emacs Orgmode File')
