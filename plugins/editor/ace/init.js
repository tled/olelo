$(function() {
    "use strict";

    var textarea = $('#edit-content');
    if (textarea.length == 1) {
	textarea.hide().before('<div id="ace-editor" style="position:relative; width:100%; height: 40em"/>');
	var editor = ace.edit('ace-editor');
	var modes = {
	    'text/x-markdown': 'markdown',
	    'text/x-textile': 'textile'
	};
	if (window.Olelo && modes[Olelo.page_mime])
	    editor.getSession().setMode('ace/mode/' + modes[Olelo.page_mime]);
	editor.getSession().setValue(textarea.val());
	$('form').submit(function() {
	    textarea.val(editor.getSession().getValue());
	});
    }
});
