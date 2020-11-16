#!/bin/sh
set -e

FRR_URL=https://github.com/FRRouting/frr.git
FRR_VERSION=frr-7.5

PCRE_VERSION=8.44
PCRE_URL="https://ftp.pcre.org/pub/pcre/pcre-$PCRE_VERSION.tar.bz2"

LIBYANG_URL=https://github.com/CESNET/libyang.git

apk update
apk add git curl build-base libtool autoconf automake \
        json-c-dev python2 python2-dev pkgconf readline-dev \
        cmake bison flex libcap-dev bsd-compat-headers

mkdir -p /tmp/build/
mkdir -p /tmp/build/fatyang

echo "Cloning frr"
cd /tmp/build
git clone --depth 1 --branch "$FRR_VERSION" "$FRR_URL" frr

echo "Building pcre"
cd /tmp/build
curl "$PCRE_URL" > pcre.tar.bz2
tar xvf pcre.tar.bz2
cd pcre-"$PCRE_VERSION"/
./configure \
	--enable-static \
	--disable-shared \
	--enable-utf8 \
	--enable-jit \
	--enable-unicode-properties \
	--with-pic
make
make install
cp .libs/*.a /tmp/build/fatyang/

cd /tmp/build
git clone --depth 1 "$LIBYANG_URL"
cd libyang
mkdir build
cd build
cmake \
	-DCMAKE_INSTALL_PREFIX:PATH=/usr \
	-DENABLE_STATIC=ON \
	-DENABLE_LYD_PRIV=ON \
	-DCMAKE_POSITION_INDEPENDENT_CODE=TRUE \
	-DCMAKE_BUILD_TYPE:String="Release" ..
make
make install
cp ./*.a /tmp/build/fatyang

cd /tmp/build/fatyang/
ar -M <<EOM
  CREATE libyang_fat.a
  ADDLIB libyang.a
  ADDLIB libyangdata.a
  ADDLIB libmetadata.a
  ADDLIB libnacm.a
  ADDLIB libuser_inet_types.a
  ADDLIB libuser_yang_types.a
  ADDLIB libpcre.a
  SAVE
  END
EOM
ranlib libyang_fat.a
cp /tmp/build/fatyang/libyang_fat.a /usr/lib64/libyang.a

mkdir /tmp/build/frr-archive
cd /tmp/build/frr
./bootstrap.sh
PKG_CONFIG_PATH=/usr/lib64/pkgconfig/ \
./configure \
	--enable-static \
	--enable-static-bin \
	--enable-shared \
	--prefix=/tmp/build/frr-archive \
	--enable-user=root \
    --enable-group=root \
    --enable-vty-group=root \
	--enable-vtysh \
	--disable-doc \
	--disable-ripd \
	--disable-ripngd \
	--disable-ospfd \
	--disable-ospf6d \
	--disable-ldpd \
	--disable-nhrpd \
	--disable-eigrpd \
	--disable-babeld \
	--disable-watchfrr \
	--disable-isisd \
	--disable-pimd \
	--disable-pbrd \
	--disable-staticd \
	--disable-fabricd \
	--disable-vrrpd \
	--disable-ospfapi \
	--disable-ospfclient \
	--enable-cumulus
make
make install
cd /tmp/build/frr-archive
tar czf /tmp/frr.tar.gz .
