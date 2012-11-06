// Pagination links
// $('#page_element').pagination('.pagination a');
// $('#page_element').bind('pageLoaded', function() {});
// Written by Daniel Mendler
(function($) {
    "use strict";

    $.fn.pagination = function(links) {
	var page = this;

	function loadPage(url) {
            page.load(url + (url.indexOf('?') < 0 ? '?' : '&') + 'no_layout=1', function() {
		page.trigger('pageLoaded', [url]);
            });
	}

	$(document).on('click', links, function() {
            $(this).addClass('loading');
	    if (History.enabled) {
		History.pushState(null, document.title, this.href);
	    } else {
		loadPage(this.href);
	    }
            return false;
        });

	$(window).bind('statechange', function() {
	    var state = History.getState();
	    loadPage(state.url);
	});
    };
})(jQuery);
