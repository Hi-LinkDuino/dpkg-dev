#
# You must set the $(lang) variable when you include this makefile.
#
# You can use the $(po4a_translate_options) variable to specify additional
# options to po4a.
# For example: po4a_translate_options=-L KOI8-R -A KOI8-R
#
#
# This makefile deals with the manpages generated from POs with po4a, and
# should be included in an automake Makefile.am.
#
# The man pages are generated when make enters the po4a directory.
# If a man page cannot be generated (it is not sufficiently translated; the
# threshold is 80%), it won't be distributed, and the build won't fail.
#

mandir = @mandir@/$(lang)

# List of aliases for dpkg_source.1
# If dpkg_source.1 can be generated, this aliases are also generated
dpkg_source_aliases = \
	dpkg-buildpackage.1 \
	dpkg-distaddfile.1 \
	dpkg-genchanges.1 \
	dpkg-gencontrol.1 \
	dpkg-parsechangelog.1 \
	dpkg-shlibdeps.1

# Inform automake that we want to install some man pages in section 1, 5
# and 8.
# We can't simply use:
# dist_man_MANS = $(wildcard *.[1-9])
# Because when Makefile.in is generated, dist_man_MANS is empty, and
# automake do not generate the install-man targets.
dist_man_MANS = fake-page.1 fake-page.5 fake-page.8

# Do not fail if these man pages do not exist
.PHONY: fake-page.1 fake-page.5 fake-page.8

# Override the automake's install-man target.
# And set dist_man_MANS according to the pages that could be generated
# when this target is called.
install-man: dist_man_MANS = $(wildcard *.[1-9])
install-man: install-man1 install-man5 install-man8

all-local:
# If dpkg-source.1 was generated, create the symlink
	if [ -f dpkg-source.1 ]; then \
		for man in $(dpkg_source_aliases); do \
			echo ".so man1/dpkg-source.1" > $$man; \
			chmod 644 $$man; \
		done; \
	fi

# Remove the generated aliases
clean-local:
	rm -f $(dpkg_source_aliases)

