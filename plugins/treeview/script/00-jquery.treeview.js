// Ajax Tree View
// Written by Daniel Mendler, 2009
(function($) {
    // Create treeview
    // $('div#id').treeView(...);
    $.fn.treeView = function(options) {
        if (!options) {
            options = {};
        }
        if (!options.root) {
            options.root = '/';
        }
        if (!options.url) {
            options.url = '/treeview.json';
        }
        if (!options.delay) {
            options.delay = 2000;
        }
        if (!options.ajax) {
            options.ajax = function(path, success, error) {
                $.ajax({url: options.url, data: { dir: path }, success: success, error: error, dataType: 'json'});
            };
        }

        // Store if node is expanded
        function setExpanded(path, expanded) {
            if (options.stateStore) {
                var state = $.storage.get(options.stateStore, []);
                if (!expanded) {
                    state = $.grep(state, function(n, i) { return n != path; });
                } else if ($.inArray(path, state) < 0) {
                    state.push(path);
                }
                $.storage.set(options.stateStore, state);
            }
        }

        // Check if node is expanded
        function isExpanded(path) {
            return options.stateStore && $.inArray(path, $.storage.get(options.stateStore, [])) >= 0;
        }

        // Create child element.
        // Data is array: [has-children, classes, path, name]
        function createChild(data) {
            var path = data[2],
                child = $('<li><div class="'+(data[0] ? 'hitarea collapsed' : 'placeholder')+
                          '"><div class="arrow"/><div class="'+data[1]+'"/></div><a href="'+path+'">'+data[3]+'</a></li>'),
                hitarea = child.children('.hitarea');
            child.data('name', data[3]);
            hitarea.click(function() {
                if (hitarea.hasClass('collapsed')) {
                    openTree(child, path);
                    hitarea.removeClass('collapsed').addClass('expanded');
                } else {
                    child.children('ul').hide();
                    hitarea.removeClass('expanded').addClass('collapsed');
                }
                setExpanded(path, hitarea.hasClass('expanded'));
                return false;
            });
            if (isExpanded(path)) {
                openTree(child, path);
                hitarea.removeClass('collapsed').addClass('expanded');
            }
            return child;
        }

        // Open tree element with path
        function openTree(element, path) {
            // Cache key for cached json data
            var cacheKey = options.cacheStore ? options.cacheStore + ':' + path : null;

            // Store json in cache
            function store(data) {
                if (cacheKey) {
                    $.storage.set(cacheKey, data);
                }
            }

            // Data loaded via ajax (callback) or from the cache
            function dataLoaded(data) {
                var ul = $('<ul/>');
                $.each(data, function(i, child) { ul.append(createChild(child)); });
                if (path == options.root) {
                    element.empty();
                }
                element.children('ul').remove();
                element.append(ul);
            }

            // Data updated via ajax (callback)
            function dataUpdated(data) {
                store(data);

                var exists = {}, list = [];
                $.each(data, function(i, child) {
                    exists[child[3]] = child;
                });
                $('> ul > li', element).each(function() {
                    var li = $(this), name = li.data('name');
                    if (!exists[name]) {
                        li.remove();
                    } else {
                        delete exists[name];
                    }
                    list.push($(this));
                });
                $.each(exists, function(name, child) {
                    var inserted = false;
                    $.each(list, function(i, other) {
                        if (name < other.data('name')) {
                            inserted = true;
                            other.before(createChild(child));
                            return false;
                        }
                    });
                    if (!inserted) {
                        element.children('ul').append(createChild(child));
                    }
                });
            }

            // Update this element with some delay
            function update() {
                setTimeout(function() {
                    options.ajax(path, dataUpdated, function() {
                        if (cacheKey) {
                            $.storage.remove(cacheKey);
                        }
                    });
                }, options.delay);
            }

            // If children exist, show them and update this element
            if (element.children('ul').length !== 0) {
                element.children('ul').show();
                update();
            } else {
                // Try to load from cache
                var data = cacheKey ? $.storage.get(cacheKey) : null;
                if (data) {
                    dataLoaded(data);
                    update();
                }
                // Load data via ajax and add busy indicator
                else {
                    element.addClass('wait');
                    options.ajax(path, function(data) {
                        element.removeClass('wait');
                        dataLoaded(data);
                        store(data);
                     }, function() {
                        element.removeClass('wait');
                     });
                }
            }
        }

        this.each(function() {
            openTree($(this), options.root);
        });
    };
})(jQuery);
