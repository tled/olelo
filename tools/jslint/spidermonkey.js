(function(a) {
    var input="";
    var line="";
    var blankcount="0";
    while (blankcount < 10){
        line=readline();

        if (line=="")
            blankcount++;
        else
            blankcount=0;
        if (line=="END") break;
        input += line;
        input += "\n";
    }
    input = input.substring(0, input.length-blankcount);

    if (!input) {
        print("No input!");
        quit(1);
    }
    if (!JSLINT(input, {
        rhino: true,
        passfail: false
    })) {
        for (var i = 0; i < JSLINT.errors.length; i += 1) {
            var e = JSLINT.errors[i];
            if (e) {
                print('Lint at line ' + (e.line + 1) + ' character ' + (e.character + 1) + ': ' + e.reason);
                print((e.evidence || '').replace(/^\s*(\S*(\s+\S+)*)\s*$/, "$1"));
                print('');
            }
        }
    } else {
        print("jslint: No problems found.");
        quit();
    }
})(arguments);
