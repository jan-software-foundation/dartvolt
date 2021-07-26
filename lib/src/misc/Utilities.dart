part of dartvolt;

/// Some utility functions that might be useful
class UtilityFunctions {
    /// Generates a git-like diff from two strings.
    /// Can be used to visualize message or channel description edits. \
    /// (Might fail to display all scenarios properly)
    String diffFromStrings(String oldString, String newString) {
        var output = '';
        var arrOld = oldString.split('\n');
        var arrNew = newString.split('\n');
        var iOld = 0;
        var iNew = 0;
        
        try {
            var whileTrueFailsafe = 0;
            
            while(
                iOld < arrOld.length &&
                iNew < arrNew.length &&
                whileTrueFailsafe < 10000
            ) {
                whileTrueFailsafe++;
                if (whileTrueFailsafe > 10000) {
                    throw 'Too many iterations';
                }
                
                void inc() {
                    if (arrOld.length > iOld) iOld++;
                    if (arrNew.length > iNew) iNew++;
                }
                
                int? nextSameOld, nextSameNew;
                
                if (arrOld[iOld] != arrNew[iNew]) {
                    for (var i = iOld; i < arrOld.length; i++) {
                        for (var j = iNew; j < arrNew.length; j++) {
                            if (nextSameOld == null && nextSameNew == null) {
                                if (arrOld[i] == arrNew[j]) {
                                    nextSameOld = i;
                                    nextSameNew = j;
                                }
                            }
                        }
                    }
                    
                    nextSameOld ??= arrOld.length;
                    nextSameNew ??= arrNew.length;
                    for (var i = iOld; i < nextSameOld; i++) {
                        output += '- ${arrOld[i]}\n';
                    }
                    for (var i = iNew; i < nextSameNew; i++) {
                        output += '+ ${arrNew[i]}\n';
                    }
                    iOld = nextSameOld;
                    iNew = nextSameNew;
                } else {
                    inc();
                }
            }
        } catch(e) {
            output = output.trim() + '\nError: $e';
        }
        
        return output.trim();
    }
}
