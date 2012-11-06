// Simple storage plugin
// Written by Daniel Mendler
(function($) {
    "use strict";

    var storage = {}, data = {};
    try {
	if (window.localStorage) {
            storage = window.localStorage;
	}
	if (storage.oleloStorage) {
	    data = JSON.parse(storage.oleloStorage);
	}
    } catch (e) {
        // Firefox fails when touching localStorage/globalStorage and cookies are disabled
    }

    function checkKey(key) {
	if (typeof(key) != 'string' && typeof(key) != 'number') {
	    throw new TypeError('Key name must be string or numeric');
	}
    }

    function save() {
	try {
	    storage.oleloStorage = JSON.stringify(data);
	} catch (e) {
            // probably cache is full, nothing is saved this way
        }
    }

    $.storage = {
	set: function(key, value){
	    checkKey(key);
	    data[key] = value;
	    save();
	    return value;
	},
	get: function(key, def){
	    checkKey(key);
	    if (key in data) {
		return data[key];
	    }
	    return typeof(def) == 'undefined' ? null : def;
	},
	remove: function(key){
	    checkKey(key);
	    if (key in data){
		delete data[key];
		save();
		return true;
	    }
	    return false;
	}
    };
})(jQuery);
