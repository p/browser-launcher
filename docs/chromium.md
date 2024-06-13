## Chromium / Chrome

### Launching

https://peter.sh/experiments/chromium-command-line-switches/
https://superuser.com/questions/1343290/disable-chrome-session-restore-popup
https://stackoverflow.com/questions/68855734/how-to-setup-chrome-sandbox-on-docker-container
https://chromium.googlesource.com/chromium/src/+/main/docs/process_model_and_site_isolation.md

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

### Diagnostics

See extensios/background page logs:
https://stackoverflow.com/questions/3829150/google-chrome-extension-console-log-from-background-page

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

[Tampermonkey](https://chromewebstore.google.com/detail/dhdgffkkebhmkfjojejmpbldmpobfkfo)

[Memory model / site isolation / multi-processes](https://chromium.googlesource.com/chromium/src/+/main/docs/process_model_and_site_isolation.md)

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
