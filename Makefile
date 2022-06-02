.PHONY: all publish

all: publish

publish: publish.el
	@echo "Publishing..."
	emacs -batch -q -l publish.el
#	emacs --batch --load publish.el --funcall org-publish-all
#emacs --batch --no-init --load publish.el --funcall org-publish-all

clean:
	@echo "Cleaning up.."
	@rm -rvf *.elc
	@rm -rvf public
	@rm -rvf .org-cache
	@rm -rvf .packages

upload: publish
	@echo "Uploading..."
#rsync -e ssh -uvr public/* wose@zuendmasse.de:/home/wose/www/zuendmasse.de/
