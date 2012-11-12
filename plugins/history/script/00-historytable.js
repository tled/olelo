(function($) {
    "use strict";

    $.fn.historyTable = function() {
	$('thead tr', this).prepend('<th class="compare"><button>&#177;</button></th>');
	$('tbody tr', this).each(function() {
	    var version = $(this).attr('id').substr(8);
	    $(this).prepend('<td class="compare"><input type="checkbox" name="' + version + '"/></td>');
	});
	var versions = $.storage.get('historyTable');
	if (versions) {
	    for (var i = 0; i < versions.length; ++i)
		$('input[name=' + versions[i] + ']').attr('checked', 'checked');
	}

	var checkboxes = $('tbody input', this);
	function getSelectedVersions() {
	    var versions = [];
	    checkboxes.each(function() {
		if (this.checked) {
		    versions.push(this.name);
		}
	    });
	    return versions;
	}

	var button = $('th button', this);
	button.click(function() {
	    var versions = getSelectedVersions();
	    $.storage.set('historyTable', versions);
            location.href = location.pathname.replace('/history', '/compare/' + versions[versions.length-1] + '...' + versions[0]);
	});

	$('td input', this).change(function() {
	    var versions = getSelectedVersions();
	    if (versions.length > 1)
		button.removeAttr('disabled');
	    else
		button.attr('disabled', 'disabled');
	}).change();
    };
})(jQuery);
