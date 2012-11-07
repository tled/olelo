(function($) {
    "use strict";

    var markups = {
        creole: {
            link:   ['[[', 'link text', ']]'],
            bold:   ['**', 'bold text', '**'],
            italic: ['//', 'italic text', '//'],
            ul:     ['* ', 'list item', '', true],
            ol:     ['# ', 'list item', '', true],
            h1:     ['= ', 'headline', '', true],
            h2:     ['== ', 'headline', '', true],
            h3:     ['=== ', 'headline', '', true],
            sub:    ['~~', 'subscript', '~~'],
            sup:    ['^^', 'superscript', '^^'],
            del:    ['--', 'deleted text', '--'],
            ins:    ['++', 'inserted text', '++'],
            image:  ['{{', 'image', '}}'],
            preformatted: ['{{{', 'preformatted', '}}}']
        },
        markdown: {
            link: function(selected) {
                var target = prompt('link target:', selected);
                return target ? ['[', 'link text', '](' + target + ')'] : null;
            },
            bold:   ['**', 'bold text', '**'],
            italic: ['*',  'italic text', '*'],
            ul:     ['* ', 'list item', '', true],
            ol:     ['1. ', 'list item', '', true],
            h1:     ['', 'headline', '\n========', true],
            h2:     ['', 'headline', '\n--------', true],
            image: function(selected) {
                var target = prompt('image path:', selected);
                return target ? ['![', 'image alt text', '](' + target + ')'] : null;
            },
            preformatted: ['    ', 'preformatted', '', true]
        },
        orgmode: {
            bold:   ['*', 'bold text', '*'],
            italic: ['/', 'italic text', '/'],
            ul:     ['- ', 'list item', ''],
            ol:     ['1. ', 'list item', ''],
            h1:     ['* ',  'headline', ''],
            h2:     ['** ', 'headline', ''],
            h3:     ['*** ', 'headline', '']
        },
        textile: {
            link: function(selected) {
                var target = prompt('link target:', selected);
                return target ? ['"', 'link text', '":' + target] : null;
            },
            bold:   ['*', 'bold text', '*'],
            italic: ['_', 'italic text', '_'],
            ul:     ['* ', 'list item', '', true],
            ol:     ['# ', 'list item', '', true],
            h1:     ['h1. ', 'headline', '', true],
            h2:     ['h2. ', 'headline', '', true],
            h3:     ['h3. ', 'headline', '', true],
            em:     ['_', 'emphasized text', '_'],
            sub:    ['~', 'subscript', '~'],
            sup:    ['^', 'superscript', '^'],
            del:    ['-', 'deleted text', '-'],
            ins:    ['+', 'inserted text', '+'],
            image:  ['!', 'image', '!']
        }
    };

    function insertMarkup(textarea, config) {
        var selected = textarea.getSelectedText();
        if (typeof config == 'function') {
            config = config(selected);
        }
        if (!config) {
            return;
        }
        var range = textarea.getSelectionRange();
        var prefix = config[0], content = config[1], suffix = config[2], newline = config[3];
        if (newline) {
            textarea.setSelectionRange(range.start - 1, range.start);
            if (range.start !== 0 && textarea.getSelectedText() != '\n') {
                prefix = '\n' + prefix;
            }
            textarea.setSelectionRange(range.end, range.end + 1);
            if (textarea.getSelectedText() != '\n') {
                suffix += '\n';
            }
        }
        if (range.start == range.end) {
            textarea.insertText(prefix + content + suffix, range.start, range.start, false);
            textarea.setSelectionRange(range.start + prefix.length, range.start + prefix.length + content.length);
        } else {
            textarea.insertText(prefix + selected + suffix, range.start, range.end, false);
        }
    }

    $.fn.markupEditor = function(markup) {
        markup = markups[markup];
        if (markup) {
            var list = $('<ul class="button-bar" id="markup-editor"/>');

            var buttons = [];
            for (var k in markup) {
                 buttons.push(k);
            }
            buttons.sort();
            for (var i = 0; i < buttons.length; ++i) {
                list.append('<li><a href="#" id="markup-editor-' + buttons[i] + '">' + buttons[i] + '</a></li>');
            }
            this.before(list);

            var textarea = this;
            $('a', list).click(function() {
                insertMarkup(textarea, markup[this.id.substr(14)]);
                return false;
            });
        }
    };
})(jQuery);
