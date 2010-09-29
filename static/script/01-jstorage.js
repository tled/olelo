/**
 * ----------------------------- JSTORAGE -------------------------------------
 * Simple local storage wrapper to save data on the browser side, supporting
 * all major browsers - IE6+, Firefox2+, Safari4+, Chrome4+ and Opera 10.5+
 *
 * Copyright (c) 2010 Andris Reinman, andris.reinman@gmail.com
 * Project homepage: www.jstorage.info
 *
 * Licensed under MIT-style license:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/**
 * USAGE:
 *
 * jStorage requires JSON.parse and JSON.stringify. These
 * methods are provided by the browser or by
 * http://www.json.org/json2.js.
 *
 * Methods:
 *
 * -set(key, value)
 * jStorage.set(key, value) -> saves a value
 *
 * -get(key[, default])
 * value = jStorage.get(key [, default]) ->
 *    retrieves value if key exists, or default if it doesn't
 *
 * -remove(key)
 * jStorage.remove(key) -> removes a key from the storage
 *
 * -flush()
 * jStorage.flush() -> clears the cache
 *
 * <value> can be any JSON-able value, including objects and arrays.
 *
 */

(function() {
	var
                // This is the object, that holds the cached values
		storage = {},

		// Actual browser storage (localStorage or globalStorage['domain']) */
		storageService = null,

		// DOM element for older IE versions, holds userData behavior */
                storageElement = null;

	////////////////////////// PRIVATE METHODS ////////////////////////

	/**
	 * Initialization function. Detects if the browser supports DOM Storage
	 * or userData behavior and behaves accordingly.
	 * @returns undefined
	 */
	function init() {
                try {
                        if (window.localStorage)
                                storageService = window.localStorage;
                        else if (window.globalStorage)
                                storageService = window.globalStorage[window.location.hostname];
                } catch (e) {
                        // Firefox fails when touching localStorage/globalStorage and cookies are disabled
                }

		// Check if browser supports userData behavior
                if (!storageService) {
			storageElement = document.createElement('link');
			if (storageElement.addBehavior) {

				// Use a DOM element to act as userData storage
				storageElement.style.behavior = 'url(#default#userData)';

				// userData element needs to be inserted into the DOM!
				document.getElementsByTagName('head')[0].appendChild(storageElement);

				storageElement.load('jStorage');
				var data = '{}';
				try{
					data = storageElement.getAttribute('jStorage');
				} catch (e) {
                                }
				storageService.jStorage = data;
			} else {
				storageElement = null;
				return;
			}
		}

                if (!storageService)
                        storageService = { jStorage: '{}' };

		// if jStorage string is retrieved, then decode it
		if (storageService.jStorage) {
			try {
				storage = JSON.parse(storageService.jStorage);
			} catch (e) {
                                storageService.jStorage = '{}';
                        }
		} else {
			storageService.jStorage = '{}';
		}
	}

	/**
	 * This functions provides the "save" mechanism to store the jStorage object
	 * @returns undefined
	 */
	function save() {
		try {
			storageService.jStorage = JSON.stringify(storage);
			// If userData is used as the storage engine, additional
			if (storageElement) {
				storageElement.setAttribute('jStorage',storageService.jStorage);
				storageElement.save('jStorage');
			}
		} catch (e) {
                        // probably cache is full, nothing is saved this way
                }
	}

	/**
	 * Function checks if a key is set and is string or numberic
	 */
	function checkKey(key) {
		if (typeof key != 'string' && typeof key != 'number')
			throw new TypeError('Key name must be string or numeric');
	}

	////////////////////////// PUBLIC INTERFACE /////////////////////////

	var jStorage = {
		/**
		 * Sets a key's value.
		 *
		 * @param {String} key - Key to set. If this value is not set or not
		 *				a string an exception is raised.
		 * @param value - Value to set. This can be any value that is JSON
		 *				compatible (Numbers, Strings, Objects etc.).
		 * @returns the used value
		 */
		set: function(key, value){
			checkKey(key);
			storage[key] = value;
			save();
			return value;
		},

		/**
		 * Looks up a key in cache
		 *
		 * @param {String} key - Key to look up.
		 * @param {mixed} def - Default value to return, if key didn't exist.
		 * @returns the key value, default value or <null>
		 */
		get: function(key, def){
			checkKey(key);
			if (key in storage)
				return storage[key];
			return typeof(def) == 'undefined' ? null : def;
		},

		/**
		 * Removes a key from cache.
		 *
		 * @param {String} key - Key to remove.
		 * @returns true if key existed or false if it didn't
		 */
		remove: function(key){
			checkKey(key);
			if (key in storage){
				delete storage[key];
				save();
				return true;
			}
			return false;
		},

		/**
		 * Deletes everything in cache.
		 */
		flush: function(){
			storage = {};
			save();
			/*
			 * Just to be sure - andris9/jStorage#3
			 */
			if (window.localStorage){
				try {
					localStorage.clear();
				} catch (e) {
                                }
			}
		}
	};

	// Initialize jStorage
	init();

        // Expose api
        window.jStorage = jStorage;
})();
