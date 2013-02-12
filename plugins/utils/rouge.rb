description 'Syntax highlighter'
require 'rouge'
export_code :css, ::Rouge::Themes::ThankfulEyes.render
