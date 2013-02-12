description 'Syntax highlighter'
dependencies 'utils/assets'
require 'rouge'
export_code :css, ::Rouge::Themes::ThankfulEyes.render
