$(function() {
    "use strict";

    var mime = Olelo.page_mime;
    if (mime == 'application/x-empty' || mime == 'inode/directory') {
	mime = Olelo.default_mime;
    }
    var match = /text\/x-(\w+)/.exec(mime);
    if (match) {
	$('#edit-content').markupEditor(match[1]);
    }
});
