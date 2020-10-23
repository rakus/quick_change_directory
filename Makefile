#
# Makefile to build ZIP and README.html
#

.PHONY: test shellcheck check zip html clean

QC_VERSION = 2.0

ZIP_FILE = quick-change-directory.zip
ZIP_CONTENT = README.md LICENSE INSTALL quick_change_directory.shinc quick-change-directory qc-build-index.sh qc-index.cfg dstore

help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%s\033[0m\n    %s\n", $$1, $$2}'

test:   ## Run tests.
	test/run.sh

shellcheck:  ## Run shellcheck.
	shellcheck -fgcc quick-change-directory dstore  qc-build-index.sh
	shellcheck -fgcc -sbash quick_change_directory.shinc
	shellcheck -fgcc -sksh quick_change_directory.shinc
	(cd test && shellcheck -sbash -fgcc *.sh *.shinc ../quick_change_directory.shinc)

check: test shellcheck ## Run tests and shellcheck.

zip: ${ZIP_FILE}   ## Create zip file including INSTALL script-

${ZIP_FILE}: ${ZIP_CONTENT}
	mkdir -p build/quick-change-dir
	cp $^ build/quick-change-dir
	(cd build && zip -r ../$@ quick-change-dir)
	rm -rf build

html: README.html          ## Build README.html

README.html: README.md
	marked --gfm --tables $< > $@

clean:                     ## Cleanup by removing README.html and zip file
	rm -rf ${ZIP_FILE} README.html build/

