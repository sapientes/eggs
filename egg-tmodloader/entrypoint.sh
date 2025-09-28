#!/bin/bash

set -euo pipefail

if test ! -f ~/.env ; then
    touch ~/.env
fi

source ~/.env

# Download Mods
if test -z "${TMOD_AUTODOWNLOAD}" ; then
    echo -e "[SYSTEM] No mods to download. If you wish to download mods at runtime, please set the TMOD_AUTODOWNLOAD environment variable equal to a comma separated list of Mod Workshop IDs."
    echo -e "[SYSTEM] For more information, please see the Github README."
    sleep 5s
else
    echo -e "[SYSTEM] Downloading Mods specified in the TMOD_AUTODOWNLOAD Environment Variable. This may hand a while depending on the number of mods..."
    # Convert the Comma Separated list of Mod IDs to a list of SteamCMD commands and call SteamCMD to download them all.
    steamcmd +force_install_dir ~/steamMods +login anonymous +workshop_download_item 1281930 `echo -e $TMOD_AUTODOWNLOAD | sed 's/,/ +workshop_download_item 1281930 /g'` +quit
    echo -e "[SYSTEM] Finished downloading mods."
fi

# Enable Mods
if test -z "${TMOD_ENABLEDMODS}" ; then
    echo -e "[SYSTEM] The TMOD_ENABLEDMODS environment variable is not set. Defaulting to the mods specified in ~/tModLoader/Mods/enabled.json"
    echo -e "[SYSTEM] To change which mods are enabled, set the TMOD_ENABLEDMODS environment variable to a comma seperated list of mod Workshop IDs."
    echo -e "[SYSTEM] For more information, please see the Github README."
    sleep 5s
else
  enabledpath=~/tModLoader/Mods/enabled.json
  modpath=~/steamMods/steamapps/workshop/content/1281930
  rm -f $enabledpath
  mkdir -p ~/tModLoader/Mods
  touch $enabledpath

  echo -e "[SYSTEM] Enabling Mods specified in the TMOD_ENABLEDMODS Environment variable..."
  echo '[' >> $enabledpath
  # Convert the Comma separated list of Mod IDs to an iterable list. We use this to drill through the directories and get the internal names of the mods.
  echo -e $TMOD_ENABLEDMODS | tr "," "\n" | while read LINE
  do
    echo -e "[SYSTEM] Enabling $LINE..."

    if [ $? -ne 0 ]; then
      echo -e "[!!] Mod ID $LINE not found! Has it been downloaded?"
      continue
    fi
    modname=$(ls -1 $(ls -d $modpath/$LINE/*/|tail -n 1) | sed -e 's/\.tmod$//')
    if [ $? -ne 0 ]; then
      echo -e " [!!] An error occurred while attempting to load $LINE."
      continue
    fi
    # For each mod name that we resolve, write the internal name of it to the enabled.json file.
    echo "\"$modname\"," >> $enabledpath
    echo -e "[SYSTEM] Enabled $modname ($LINE) "
  done
    echo ']' >> $enabledpath
    echo -e "\n[SYSTEM] Finished loading mods."
fi

exec /terraria-server/LaunchUtils/ScriptCaller.sh \
  -savedirectory ~/ \
  -tmlsavedirectory ~/saves \
  -modpath ~/mods \
  -steamworkshopfolder ~/steamMods/steamapps/workshop \
  "$@"
