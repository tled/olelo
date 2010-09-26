(function($) {
    // Add treeview translations
    $.translations({
	en: {
	    confirmUnsaved: 'The page was not saved. Continue?',
	    pageUnsaved: 'The page was not saved.'
	},
	de: {
	    confirmUnsaved: 'Die Seite wurde nicht gespeichert. Fortsetzen?',
	    pageUnsaved: 'Die Seite wurde nicht gespeichert.'
	}
    });

    $.fn.confirmUnsaved = function() {
	return !this.unsavedChanges() || confirm($.t('confirmUnsaved'));
    };

    $.fn.unsavedChanges = function() {
	var dirty = false;
	$('input.confirm, textarea.confirm, select.confirm', this).each(function() {
	    switch (this.type) {
	    case 'checkbox':
	    case 'radio':
		dirty = this.checked != this.defaultChecked;
		break;
	    case 'hidden':
	    case 'password':
	    case 'text':
	    case 'textarea':
	    case 'file':
		dirty = this.value != this.defaultValue;
		break;
	    case 'select-one':
	    case 'select-multiple':
		for (var i = 0; i < this.options.length && !dirty; ++i)
                    dirty = this.options[i].selected != this.options[i].defaultSelected;
		break;
	    }
	    if (dirty)
		return false;
	});
	return dirty;
    };

    var submitForm = false;
    $('form').submit(function() {
	submitForm = true;
    });

    $(window).bind('beforeunload', function() {
	if (!submitForm && $(document).unsavedChanges())
	    return $.t('pageUnsaved');
    });
})(jQuery);
