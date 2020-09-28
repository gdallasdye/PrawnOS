#!/bin/bash

#Converts an existing firefox install to a pseudo Tor-Browser
#Currently assumes that the user is dedicating their current install for use as a pseudo Tails distro

#First, let's clean (rm -rf) the existing mozilla folder, to minimize future data leakage
rm -rf ~/.mozilla

#Then we remove the preferences the PrawnOS installpackages introduced, so as not to interfere with the preferences we'll install later
#Use the -f switch to supress errors if they don't exist. Increases portability for non PrawnOS users too.
sudo rm -f /usr/lib/firefox-esr/defaults/pref/prawn-settings.js
sudo rm -f /usr/lib/firefox-esr/prawn.cfg

#Next, we remove then purge firefox-esr then install firefox-esr and tor
sudo apt remove -y firefox-esr
sudo apt purge -y firefox-esr
sudo apt install -y firefox tor

#Next, the user with UID 1000 is probably the only user. Let's add them to the tor group
#TODO: may not be necessary?
#TODO: test the line below
#sudo usermod -a -G tor uid=1000
#newgrp tor

#We should try installing curl, incase it's not already
sudo apt install -y curl

#We probably want to start tor before we follow the next steps
sudo systemctl enable --now tor

#Then we start to reuse Jeremy Rand's documentation.
#TODO: make a test, and make improvements. 

#(substitute the tag for whatever Tor Browser release you want to use)
curl --output 000-tor-browser-0.js http://jqs44zhtxl2uo6gk.onion/tor-browser.git/plain/browser/app/profile/000-tor-browser.js?h=tor-browser-78.3.0esr-10.0-2-build2 

grep -v "^# " 000-tor-browser-0.js | grep -v "^#expand" > 000-tor-browser-1.js

cpp -E -D XP_LINUX=1 -D MOZ_BUNDLED_FONTS=1 -o 000-tor-browser-2.js 000-tor-browser-1.js

grep -v "^# " 000-tor-browser-2.js > 000-tor-browser-3.js

sed "s/9150)/9050)/" 000-tor-browser-3.js > 000-tor-browser.js

rm 000-tor-browser-*.js

sudo mv 000-tor-browser.js /usr/share/firefox-esr/browser/defaults/preferences/

echo "You may now reboot"
