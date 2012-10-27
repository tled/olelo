// Underline text in elements. Especially useful for accesskeys.
// Written by Daniel Mendler
(function($) {
    $.extend($.fn, {
	// Underline text
	underlineText: function(str) {
	    this.each(function() {
		var elem = $(this), text, i;
		if (elem.children().size() === 0) {
		    text = elem.text();
		    i = text.toLowerCase().indexOf(str.toLowerCase());
		    if (i >= 0) {
			elem.html(text.substr(0, i) + '<span style="text-decoration: underline">' +
			          text.substr(i, str.length) + '</span>' + text.substr(i+str.length));
		    }
		} else {
		    elem.children().underlineText(str);
		}
	    });
	},
	// Underline access key
	underlineAccessKey: function() {
	    this.each(function() {
		var key = $(this).attr('accesskey');
		if (key) {
		    $(this).underlineText(key);
		}
	    });
	}
    });
})(jQuery);
