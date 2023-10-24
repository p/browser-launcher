## Chromium / Chrome

### Launching

https://peter.sh/experiments/chromium-command-line-switches/
https://superuser.com/questions/1343290/disable-chrome-session-restore-popup
https://stackoverflow.com/questions/68855734/how-to-setup-chrome-sandbox-on-docker-container

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

### Sessions

Files potentially relevant to sessions (all under `Default` subdir):

    Cookies
    Cookies-journal
    Preferences
    Secure Preferences
    Session Storage
    Sessions

These are a mix of sqlite3 databases and SNSS files.

Description of these files:

- https://digitalinvestigation.wordpress.com/2012/09/03/chrome-session-and-tabs-files-and-the-puzzle-of-the-pickle/

Software to read these files:

- https://github.com/lemnos/chrome-session-dump
- https://code.google.com/archive/p/ccl-ssns/
- https://github.com/phacoxcll/SNSS_Reader
- https://github.com/JRBANCEL/Chromagnon/

Additional references:

- https://softwarerecs.stackexchange.com/questions/19500/tool-to-read-data-from-google-chrome-snss-files

### Restore Session

- https://www.adlice.com/google-chrome-secure-preferences/
- https://chrome.google.com/webstore/detail/session-buddy/edacconmaakjimmfgnblocblbcdcpbko
- https://superuser.com/questions/662329/how-do-i-recover-tab-session-information-from-chrome-chromium
- https://w3guy.com/save-chrome-browsing-session/

### Secure Preferences

- https://www.cse.chalmers.se/~andrei/cans20.pdf
- https://superuser.com/questions/1661944/chrome-uses-preferences-and-secure-preferences-to-manage-extensions-whats-the
- https://www.adlice.com/google-chrome-secure-preferences/

### Session Storage

This uses LevelDB.
See [here](https://www.cclsolutionsgroup.com/post/hang-on-thats-not-sqlite-chrome-electron-and-leveldb)
for an introduction.

[Ruby implementation](https://github.com/wmorgan/leveldb-ruby).

Other resources:

- https://dfir.blog/deciphering-browser-hieroglyphics-leveldb-filesystem/

### Search Bar

- https://chrome.google.com/webstore/detail/searchbar/fjefgkhmchopegjeicnblodnidbammed?hl=en
- https://www.techjunkie.com/add-search-box-chrome/

### Other Interesting Extensions

- https://superuser.com/questions/261689/its-all-text-for-chrome

### Tweaks

- [Disable blocking of pasting](https://superuser.com/questions/919625/how-to-paste-text-into-input-fields-that-block-it)
- [Text (memo) field extension](https://chrome.google.com/webstore/detail/text-field/igigbeogifbmkfgbllimpgdaelhilgkj)

#### Ungoogled Chromium Preferences

`./chrome/browser/ungoogled_flag_entries.h`

Relevant ones:

- disable-beforeunload
- hide-crashed-bubble
- popups-to-tabs
- keep-old-history
- custom-ntp
- tab-hover-cards

### Keyboard Shortcuts

- https://superuser.com/questions/962871/how-to-exit-the-chromium-search-bar-without-using-the-mouse

## Firefox / Waterfox / Pale Moon

### Files

https://www.waterfox.net/support/WINNT/profiles-where-waterfox-stores-user-data/

### Extension Installation

Option 1: place the unpacked extension into `distribution/extensions/ID`
subdir of the browser installation directory. `ID` is the identifier of
the extension, obtained as follows:

- If the extension has a `manifest.json`, it'll be under `applications` key,
e.g.:

    "applications": {
      "gecko": {
        "id": "{66E978CD-981F-47DF-AC42-E3CF417C1467}",
        "strict_min_version": "57.0"
      }
    }

In this case, the identifier is `{66E978CD-981F-47DF-AC42-E3CF417C1467}`.

The extension will load even if `strict_min_version` implies it is
incompatible with the installed browser.

The extension will load even if it is unsigned (e.g., after `META-INF`
subdirectory is removed).

References:
[description](https://support.mozilla.org/en-US/kb/deploying-firefox-with-extensions),
[how to get extension id from manifest.json](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/manifest.json/browser_specific_settings).

Option 2: place the XPI extension package into `distribution/extensions/ID.xpi`
under the browser installation directory. `ID` is the identifier of the
extension obtained as described in the previous section.

This option works with XPI packages distributed by `addons.mozilla.org`.
Extracting the contents of an XPI file with `unzip` and repacking it with `zip`
produces an XPI file that no longer works via this option.

If the XPI package is as obtained from `addons.mozilla.org`, the extension
will load even if `strict_min_version` implies it is incompatible with
the installed browser.

References:
[description](https://support.mozilla.org/en-US/kb/deploying-firefox-with-extensions),
[how to get extension id from manifest.json](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/manifest.json/browser_specific_settings).

- http://kb.mozillazine.org/Installing_extensions
- http://kb.mozillazine.org/Determine_extension_ID
- https://www.ghacks.net/2016/08/14/override-firefox-add-on-signing-requirement/
- https://firefox-source-docs.mozilla.org/mozbase/mozprofile.html
- https://discourse.mozilla.org/t/what-is-the-easiest-way-to-install-a-local-unsigned-add-on-permanently/52005/3
- https://extensionworkshop.com/documentation/develop/temporary-installation-in-firefox/
- https://riptutorial.com/firefox-addon/example/26613/installing-a-temporary-add-on
- https://stackoverflow.com/questions/27155766/how-to-install-unpacked-extension-in-firefox-chrome
- https://www.addictivetips.com/web/how-to-install-unsigned-add-ons-in-firefox-43/
- https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/manifest.json/browser_specific_settings
- https://extensionworkshop.com/documentation/develop/getting-started-with-web-ext/

- https://wiki.mozilla.org/Add-ons/Extension_Signing
plus [here](https://addons-server.readthedocs.io/en/latest/topics/api/signing.html)
and [here](https://github.com/mozilla/sign-addon)

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

### Extensions

Meta:

- https://github.com/xiaoxiaoflood/firefox-scripts

Specific functionality:

- https://github.com/onemen/TabMixPlus
- [Disable JavaScript](https://addons.mozilla.org/en-US/firefox/addon/disable-javascript/) -
works per-site. [Source/GH](https://github.com/dpacassi/disable-javascript)

## X11

### Message Boxes

- yad
- zenity
