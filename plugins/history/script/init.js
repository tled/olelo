$(function() {
    "use strict";
    $('#content').bind('pageLoaded', function pageLoaded() {
        $('#history', this).historyTable();
    });
    $('#history').historyTable();
});
