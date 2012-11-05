// Simple, unobtrusive tab widget
// Written by Daniel Mendler
(function($) {
    $.fn.tabWidget = function(options) {
        var store = options && options.store;
	var selected = null;
	$("> a[href^='#']", this).click(function() {
            // Handle tab clicks
	    if (selected.data('tab') == $(this).data('tab')) {
		return false;
	    }
	    if (!selected.data('tab').confirmUnsaved()) {
		return false;
	    }
	    selected.data('tab').hide();
	    selected.parent().removeClass('selected');
	    selected = $(this);
	    selected.data('tab').show();
	    selected.parent().addClass('selected');
	    if (store) {
		$.storage.set(store, selected.data('tab').attr('id'));
	    }
	    return false;
	}).each(function() {
	    // Hide tabs
	    var tab = $(this.href.match(/(#.*)$/)[1]);
	    tab.hide();
	    $(this).data('tab', tab);
	});

        // Get selected tab from store
	if (store) {
	    var name = $.storage.get(store);
	    if (name) {
                selected = $("> a[href='#" + name + "']", this);
	    }
	}

        // Get selected tab by class
	if (!selected || selected.size() === 0) {
            selected = $(this).filter('.selected').find("> a[href^='#']");
	}

        // Select first tab
        if (!selected || selected.size() === 0) {
            selected = $(this).filter(':first').find("> a[href^='#']");
	}

	// Show initially selected tab
	selected.parent().addClass('selected');
	selected.data('tab').show();
    };
})(jQuery);
