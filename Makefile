#
# Makefile to build ZIP and README.html
#

.PHONY: test shellcheck check zip html clean

QC_VERSION = 2.0

ZIP_FILE = quick-change-directory.zip
ZIP_CONTENT = README.md LICENSE INSTALL quick_change_directory.sh qc-backend qc-build-index qc-index.cfg dstore

help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%s\033[0m\n    %s\n", $$1, $$2}'

test:   ## Run tests.
	test/run.sh all

shellcheck:  ## Run shellcheck.
	shellcheck -e SC1107 -fgcc qc-backend dstore  qc-build-index
	shellcheck -e SC1107 -fgcc -sbash quick_change_directory.sh
	shellcheck -e SC1107 -fgcc -sksh quick_change_directory.sh
	(cd test && shellcheck -e SC1107 -sbash -fgcc *.sh *.shinc ../quick_change_directory.sh)

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

