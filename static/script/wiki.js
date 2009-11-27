(function($) {
    $.extend($.fn, {
	// Tabs
	tabs: function() {
	    links = $('ul:first > li > a', this);
	    links.each(function() {
		hash = this.href.match(/(#.*)$/);
		this.tab = $(hash[1]);
		this.tabLinks = links;
		if ($(this).parent('li.tabs-selected').length == 0)
		    this.tab.hide();
	    });
	    links.click(function() {
		this.tabLinks.each(function() { this.tab.hide(); });
		this.tabLinks.parent('li').removeClass('tabs-selected');
		this.tab.show();
		$(this).parent('li').addClass('tabs-selected');
		return false;
	    });
	},
	// Underline access key
	underlineAccessKey: function() {
	    this.each(function() {
		key = $(this).attr('accesskey');
		if (key) {
		    text = $(this).text();
		    i = text.toLowerCase().indexOf(key.toLowerCase());
		    if (i >= 0)
			$(this).html(text.substr(0, i) + '<span style="text-decoration: underline">' + text.substr(i, 1) + '</span>' + text.substr(i+1));
		}
	    });
	},
	// Date toggler
	dateToggler: function() {
	    function timeDistance(to, from) {
		n = Math.floor((to  - from) / 60000)
		if (n == 0) return 'less than a minute';
		if (n == 1) return 'a minute';
		if (n < 45) return n + ' minutes';
		if (n < 90) return ' about 1 hour';
		if (n < 1440) return 'about ' + Math.round(n / 60) + ' hours';
		if (n < 2880) return '1 day';
		if (n < 43200) return Math.round(n / 1440) + ' days';
		if (n < 86400) return 'about 1 month';
		if (n < 525960) return Math.round(n / 43200) + ' months';
		if (n < 1051920) return 'about 1 year';
		return 'over ' + Math.round(n / 525960) + ' years';
	    }

	    function timeAgo(from) {
		return timeDistance(new Date().getTime(), new Date(from * 1000)) + ' ago';
	    }

	    function toggleDate() {
		elem = $(this);
		match = elem.attr('class').match(/seconds_(\d+)/);
		elem.children('.ago').text(timeAgo(match[1]));
		elem.children('.full, .ago').toggle();
	    }

	    this.each(function() {
		elem = $(this);
		elem.html('<span class="full">' + elem.text() + '</span><span class="ago"></span>')
		elem.children('.ago').hide();
		toggleDate.apply(this);
		elem.click(toggleDate);
	    });
	}
    });
})(jQuery);

$(document).ready(function(){
    $('.tabs').tabs();

    $('table.sortable').tablesorter({widgets: ['zebra']});
    $('table.history').tablesorter({
        widgets: ['zebra'],
        headers: {
            0: { sorter: false },
            1: { sorter: false },
            2: { sorter: 'text' },
	    3: { sorter: 'text' },
	    4: { sorter: 'text' }, // FIXME: Write parser for date
	    5: { sorter: 'text' },
            6: { sorter: false }
        }
    });

    $('table.history').disableSelection();
    $('table.history td *').css({ cursor: 'move' });
    $('table.history tbody tr').draggable({
	helper: function() {
	    table = $('<table class="history-draggable"><tbody>' + $(this).html() + '</tbody></table>');
	    a = $.makeArray(table.find('td'));
	    b = $.makeArray($(this).find('td'));
	    for (i = 0; i < a.length; ++i)
		$(a[i]).css({ width: $(b[i]).width() + 'px' });
	    return table;
	}
    }).droppable({
	hoverClass: 'history-droppable-hover',
	drop: function(event, ui) {
	    to = this.id;
	    from = ui.draggable.attr('id');
	    if (to != from)
		location.href = '/diff?from=' + from + '&to=' + to;
	}
    });

    $('.zebra tr:even').addClass('even');
    $('.zebra tr:odd').addClass('odd');

    $('input.clear').focus(function() {
	if (this.value == this.defaultValue)
	    this.value = '';
    }).blur(function() {
	if (this.value == '')
	    this.value = this.defaultValue;
    });

    $('.date').dateToggler();
    $('label, #menu, .tabs > ul').disableSelection();
    $('#upload-file').change(function() {
	elem = $('#upload-path');
	if (elem.size() == 1) {
	    val = elem.val();
	    if (val == '') {
		elem.val(this.value);
	    } else if (val.match(/^(.*\/)?new page$/)) {
		val = val.replace(/new page$/, '') + this.value;
		elem.val(val);
	    }
	}
    });

    $('*[accesskey]').underlineAccessKey();
});