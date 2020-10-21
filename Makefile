#
# Makefile to build ZIP and README.html
#

.PHONY: html clean test check help


help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%s\033[0m\n    %s\n", $$1, $$2}'

test:   ## Run tests
	test/run.sh

shellcheck:  ## Run shellcheck.
	shellcheck -fgcc quick-change-directory dstore  qc-build-index.sh
	shellcheck -fgcc -sbash quick_change_directory.shinc
	shellcheck -fgcc -sksh quick_change_directory.shinc
	(cd test && shellcheck -sbash -fgcc *.sh *.shinc ../quick_change_directory.shinc)

check: test shellcheck ## run test & shellcheck





html: README.html           ## Build README.html

README.html: README.md
	marked --gfm --tables $< > $@

clean:                     ## Cleanup by removing README.html and zip file
	rm -rf quick_change_dir.zip README.html build

