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

https://support.mozilla.org/en-US/kb/add-search-bar-firefox-toolbar

### Session Restore

Reference: https://support.mozilla.org/en-US/questions/1182594

To restore: `browser.sessionstore.resume_from_crash` -> `true`,
`browser.sessionstore.max_resumed_crashes` -> `10`.
To not restore: `browser.sessionstore.resume_from_crash` -> `false`.
To prompt before restoring: `browser.sessionstore.max_resumed_crashes` -> `0`.

### File Actions aka Protocol Handlers

- https://support.mozilla.org/en-US/questions/1235051
- https://support.mozilla.org/en-US/questions/1197107
- https://searchfox.org/mozilla-release/source/netwerk/mime/nsIMIMEInfo.idl
- https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/manifest.json/protocol_handlers

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

https://superuser.com/questions/1742855/how-do-i-disable-videos-in-firefox

### Multi-Process & Process Limits

- https://www.reddit.com/r/firefox/comments/j3cn2q/moz_force_disable_e10s_not_working_in_firefox_81/
- https://bugzilla.mozilla.org/show_bug.cgi?id=1653384
- https://www.ghacks.net/2016/07/22/multi-process-firefox/
- https://support.mozilla.org/en-US/questions/1264580
- https://support.mozilla.org/en-US/questions/1264552
