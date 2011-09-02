GIT2LOG := $(shell if [ -x ./git2log ] ; then echo ./git2log --update ; else echo true ; fi)
GITDEPS := $(shell [ -d .git ] && echo .git/HEAD .git/refs/heads .git/refs/tags)

all:    changelog

changelog: $(GITDEPS)
	$(GIT2LOG) --changelog changelog

clean:
	@rm -f *~

