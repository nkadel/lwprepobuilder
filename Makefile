#
# Makefile - build wrapper for Rt 4 on RHEL 6
#
#	git clone RHEL 6 SRPM building tools from
#	https://github.com/nkadel/lwprepo

# Base directory for yum repository
REPOBASEDIR="`/bin/pwd`"
# Base subdirectories for RPM deployment
REPOBASESUBDIRS+=$(REPOBASEDIR)/lwprepo/6/SRPMS
REPOBASESUBDIRS+=$(REPOBASEDIR)/lwprepo/6/x86_64

# These build with normal mock "epel-*" setups
EPELPKGS+=perl-Data-Dump-srpm
EPELPKGS+=perl-Encode-Locale-srpm
EPELPKGS+=perl-File-Listing-srpm
EPELPKGS+=perl-HTTP-Cookies-srpm
EPELPKGS+=perl-HTTP-Daemon-srpm
EPELPKGS+=perl-HTTP-Date-srpm
EPELPKGS+=perl-HTTP-Message-srpm
EPELPKGS+=perl-HTTP-Negotiatiate-srpm
EPELPKGS+=perl-IO-HTML-srpm
EPELPKGS+=perl-LWP-MediaTypes-srpm
EPELPKGS+=perl-Net-HTTP-srpm
EPELPKGS+=perl-WWW-RobotRules-srpm


# Require customized lwprepo local repository for dependencies
# Needed by various packages


# Binary target
LWPPKGS+=perl-libwww-perl-srpm


# Populate lwprepo with packages compatible with just EPEL
all:: epel-install

# Populate lwprepo with packages that require lwprepo
all:: lwp-install

install:: epel-install lwp-install

lwprepo-6-x86_64.cfg:: lwprepo-6-x86_64.cfg.in
	sed "s|@@@REPOBASEDIR@@@|$(REPOBASEDIR)|g" $? > $@

lwprepo-6-x86_64.cfg:: FORCE
	@cmp -s $@ /etc/mock/$@ || \
		(echo Warning: /etc/mock/$@ does not match $@, exiting; exit 1)

lwprepo.repo:: lwprepo.repo.in
	sed "s|@@@REPOBASEDIR@@@|$(REPOBASEDIR)|g" $? > $@

lwprepo.repo:: FORCE
	@cmp -s $@ /etc/yum.repos.d/$@ || \
		(echo Warning: /etc/yum.repos.d/$@ does not match $@, exiting; exit 1)

epel:: $(EPELPKGS)


$(REPOBASESUBDIRS)::
	mkdir -p $@

epel-install:: $(REPOBASESUBDIRS)

epel-install:: FORCE
	@for name in $(EPELPKGS); do \
		(cd $$name && $(MAKE) all install) || exit 1; \
	done

lwp:: $(LWPPKGS)

lwp-install:: FORCE
	@for name in $(LWPPKGS); do \
		(cd $$name && $(MAKE) all install) || exit 1; \
	done

# Dependencies

lwp:: perl-Data-Dump-srpm
lwp:: perl-Encode-Locale-srpm
lwp:: perl-File-Listing-srpm
lwp:: perl-HTTP-Cookies-srpm
lwp:: perl-HTTP-Daemon-srpm
lwp:: perl-HTTP-Date-srpm
lwp:: perl-HTTP-Message-srpm
lwp:: perl-HTTP-Negotiatiate-srpm
lwp:: perl-IO-HTML-srpm
lwp:: perl-libwww-perl-srpm
lwp:: perl-LWP-MediaTypes-srpm
lwp:: perl-Net-HTTP-srpm
lwp:: perl-WWW-RobotRules-srpm

# Git clone operations, not normally required
# Targets may change

# Build EPEL compatible softwaer in place
$(EPELPKGS):: FORCE
	(cd $@ && $(MAKE) $(MLAGS)) || exit 1

$(LWPPKGS):: lwprepo-6-x86_64.cfg

$(LWPPKGS):: FORCE
	(cd $@ && $(MAKE) $(MLAGS)) || exit 1

# Needed for local compilation, only use for dev environments
build:: lwprepo.repo

build clean realclean distclean:: FORCE
	@for name in $(EPELPKGS) $(LWPPKGS); do \
	     (cd $$name && $(MAKE) $(MFLAGS) $@); \
	done  

realclean distclean:: clean

clean::
	find . -name \*~ -exec rm -f {} \;

# Use this only to build completely from scratch
# Leave the rest of lwprepo alone.
maintainer-clean:: clean
	@echo Clearing local yum repository
	find lwprepo -type f ! -type l -exec rm -f {} \; -print

# Leave a safe repodata subdirectory
maintainer-clean:: FORCE

safe-clean:: maintainer-clean FORCE
	@echo Populate lwprepo with empty, safe repodata
	find lwprepo -noleaf -type d -name repodata | while read name; do \
		createrepo -q $$name/..; \
	done


# This is only for upstream repository publication.
# Modify for local use as needed, but do try to keep passwords and SSH
# keys out of the git repository fo this software.
RSYNCTARGET=rsync://localhost/lwprepo
RSYNCOPTS=-a -v --ignore-owner --ignore-group --ignore-existing
RSYNCSAFEOPTS=-a -v --ignore-owner --ignore-group
publish:: all
publish:: FORCE
	@echo Publishing RPMs to $(RSYNCTARGET)
	rsync $(RSYNCSAFEOPTS) --exclude=repodata $(RSYNCTARGET)/

publish:: FORCE
	@echo Publishing repodata to $(RSYNCTARGET)
	find repodata/ -type d -name repodata | while read name; do \
	     rsync $(RSYNCOPTS) $$name/ $(RSYNCTARGET)/$$name/; \
	done

FORCE::

