// Placeholder text for input fields
// Written by Daniel Mendler
jQuery.fn.placeholder = function() {
    this.focus(function() {
	if (this.value == this.defaultValue)
	    this.value = '';
    }).blur(function() {
	if (this.value == '')
	    this.value = this.defaultValue;
    });
};
