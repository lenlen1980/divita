// Framer Events Analytics stub - disabled due to CloudFront restrictions in Russia
(function() {
    'use strict';
    
    // Mock Framer analytics functions to prevent errors
    window.framer = window.framer || {};
    window.framer.events = {
        track: function() {
            // Silent stub - do nothing
            console.log('[Framer Events] Analytics disabled due to regional restrictions');
        },
        identify: function() {
            // Silent stub - do nothing
        },
        page: function() {
            // Silent stub - do nothing
        }
    };
    
    // Prevent any initialization errors
    console.log('[Framer Events] Analytics service replaced with stub');
})();
