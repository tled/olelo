Slim::Engine.set_default_options format: :xhtml,
                                 shortcut: {'&' => {:tag=>'input', :attr=>'type'}, '#' => {:attr=>'id'}, '.' => {:attr=>'class'}}
