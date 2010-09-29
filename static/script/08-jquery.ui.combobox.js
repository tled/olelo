(function($) {
    $.widget('ui.combobox', {
	_create: function() {
	    var input = this.element;
            input.autocomplete({
		delay: 0,
		minLength: 0,
		source: this.options.source
	    });
	    $('<button>&#9662;</button>')
		.attr('tabIndex', -1)
		.insertAfter(input)
		.click(function(event) {
		    event.preventDefault();
		    // close if already visible
		    if (input.autocomplete('widget').is(':visible')) {
			input.autocomplete('close');
			return;
		    }
		    // pass empty string as value to search for, displaying all results
		    input.autocomplete('search', '');
		    input.focus();
		});
	}
    });
})(jQuery);
