// Drag & Drop for version compare
jQuery.fn.historyTable = function() {
    this.disableSelection();
    var rows = $('tbody tr', this);

    // Click on row
    rows.mousedown(function(event) {
	var from = $(this),
            offset = from.offset(),
            to = null;
	    fromText = $('td:first-child a:first-child', from).text(),
	    fromDate = $('td:nth-child(3)', from).text(),
	    draggable = null;

        // Stop dragging -> Remove draggable, unbind events
	function stop() {
	    if (draggable)
                draggable.remove();
	    $(document).unbind('mouseup.historyTable keypress.historyTable');
	    rows.unbind('mouseover.historyTable mousemove.historyTable');
	}

        // Handle mouse up while dragging -> Redirect to compare page
	$(document).bind('mouseup.historyTable', function() {
	    stop();
	    if (to) {
	        var toVersion = to.attr('id').substr(8),
                    fromVersion = from.attr('id').substr(8);
	        if (toVersion != fromVersion)
	            location.href = location.pathname.replace('/history', '/compare/' + fromVersion + '...' + toVersion);
            }
            return true;
        });

        // Handle keypress while dragging -> Stop dragging
        $(document).bind('keypress.historyTable', function(event) {
	    stop();
	    return true;
	});

        // Handle mousemove while dragging -> Create draggable and unbind this event
	rows.bind('mousemove.historyTable', function(moveEvent) {
            var distance = Math.abs(event.pageX - moveEvent.pageX) + Math.abs(event.pageY - moveEvent.pageY);
            if (distance > 5) {
                draggable = $('<div class="history-draggable">' + fromText + ' (' + fromDate + ')</div>').css({
                    width: (from.width() - 10) + 'px',
                    height: (from.height() - 4) + 'px',
                    padding: '2px 5px',
                    position: 'absolute',
                    display: 'block',
                    zIndex: 1000,
                    cursor: 'move',
                    top: Math.round(offset.top) + 'px',
                    left: Math.round(offset.left) + 'px'
		}).appendTo('body');
		rows.unbind('mousemove.historyTable');
	    }
            return true;
        });

        // Handle mouseover while dragging -> Move draggable to new target
        rows.bind('mouseover.historyTable', function() {
            if (draggable) {
                to = $(this);
		var toText = $('td:first-child a:first-child', to).text(),
		    toDate = $('td:nth-child(3)', to).text(),
		    offset = to.offset();
                draggable.css({
	            top: Math.round(offset.top) + 'px',
		    left: Math.round(offset.left) + 'px'
	        }).html(fromText + ' (' + fromDate + ') &#8594; ' + toText + ' (' + toDate + ')');
	    }
            return true;
	});

	return false;
    });
};
