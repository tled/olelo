(function() {
    function initFancybox() {
        $('a.fancybox').each(function() {
            this.href = this.href.replace(/output=\w+/g, '');
            if (this.href.indexOf('?') < 0)
                this.href += '?';
            this.href += 'output=image&amp;geometry=800x800>';
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
})();
