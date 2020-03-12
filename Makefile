#
# Makefile to build ZIP and README.html
#

ZIP_CONTENT = README.md INSTALL _quick_change_dir qc-build-index.sh qc-index.list

.PHONY: zip html clean test check help

help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%s\033[0m\n    %s\n", $$1, $$2}'

test:   ## Run tests
	test/run.sh

check:  ## run shellcheck
	shellcheck -sbash -fgcc _quick_change_dir *.sh
	(cd test && shellcheck -sbash -fgcc *.sh *.shinc ../_quick_change_dir)

zip: quick_change_dir.zip   ## Build zip file

html: README.html           ## Build README.html

quick_change_dir.zip: $(ZIP_CONTENT)
	zip $@ $^


README.html: README.md
	marked --gfm --tables $< > $@

clean:                     ## Cleanup by removing README.html and zip file
	rm -f quick_change_dir.zip README.html

