## Chromium / Chrome

### Launching

https://peter.sh/experiments/chromium-command-line-switches/
https://superuser.com/questions/1343290/disable-chrome-session-restore-popup

### Policies

https://dennisspan.com/deploying-google-chrome-extensions-using-group-policy/
https://www.chromium.org/administrators/linux-quick-start
http://dev.chromium.org/administrators/policy-list-3#ExtensionInstallForcelist
https://cloud.google.com/docs/chrome-enterprise/policies/

### Install Extensions

https://github.com/mdamien/chrome-extensions-archive/issues/8
https://stackoverflow.com/questions/16800696/how-install-crx-chrome-extension-via-command-line
https://developer.chrome.com/webstore/inline_installation

### Preferences

https://support.google.com/chrome/a/answer/187948?visit_id=637393417480115480-3521742&rd=1


## Firefox / Waterfox / Pale Moon

### Files

https://www.waterfox.net/support/WINNT/profiles-where-waterfox-stores-user-data/

### Extension Installation

- http://kb.mozillazine.org/Installing_extensions
- http://kb.mozillazine.org/Determine_extension_ID
- https://www.ghacks.net/2016/08/14/override-firefox-add-on-signing-requirement/
- https://firefox-source-docs.mozilla.org/mozbase/mozprofile.html

### Policies

https://support.mozilla.org/en-US/kb/customizing-firefox-using-policiesjson
https://github.com/mozilla/policy-templates/blob/master/README.md

### User Scripts

https://stackoverflow.com/questions/24542151/how-to-edit-tampermonkey-scripts-outside-of-the-browser
https://stackoverflow.com/questions/53589149/is-it-possible-to-load-a-userscript-from-the-local-filesystem
https://stackoverflow.com/questions/11850460/where-are-chrome-tampermonkey-userscripts-stored-on-the-filesystem
https://gist.github.com/derjanb/9f6c10168e63c3dc3cf0
https://stackoverflow.com/questions/49509874/how-to-update-tampermonkey-script-to-a-local-file-programmatically

https://violentmonkey.github.io/guide/creating-a-userscript/

### User Chrome / UI customization

https://www.howtogeek.com/334716/how-to-customize-firefoxs-user-interface-with-userchrome.css/
https://github.com/MrOtherGuy/firefox-csshacks (also for user content css)
https://github.com/Aris-t2/CustomCSSforFx
https://www.userchrome.org/what-is-userchrome-css.html
https://www-archive.mozilla.org/unix/customizing.html

### Session Restore

Reference: https://support.mozilla.org/en-US/questions/1182594

To restore: `browser.sessionstore.resume_from_crash` -> `true`,
`browser.sessionstore.max_resumed_crashes` -> `10`.
To not restore: `browser.sessionstore.resume_from_crash` -> `false`.
To prompt before restoring: `browser.sessionstore.max_resumed_crashes` -> `0`.

### Privacy

Decentraleyes - common js rerouter extension

Facebook containers/multi-container extension - interesting


## X11

### Message Boxes

- yad
- zenity
