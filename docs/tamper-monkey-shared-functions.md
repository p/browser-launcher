# Tampermonkey Library Script Pattern

This guide shows how to create shared helper functions that can be used across multiple Tampermonkey scripts using the window object approach.

## Creating a Library Script

Create a new script in Tampermonkey with your shared helper functions:

```javascript
// ==UserScript==
// @name         Library: My Shared Helpers
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Shared utility functions
// @match        *://*/*
// @grant        none
// @run-at       document-start
// ==/UserScript==

(function() {
    'use strict';

    window.myHelpers = {
        // Add event listener for specific key press
        onKey: function(key, callback) {
            document.addEventListener('keydown', (e) => {
                if (e.key === key && !e.target.matches('input, textarea')) {
                    callback(e);
                }
            });
        },

        // Log with prefix
        log: function(message) {
            console.log('[MyHelpers]', message);
        },

        // Quick style injection
        addStyle: function(css) {
            const style = document.createElement('style');
            style.textContent = css;
            document.head.appendChild(style);
        }
    };
})();
```

**Key Requirements:**
- `@match *://*/*` - Runs on all sites (or specify specific domains)
- `@run-at document-start` - Ensures library loads before other scripts
- Attach functions to `window.myHelpers` (or any name you choose)

## Using the Library in Other Scripts

Create consumer scripts that use the shared helpers:

```javascript
// ==UserScript==
// @name         My Feature Script
// @namespace    http://tampermonkey.net/
// @version      1.0
// @match        https://example.com/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // Use the shared helpers
    window.myHelpers.onKey('r', () => {
        alert('R key pressed!');
    });

    window.myHelpers.addStyle(`
        body {
            max-width: 1024px;
            margin: 0 auto;
        }
    `);

    window.myHelpers.log('Script initialized');
})();
```

## Important Notes

- Both library and consumer scripts must have overlapping `@match` patterns
- Library script needs `@run-at document-start` to load first
- Consumer scripts can use `@run-at document-end` or default timing
- Functions are shared via the `window` object
- Scripts must run on the same page/domain to share functions

## Alternative: Violentmonkey

If you need true extension-level helper functions (like custom GM_* APIs), consider using **Violentmonkey** instead of Tampermonkey:

- **Fully open source** (MIT licensed) - you can view and modify all source code
- **Extensible architecture** - fork and add your own GM_* style functions at the extension level
- **Compatible API** - drop-in replacement for Tampermonkey scripts
- **Source available** at github.com/violentmonkey/violentmonkey

Tampermonkey is closed source, so you cannot add true GM_* functions without reverse-engineering proprietary code. The window object approach shown above is the best option for Tampermonkey users.
