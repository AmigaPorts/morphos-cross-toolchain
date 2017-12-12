#!/bin/sh
#
# setup-cross-env.sh version 1.3 Copyright 2013-2015 Mark Olsen
#
# Script to automatically set up a MorphOS cross compiler environment on Linux (and other Unix-oids).
#
# History:
# 1.4 - 20160129
#  - The GNU people just can't stop breaking Makeinfo, so documentation generation for GCC is now disabled to avoid Makeinfo problems.
#  - The GNU people also just can't stop breaking GCC, so a patch to let GCC build with (a newer) GCC has also been included.
#
# 1.3 - 20150812
#  - Now works on Mac OS X
#

VERSION='20160605'
PREFIX='/opt/ppc-morphos'

wget http://www.morphos-team.net/files/sdk-$VERSION.lha
wget http://www.morphos-team.net/files/src/sdk/sdk-source-$VERSION.tar.xz

if [ "$1" = "--force" ]
then
	FORCE=y
fi

if [ ! -d $PREFIX ]
then
	echo "$PREFIX doesn't exist. Please create it and chown it to your user."
	ERROR=1
fi

if [ ! -O $PREFIX ]
then
	echo "$PREFIX isn't owned by you. Please chown it to your user."
	ERROR=1
fi

if [ ! -w $PREFIX ]
then
	echo "$PREFIX isn't writable by you. Please chmod u+w $PREFIX";
	ERROR=1;
fi

if ! echo $PATH | grep -q $PREFIX/bin
then
	echo "$PREFIX/bin isn't in your \$PATH. Please add it by typing \"export PATH=\$PATH:$PREFIX/bin\"."
	ERROR=1
fi

for i in bison bzip2 flex gcc ld lha m4 make makeinfo patch xz
do
	if [ -z "`which $i`" ]
	then
		echo "$i is missing."
		ERROR=1
	fi
done

if [ -z "$FORCE" ]
then
	if [ -d $PREFIX/include ] || [ -d $PREFIX/os-include ] || [ -d $PREFIX/includestd ] || [ -d $PREFIX/ppc-morphos ]
	then
		echo "You already have an SDK installed in $PREFIX. Either remove the old SDK manually or use --force to automatically overwrite it."
		ERROR=1
	fi
fi

if [ ! -z "$ERROR" ]
then
	exit 1
fi

SDKSOURCE="`ls sdk-source-????????.tar.xz | head -n 1`"
SDKVERSION=`echo "$SDKSOURCE" | sed "s/sdk-source-\(........\)\.tar\.xz/\1/"`
SDK="sdk-$SDKVERSION.lha"

if [ ! -f "$SDK" ] || [ ! -f "$SDKSOURCE" ]
then
	echo "Unable to find the SDK files."
	echo "Please download the SDK and the corresponding SDK source code files from"
	echo "http://www.morphos-team.net/ and place them in the current directory."

	exit 1
fi

if [ -z "$SDKVERSION" ]
then
	echo "Unable to detect SDK version."
	exit 1
fi

echo "Using SDK version: $SDKVERSION."

if [ "`uname`" = "Darwin" ]
then
	TMPDIR="`mktemp -d -t setupcrosssdk`"
else
	TMPDIR="`mktemp -d`"
fi
CURDIR="`pwd`"

if [ -z "$TMPDIR" ]
then
	echo "Unable to create temporary directory."
	exit 1
fi

trap "rm -rf \"$TMPDIR\"" exit

if [ -d $PREFIX/include ] || [ -d $PREFIX/os-include ] || [ -d $PREFIX/includestd ] || [ -d $PREFIX/ppc-morphos ]
then
	echo "Removing old SDK installation."
	rm -rf $PREFIX/include $PREFIX/os-include $PREFIX/includestd $PREFIX/ppc-morphos
fi

echo "Extracting SDK files."

# Extract files for $PREFIX
(cd "$TMPDIR" && lha -x "$CURDIR/$SDK" "morphossdk/sdk.pack" >/dev/null && xz -dcf morphossdk/sdk.pack | (cd $PREFIX && tar --transform "s,^Development/GG/,," -x "Development/GG/ppc-morphos" "Development/GG/include" "Development/GG/includestd" "Development/GG/os-include")) || exit 1

# Extract the Binutils/GCC source code.
(cd "$TMPDIR" && tar -xf "$CURDIR/$SDKSOURCE" binutils gcc4)

# Build Binutils
echo "Building binutils."
cd "$TMPDIR" && chmod -R 777 binutils
# Fortify on Ubuntu, which is enabled by default, detects phantom errors which according to Valgrind don't exist. Adding -U_FORTIFY_SOURCE to avoid this.
(cd "$TMPDIR/binutils" && CFLAGS="-m32 -O2 -U_FORTIFY_SOURCE" ./configall >"$CURDIR/setup-cross-sdk.log" 2>&1) || ERROR=1

# Are we Mac OS X? Apply some dubious patches to try to get this to build...
if [ "`uname`" = "Darwin" ]
then
	DARWINCFLAGS="-fno-builtin"

	cat <<EOF | (cd "$TMPDIR/binutils/include" && patch -p0)
--- libiberty.h.orig    2015-06-19 16:07:57.000000000 +0300
+++ libiberty.h 2015-08-12 20:56:54.000000000 +0300
@@ -108,7 +108,7 @@
 
 /* Exit, calling all the functions registered with xatexit.  */
 
