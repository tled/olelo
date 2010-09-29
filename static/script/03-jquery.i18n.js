// Very simple i18n plugin
// Written by Daniel Mendler
(function($) {
        var locale = null, translations = {};
        $.translations = function(t) {
                for (var lang in t) {
                        if (!translations[lang]) {
                                translations[lang] = t[lang];
                        } else {
                                for (var name in t[lang])
                                        translations[lang][name] = t[lang][name];
			}
                }
        };
        function lookup(locale, name) {
                var t = translations[locale];
                return t && t[name];
        }
        $.t = function(name, args) {
                if (!locale) {
                        var html = $('html');
                        locale = html.attr('lang') || html.attr('xml:lang') || 'en';
                }
                var i, s = lookup(locale, name);
                if (!s && (i = locale.indexOf('-')))
                        s = lookup(locale.substr(0, i), name);
                if (s) {
		        for (var key in args)
                                s = s.replace(new RegExp('#{' + key + '}', 'g'), args[key]);
                        return s;
		}
		return '#' + name;
         };
})(jQuery);
