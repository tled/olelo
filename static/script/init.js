// Olelo bootstrap
// Written by Daniel Mendler
$(function() {
    $('html').removeClass('no-js').addClass('js');
    function pageLoaded(parent) {
        $('#upload-path', parent).each(function() {
            var elem = this;
            var old = elem.value;
            var base = elem.value;
            if (base.length === 0 || base.match(/\/$/)) {
                $('#upload-file').change(function() {
                    if (elem.value == old) {
                        elem.value = base + this.value;
                        old = elem.value;
                    }
                });
            }
        });
        $('label, #menu, .tabhead, .pagination, .button-bar', parent).disableSelection();
        $('#history-table', parent).historyTable();
	$('.date', parent).timeAgo();
        $('.tabs', parent).each(function() {
	    $('> li', this).tabWidget();
	});
        $('input.placeholder', parent).placeholder();
        $('*[accesskey]', parent).underlineAccessKey();
    }

    $('.pagination a').pagination('#content');
    $('#content').bind('pageLoaded', function() { pageLoaded(this); });
    pageLoaded();

    $('button[data-target]').live('click', function() {
	var button = $(this);
	var form = $(this.form);
	button.addClass('loading');
        $.ajax({
            type: form.attr('method') || 'get',
            url:  form.attr('action') || window.location.href,
            data: form.serialize() + '&' + button.attr('name') + '=' + button.attr('value') + '&no_layout=1',
            success: function(data) {
		$('#' + button.data('target')).html(data);
		button.removeClass('loading');
            }});
	return false;
    });
});