-#ifndef __GNUC__
+#ifndef __NOTREALLYGNUC__
 extern void xexit PARAMS ((int status));
 #else
 typedef void libiberty_voidfn PARAMS ((int status));
EOF

	cat <<EOF | (cd "$TMPDIR/binutils/libiberty" && patch -p0)
--- strerror.c.orig     2015-06-19 16:07:59.000000000 +0300
+++ strerror.c  2015-08-12 20:59:35.000000000 +0300
@@ -466,7 +466,7 @@
 
 #else
 
-extern int sys_nerr;
+extern const int sys_nerr;
 extern char *sys_errlist[];
 
 #endif
EOF

fi

test -z "$ERROR" && (cd "$TMPDIR/binutils/build" && make CFLAGS="-m32 -O2 -U_FORTIFY_SOURCE $DARWINCFLAGS" >>"$CURDIR/setup-cross-sdk.log" 2>&1) || ERROR=1
test -z "$ERROR" && (cd "$TMPDIR/binutils/build" && make install >>"$CURDIR/setup-cross-sdk.log" 2>&1) || ERROR=1

if [ ! -z "$ERROR" ]
then
	echo "Failed to build Binutils for whatever reason. You're unfortunately on"
	echo "your own now. Check \"$CURDIR/setup-cross-sdk.log\" for details."
	exit 1
fi

# Set up required Binutils symlinks
mkdir -p $PREFIX/ppc-morphos/bin

for i in ar as ld nm objdump ranlib
do
	ln -s $PREFIX/bin/ppc-morphos-$i $PREFIX/ppc-morphos/bin/$i
done

# Build GCC 4
echo "Building GCC 4."

test -z "$ERROR" && (cd "$TMPDIR/gcc4" && make gcc4_unpack >>"$CURDIR/setup-cross-sdk.log" 2>&1) || ERROR=1

# Are we Mac OS X? Apply some dubious patches to try to get this to build...
if [ "`uname`" = "Darwin" ]
then
	test -z "$ERROR" && (cd "$TMPDIR/gcc4" && make mpfr_unpack >"$CURDIR/setup-cross-sdk.log" 2>&1) || ERROR=1

	cat <<EOF | (cd "$TMPDIR/gcc4" && patch -p0) >>"$CURDIR/setup-cross-sdk.log" 2>&1
--- Makefile.orig       2015-06-19 16:09:13.000000000 +0300
+++ Makefile    2015-08-12 21:32:17.000000000 +0300
@@ -85,7 +85,7 @@
 
 # GCC v4
 
-gcc4: gmp_install mpfr_install gcc4_unpack gcc4_patch gcc4_dir gcc4_configure gcc4_make
+gcc4: mpfr_install gcc4_unpack gcc4_patch gcc4_dir gcc4_configure gcc4_make
 
 GCC4_DIR = gcc-4.4.5
 
EOF

	cat <<EOF | (cd "$TMPDIR/gcc4/mpfr-3.0.0" && patch -p0) >>"$CURDIR/setup-cross-sdk.log" 2>&1
--- mpfr.h.orig 2010-06-10 14:00:14.000000000 +0300
+++ mpfr.h      2015-08-12 21:35:58.000000000 +0300
@@ -23,6 +23,8 @@
 #ifndef __MPFR_H
 #define __MPFR_H
 
+#define __gmp_const const
+
 /* Define MPFR version number */
 #define MPFR_VERSION_MAJOR 3
 #define MPFR_VERSION_MINOR 0
EOF

fi

	cat <<EOF | (cd "$TMPDIR/gcc4/gcc-4.4.5/gcc" && patch -p0)
--- toplev.h.orig       2009-02-20 17:20:38.000000000 +0200
+++ toplev.h    2015-08-12 21:24:42.000000000 +0300
@@ -174,7 +174,7 @@
 extern int floor_log2                  (unsigned HOST_WIDE_INT);
 
 /* Inline versions of the above for speed.  */
-#if GCC_VERSION >= 3004
+#if NOTREALLYGCC_VERSION >= 3004
 # if HOST_BITS_PER_WIDE_INT == HOST_BITS_PER_LONG
 #  define CLZ_HWI __builtin_clzl
 #  define CTZ_HWI __builtin_ctzl
EOF

test -z "$ERROR" && (cd "$TMPDIR/gcc4" && sed "s,../configure --target=ppc-morphos.*$,& MAKEINFO=missing," <Makefile >Makefile.new && mv Makefile.new Makefile) || ERROR=1

test -z "$ERROR" && (cd "$TMPDIR/gcc4" && make >>"$CURDIR/setup-cross-sdk.log" 2>&1) || ERROR=1
test -z "$ERROR" && (cd "$TMPDIR/gcc4" && make install >>"$CURDIR/setup-cross-sdk.log" 2>&1) || ERROR=1

if [ ! -z "$ERROR" ]
then
	echo "Failed to build GCC 4 for whatever reason. You're unfortunately on"
	echo "your own now. Check \"$CURDIR/setup-cross-sdk.log\" for details."
	exit 1
fi

# Set up some GCC symlinks
ln -s $PREFIX/bin/ppc-morphos-gcc-4 $PREFIX/bin/ppc-morphos-gcc
ln -s $PREFIX/bin/ppc-morphos-g++-4 $PREFIX/bin/ppc-morphos-g++

echo 'All done!'

exit 0
