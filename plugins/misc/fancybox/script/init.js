$(function() {
    "use strict";

    function initFancybox() {
        $('a.fancybox').each(function() {
            var href = this.href.replace(/aspect=\w+/g, '');
            this.href = href + (href.indexOf('?') < 0 ? '?' : '&') + 'aspect=image&geometry=800x800>';
        });
        $('a.fancybox').fancybox({
            'transitionIn'  : 'none',
            'transitionOut' : 'none',
            'titlePosition' : 'over',
            'titleFormat'   : function(title, currentArray, currentIndex, currentOpts) {
                return '<span id="fancybox-title-over">' + (currentIndex + 1) + ' / ' + currentArray.length + ' ' + (title ? title : '') + '</span>';
        }});
    }

    $('#content').bind('pageLoaded', initFancybox);
    initFancybox();
});
