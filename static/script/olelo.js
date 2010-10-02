// Olelo bootstrap
// Written by Daniel Mendler
$(function() {
    $('html').removeClass('no-js').addClass('js');
    $('#themes').styleswitcher();
    function pageLoaded(parent) {
        $('#upload-path', parent).each(function() {
            var elem = this;
            var old = elem.value;
            var base = elem.value;
            if (base.length == 0 || base.match(/\/$/)) {
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
        $('.zebra, #history-table, #tree-table', parent).zebra();
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
});
