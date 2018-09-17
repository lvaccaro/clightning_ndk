#! /bin/bash
set -e

repo=$1
commit=$2
toolchain=$3
target_host=$4
bits=$5

export PATH=/opt/$toolchain/bin:${PATH}
export AR=$target_host-ar
export AS=$target_host-clang
export CC=$target_host-clang
export CXX=$target_host-clang++
export LD=$target_host-ld
export STRIP=$target_host-strip
export LDFLAGS="-pie"
export BUILD=aarch64
export MAKE_HOST=$target_host
export HOST=$target_host
export QEMU_LD_PREFIX=/opt/${toolchain}/sysroot
export CONFIGURATOR_CC="/usr/bin/gcc"

num_jobs=4
if [ -f /proc/cpuinfo ]; then
    num_jobs=$(grep ^processor /proc/cpuinfo | wc -l)
fi

# sqlite
wget https://www.sqlite.org/2018/sqlite-autoconf-3260000.tar.gz
tar xzvf sqlite-autoconf-3260000.tar.gz
cd sqlite-autoconf-3260000
./configure --enable-static --disable-readline --disable-threadsafe --host=${target_host} CC=$CC --prefix=${QEMU_LD_PREFIX}
make -j $num_jobs
make install
cd ..
rm -rf sqlite-autoconf-3260000
rm -rf sqlite-autoconf-3260000.tar.gz

# gmp
wget https://gmplib.org/download/gmp/gmp-6.1.2.tar.bz2
tar xjvf gmp-6.1.2.tar.bz2
cd gmp-6.1.2
./configure --enable-static --disable-assembly --host=${target_host} CC=$CC --prefix=${QEMU_LD_PREFIX}
make -j $num_jobs
make install
cd ..
rm -rf gmp-6.1.2
rm -rf gmp-6.1.2.tar.bz2

# download lightning
git clone $repo lightning
cd lightning
git checkout $commit

# set virtualenv
python3 -m virtualenv venv
. venv/bin/activate
pip install -r requirements.txt

# set standard cc for the configurator
sed -i -e 's/$CC ${CWARNFLAGS-$BASE_WARNFLAGS} $CDEBUGFLAGS $COPTFLAGS -o $CONFIGURATOR $CONFIGURATOR.c/$CONFIGURATOR_CC ${CWARNFLAGS-$BASE_WARNFLAGS} $CDEBUGFLAGS $COPTFLAGS -o $CONFIGURATOR $CONFIGURATOR.c/g' configure
sed -i -e 's/-Wno-maybe-uninitialized/-Wno-uninitialized/g' configure

# run configure
./configure CONFIGURATOR_CC=/usr/bin/gcc --prefix=${QEMU_LD_PREFIX} --disable-developer --disable-compat --disable-valgrind --enable-static

# change settings
export CONFIG_VAR_FILE=config.vars
export CONFIG_HEADER=ccan/config.h

sed -i -e 's/HAVE_SYS_TERMIOS_H=1/HAVE_SYS_TERMIOS_H=0/g' $CONFIG_VAR_FILE
sed -i -e 's/HAVE_GOOD_LIBSODIUM=1/HAVE_GOOD_LIBSODIUM=0/g' $CONFIG_VAR_FILE
sed -i -e 's/HAVE_SQLITE3=0/HAVE_SQLITE3=1/g' $CONFIG_VAR_FILE
sed -i -e 's/HAVE_BACKTRACE=1/HAVE_BACKTRACE=0/g' $CONFIG_VAR_FILE
sed -i -e 's/HAVE_QSORT_R_PRIVATE_LAST=1/HAVE_QSORT_R_PRIVATE_LAST=0/g' $CONFIG_VAR_FILE

sed -i -e 's/HAVE_SYS_TERMIOS_H 1/HAVE_SYS_TERMIOS_H 0/g' $CONFIG_HEADER
sed -i -e 's/HAVE_GOOD_LIBSODIUM 1/HAVE_GOOD_LIBSODIUM 0/g' $CONFIG_HEADER
sed -i -e 's/HAVE_SQLITE3 0/HAVE_SQLITE3 1/g' $CONFIG_HEADER
sed -i -e 's/HAVE_BACKTRACE 1/HAVE_BACKTRACE 0/g' $CONFIG_HEADER
sed -i -e 's/HAVE_QSORT_R_PRIVATE_LAST 1/HAVE_QSORT_R_PRIVATE_LAST 0/g' $CONFIG_HEADER

# patch makefile
wget https://raw.githubusercontent.com/lvaccaro/clightning_ndk/master/Makefile.patch
git apply Makefile.patch

# build external libraries and source before ccan tools
make PIE=1 DEVELOPER=0 || echo "continue"

# build ccan tools for the host machine
sed -i -e 's/"ccan_compat.h"/"..\/ccan_compat.h"/g' ccan/config.h
make clean -C ccan/ccan/cdump/tools
make LDFLAGS="" CC="${CONFIGURATOR_CC}" LDLIBS="-L/usr/local/lib" -C ccan/ccan/cdump/tools

# copy the a pregenerated gen header version
wget https://raw.githubusercontent.com/lvaccaro/clightning_ndk/master/gen_header_versions.h

# complete the build process
make PIE=1 DEVELOPER=0 || echo "continue"

# rebuild tools and rerun
make LDFLAGS="" CC="${CONFIGURATOR_CC}" LDLIBS="-L/usr/local/lib" -C ccan/ccan/cdump/tools
make PIE=1 DEVELOPER=0

#exit from lightning build system
deactivate
cd ..

# pack binaries
export repo_name="${HOST}-lightning"
tar -C lightning/lightningd -czf ${repo_name}.tar.gz lightning_channeld lightning_closingd lightning_connectd lightning_gossipd lightning_hsmd lightning_onchaind lightning_openingd lightningd
