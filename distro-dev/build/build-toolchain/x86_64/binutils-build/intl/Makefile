# Makefile for directory with message catalog handling library of GNU gettext
# Copyright (C) 1995-1998, 2000-2003 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street - Fifth Floor, Boston, MA 02110-1301,
# USA.

# This Makefile has been modified from the original shipped with
# gettext 0.12.1 to remove the ability to install libintl (which
# we do not need nor want), the ability to build a shared library
# (likewise), and a large number of heinous kludges.

SHELL = /bin/sh

srcdir = /Users/samoakes/Desktop/LinuxAI/distro-dev/build/sources/binutils-2.41/intl
VPATH = $(srcdir)

prefix = /Users/samoakes/Desktop/LinuxAI/distro-dev/build/toolchain
exec_prefix = ${prefix}
transform = s&^&x86_64-linuxai-linux-gnu-&
libdir = ${exec_prefix}/lib
includedir = ${prefix}/include
datarootdir = ${prefix}/share
datadir = ${datarootdir}
localedir = $(datadir)/locale
aliaspath = $(localedir)

AR = ar
ACLOCAL = /Users/samoakes/Desktop/LinuxAI/distro-dev/build/sources/binutils-2.41/missing aclocal
AUTOCONF = /Users/samoakes/Desktop/LinuxAI/distro-dev/build/sources/binutils-2.41/missing autoconf
AUTOHEADER = /Users/samoakes/Desktop/LinuxAI/distro-dev/build/sources/binutils-2.41/missing autoheader
CC = gcc
RANLIB = ranlib 
YACC = bison -y -d
YFLAGS = --name-prefix=__gettext
CPPFLAGS = 
CFLAGS = -g -O2    
LDFLAGS =  
LIBS = 
DEFS = -DHAVE_CONFIG_H
PICFLAG = -fno-common

COMPILE = $(CC) -c $(CPPFLAGS) $(CFLAGS) $(PICFLAG) $(DEFS) $(DEFS-$@) $(INCLUDES)

HEADERS = \
  gmo.h \
  gettextP.h \
  hash-string.h \
  loadinfo.h \
  plural-config.h \
  plural-exp.h \
  eval-plural.h \
  localcharset.h \
  relocatable.h \
  libgnuintl.h
SOURCES = \
  bindtextdom.c \
  dcgettext.c \
  dgettext.c \
  gettext.c \
  finddomain.c \
  loadmsgcat.c \
  localealias.c \
  textdomain.c \
  l10nflist.c \
  explodename.c \
  dcigettext.c \
  dcngettext.c \
  dngettext.c \
  ngettext.c \
  plural.y \
  plural-exp.c \
  localcharset.c \
  relocatable.c \
  localename.c \
  log.c \
  osdep.c \
  intl-compat.c
OBJECTS = \
  bindtextdom.o \
  dcgettext.o \
  dgettext.o \
  gettext.o \
  finddomain.o \
  loadmsgcat.o \
  localealias.o \
  textdomain.o \
  l10nflist.o \
  explodename.o \
  dcigettext.o \
  dcngettext.o \
  dngettext.o \
  ngettext.o \
  plural.o \
  plural-exp.o \
  localcharset.o \
  relocatable.o \
  localename.o \
  log.o \
  osdep.o \
  intl-compat.o

DEFS-dcigettext.o = -DLOCALEDIR="\"$(localedir)\""
DEFS-localealias.o = -DLOCALE_ALIAS_PATH="\"$(aliaspath)\""
DEFS-localcharset.o = -DLIBDIR="\"$(libdir)\""
DEFS-relocatable.o = -DINSTALLDIR="\"$(libdir)\""

all: all-no
all-yes: libintl.a libintl.h config.intl
all-no: # nothing

libintl.a: $(OBJECTS)
	rm -f $@
	$(AR) cru $@ $(OBJECTS)
	$(RANLIB) $@

libintl.h: $(srcdir)/libgnuintl.h
	cp $(srcdir)/libgnuintl.h $@

.SUFFIXES:
.SUFFIXES: .c .y .o

.c.o:
	$(COMPILE) $<

.y.c:
#	echo '#define USE_BISON3' > $(patsubst %.c,%-config.h,$@)
#	sed 's,%pure_parser,,;s,^/\* BISON3 \(.*\) \*/$$,\1,' $< > $@.y
#	$(YACC) $(YFLAGS) --output $@.c $@.y
#	sed 's/\.c\.y"/.y"/' $@.c > $@
#	rm -f $@.c $@.y $@.h
	echo '/* #define USE_BISON3 */' > $(patsubst %.c,%-config.h,$@)
	$(YACC) $(YFLAGS) --output $@ $<
	rm -f $*.h

