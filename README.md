# clightning_ndk

Android cross-compilation of [c-lightning](https://github.com/ElementsProject/lightning) for Android >= 24 Api.

### Build
```bash
bash build_deps.sh
export REPO=https://github.com/ElementsProject/lightning.git
export COMMIT=v0.7.2
export TOOLCHAIN=aarch64-linux-android-clang
export TARGETHOST=aarch64-linux-android
export BITS=64
bash fetchbuild.sh $REPO $COMMIT $TOOLCHAIN $TARGETHOST $BITS
```

### Get bitcoin-cli
Build sources of bitcoin_ndk enabling bitcoin tools [apply diff commit](https://github.com/lvaccaro/bitcoin_ndk/commit/35b63e11ed6efc9d9dbc787759fd0e8b0b8311f4) for the same platform.


### Push to the device
```bash
adb push lightningd/lightningd /data/local/tmp/
adb push lightningd/lightning_closingd /data/local/tmp/
adb push lightningd/lightning_connectd /data/local/tmp/
adb push lightningd/lightning_gossipd /data/local/tmp/
adb push lightningd/lightning_hsmd /data/local/tmp/
adb push lightningd/lightning_onchaind /data/local/tmp/
adb push lightningd/lightning_openingd /data/local/tmp/
adb push bitcoin-cli /data/local/tmp/
```

### Run on the device
```bash
adb shell
cd /data/local/tmp
chmod +x *
./lightningd --lightning-dir=/sdcard/tmp/ --testnet --bitcoin-rpcconnect=*** --bitcoin-rpcuser=*** --bitcoin-rpcpassword=*** --bitcoin-rpcport=18332 --bitcoin-cli=/data/local/tmp/bitcoin-cli --bitcoin-datadir=/sdcard/tmp/ --log-level=debug
```

### Dependencies
* sqlite lib [sqlite-autoreconf-3260000](https://www.sqlite.org/2018/sqlite-autoconf-3260000.tar.gz)
* gmp lib [gmp-6.1.2](https://gmplib.org/download/gmp/gmp-6.1.2.tar.bz2)
* android ndk [android-ndk-r20](https://dl.google.com/android/repository/android-ndk-r20-linux-x86_64.zip)


### References
* [INSTALL.md](https://github.com/ElementsProject/lightning/blob/master/doc/INSTALL.md#to-cross-compile-for-android)  of clightning to cross-compile c-lightning for Android
* [bitcoin_ndk](https://github.com/greenaddress/bitcoin_ndk/): ndk build of bitcoin core, knots and liquid
* [abcore](https://github.com/greenaddress/abcore/): ABCore - Android Bitcoin Core
