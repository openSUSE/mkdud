GIT2LOG	:= $(shell if [ -x ./git2log ] ; then echo ./git2log --update ; else echo true ; fi)
GITDEPS	:= $(shell [ -d .git ] && echo .git/HEAD .git/refs/heads .git/refs/tags)
VERSION	:= $(shell $(GIT2LOG) --version VERSION ; cat VERSION)
BRANCH	:= $(shell [ -d .git ] && git branch | perl -ne 'print $$_ if s/^\*\s*//')
PREFIX	:= mkdud-$(VERSION)
BINDIR   = /usr/bin
COMPLDIR = /usr/share/bash-completion/completions

all:    archive

archive: changelog
	@if [ ! -d .git ] ; then echo no git repo ; false ; fi
	mkdir -p package
	git archive --prefix=$(PREFIX)/ $(BRANCH) > package/$(PREFIX).tar
	tar -r -f package/$(PREFIX).tar --mode=0664 --owner=root --group=root --mtime="`git show -s --format=%ci`" --transform='s:^:$(PREFIX)/:' VERSION changelog
	xz -f package/$(PREFIX).tar

changelog: $(GITDEPS)
	$(GIT2LOG) --changelog changelog

install: doc
	@cp mkdud mkdud.tmp
	@perl -pi -e 's/0\.0/$(VERSION)/ if /VERSION = /' mkdud.tmp
	install -m 755 -D mkdud.tmp $(DESTDIR)$(BINDIR)/mkdud
	install -m 644 -D bash_completion/mkdud $(DESTDIR)$(COMPLDIR)/mkdud
	@rm -f mkdud.tmp

doc:
	@if [ -x /usr/bin/asciidoctor ] ; then \
	  asciidoctor -b manpage -a version=$(VERSION) mkdud_man.adoc ;\
	else \
	  a2x -f manpage -a version=$(VERSION) mkdud_man.adoc ;\
	fi
# a2x -f docbook -a version=$(VERSION) mkdud_man.adoc
# dblatex mkdud_man.xml

clean:
	@rm -rf *~ */*~ package changelog VERSION
	@rm -f mkdud.1 mkdud_man.xml mkdud_man.pdf

