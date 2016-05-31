"use strict";

// module DOMUtils

exports.ready = function(func) {
    return function() {
        // `document.readyState` can possess one of the following event types:
        // 1. "loading" indicates that the document is loading.
        // 2. "interactive" indicates that the document has finished loading
        //    but sub-resources haven't been loaded completely.
        // 3. "complete" indicates that the document as well as the
        //    sub-resources have finished loading.
        // See also:
        // https://developer.mozilla.org/en-US/docs/Web/API/Document/readyState
        var documentHasFinishedLoading = document.readyState === 'complete';

        if (documentHasFinishedLoading) {
            return func();
        }

        // Register an event handler which runs the callback function.
        if (document.addEventListener) {
            document.addEventListener('DOMContentLoaded', func, false);
        } else {
            // The function `addEventListener` is only supported starting with
            // IE 9. Use the old IE event system here.
           document.attachEvent('onreadystatechange', func);
        }
    };
};
