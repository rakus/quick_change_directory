#
# Makefile to build ZIP and README.html
#

ZIP_CONTENT = README.md INSTALL.sh _quick_change_dir qc-build-index.sh qc-index-proc.sh qc-index.list

.PHONY: zip html clean test

test:
	test/run.sh

zip: quick_change_dir.zip

html: README.html

quick_change_dir.zip: $(ZIP_CONTENT)
	zip $@ $^


README.html: README.md
	marked --gfm --tables $< > $@

clean:
	rm -f quick_change_dir.zip README.html
