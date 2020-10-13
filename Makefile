#
# Makefile to build ZIP and README.html
#

.PHONY: html clean test check help local-install-pkg

help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%s\033[0m\n    %s\n", $$1, $$2}'

test:   ## Run tests
	test/run.sh

shellcheck:  ## run shellcheck
	shellcheck -fgcc quick-change-directory dstore  qc-build-index.sh qc-local-install.sh.template
	shellcheck -fgcc -sbash quick_change_directory.shinc
	shellcheck -fgcc -sksh quick_change_directory.shinc
	(cd test && shellcheck -sbash -fgcc *.sh *.shinc ../quick_change_directory.shinc)

check: test shellcheck ## run test & shellcheck

local-install-pkg: build/qc-local-install.sh.gz  ## Build self-extractable script for local install

build/qc-local-install.sh.gz: qc-local-install.sh.template quick_change_directory.shinc quick-change-directory qc-build-index.sh qc-index.cfg dstore
	mkdir -p build/home/.qc
	cp quick_change_directory.shinc quick-change-directory qc-build-index.sh qc-index.cfg dstore build/home/.qc
	cp qc-local-install.sh.template build/qc-local-install.sh
	(cd build/home && tar -cvf - .qc ) >> build/qc-local-install.sh
	gzip -fk9 build/qc-local-install.sh



html: README.html           ## Build README.html

README.html: README.md
	marked --gfm --tables $< > $@

clean:                     ## Cleanup by removing README.html and zip file
	rm -rf quick_change_dir.zip README.html build