INCLUDES = -I. -I$(srcdir)

check: all

# The installation targets have been disabled.
install: install-exec install-data
install-exec: all
install-data: all
install-strip: install
installdirs:
installcheck:
uninstall:

.PHONY: info dvi ps pdf html
.PHONY: install-info install-dvi install-ps install-pdf install-html

info dvi ps pdf html:
install-info install-dvi install-ps install-pdf install-html:

$(OBJECTS): config.h libintl.h
bindtextdom.o dcgettext.o dcigettext.o dcngettext.o dgettext.o \
dngettext.o finddomain.o gettext.o intl-compat.o loadmsgcat.o \
localealias.o ngettext.o textdomain.o: gettextP.h gmo.h loadinfo.h
dcigettext.o loadmsgcat.o: hash-string.h
explodename.o l10nflist.o: loadinfo.h
dcigettext.o loadmsgcat.o plural.o plural-exp.o: plural-exp.h plural-config.h
dcigettext.o: eval-plural.h
localcharset.o: localcharset.h
localealias.o localcharset.o relocatable.o: relocatable.h

tags: TAGS
TAGS: $(HEADERS) $(SOURCES)
	here=`pwd`; cd $(srcdir) && \
		etags -o $$here/TAGS $(HEADERS) $(SOURCES)

ctags: CTAGS
CTAGS: $(HEADERS) $(SOURCES)
	here=`pwd`; cd $(srcdir) && \
		ctags -o $$here/CTAGS $(HEADERS) $(SOURCES)

id: ID
ID: $(HEADERS) $(SOURCES)
	here=`pwd`; cd $(srcdir) && \
		mkid -f$$here/ID $(HEADERS) $(SOURCES)

mostlyclean:
	rm -f *.a *.la *.o *.obj *.lo core core.* libintl.h

clean: mostlyclean

distclean: clean
	rm -f config.status config.cache config.log config.intl config.h
	rm -f Makefile ID TAGS

maintainer-clean: distclean

# The 'make dist' targets have been disabled; the GNU toolchain handles this
# with a script maintained separately from the Makefile.
dist:
distdir:

# Rules to rebuild the configuration

Makefile: $(srcdir)/Makefile.in config.status
	$(SHELL) ./config.status Makefile

config.intl: $(srcdir)/config.intl.in config.status
	$(SHELL) ./config.status config.intl

config.status: $(srcdir)/configure
	$(SHELL) ./config.status --recheck

$(srcdir)/configure: # $(srcdir)/aclocal.m4 $(srcdir)/configure.ac
	cd $(srcdir) && $(AUTOCONF)

aclocal_deps = \
	$(srcdir)/configure.ac \
	$(srcdir)/../config/codeset.m4 \
	$(srcdir)/../config/gettext.m4 \
	$(srcdir)/../config/glibc21.m4 \
	$(srcdir)/../config/iconv.m4 \
	$(srcdir)/../config/intdiv0.m4 \
	$(srcdir)/../config/inttypes-pri.m4 \
	$(srcdir)/../config/inttypes.m4 \
	$(srcdir)/../config/inttypes_h.m4 \
	$(srcdir)/../config/lcmessage.m4 \
	$(srcdir)/../config/lib-ld.m4 \
	$(srcdir)/../config/lib-link.m4 \
	$(srcdir)/../config/lib-prefix.m4 \
	$(srcdir)/../config/nls.m4 \
	$(srcdir)/../config/po.m4 \
	$(srcdir)/../config/progtest.m4 \
	$(srcdir)/../config/stdint_h.m4 \
	$(srcdir)/../config/uintmax_t.m4 \
	$(srcdir)/../config/ulonglong.m4

$(srcdir)/aclocal.m4: # $(aclocal_deps)
	cd $(srcdir) && $(ACLOCAL) -I ../config

config.h: stamp-h1
	test -f config.h || (rm -f stamp-h1 && $(MAKE) stamp-h1)

plural-config.h: plural.c

stamp-h1: $(srcdir)/config.h.in config.status
	-rm -f stamp-h1
	$(SHELL) ./config.status config.h

$(srcdir)/config.h.in: # $(srcdir)/aclocal.m4 $(srcdir)/configure.ac
	cd $(srcdir) && $(AUTOHEADER)
	-rm -f stamp-h1

# Tell versions [3.59,3.63) of GNU make not to export all variables.
# Otherwise a system limit (for SysV at least) may be exceeded.
.NOEXPORT:
