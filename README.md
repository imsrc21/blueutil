#Steps :
- Install brew (https://www.howtogeek.com/211541/homebrew-for-os-x-easily-installs-desktop-apps-and-terminal-utilities/)
- Run this command ```brew install blueutil```

get/set bluetooth power and discoverable state

```
Usage:
  blueutil [options]

Without options outputs current state

    -p, --power                     output power state as 1 or 0
    -p, --power 1|on|0|off          set power state
    -d, --discoverable              output discoverable state as 1 or 0
    -d, --discoverable 1|on|0|off   set discoverable state

    -h, --help                      this help
    -v, --version                   show version
```

Uses private API from IOBluetooth framework (i.e. IOBluetoothPreference*()).

Originally written by Frederik Seiffert ego@frederikseiffert.de http://www.frederikseiffert.de/blueutil/
Further development by Ivan Kuchin https://github.com/toy/blueutil
