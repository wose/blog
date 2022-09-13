(require 'package)
(setq package-user-dir (expand-file-name "./.packages"))
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(package-install 'htmlize)
(package-install 'rust-mode)

(require 'org)
(require 'ox-publish)
(load-file "./elisp/ox-rss.el")
(require 'ox-rss)
(require 'htmlize)


(setq make-backup-files nil
      auto-save-default nil)

(setq org-export-with-section-numbers nil
      org-export-with-smart-quotes t
      org-export-with-sub-superscripts '{}
      org-export-with-toc nil
;;      org-publish-cache nil
      org-publish-use-timestamps-flag t
;;      org-publish-use-timestamps-flag nil
      org-publish-timestamp-directory "./.org-cache/")

(defvar blog-images
  (regexp-opt '("jpg" "jpeg" "gif" "png" "svg" "ico"))
  "File types that are published as image files.")

(defvar zm/preamble "<h1><a href=\"/\">zuendmasse</a></h1>
    <p>adventures of a random geek</p>
    <ul>
      <li><a href=\"/\">Blog</a></li>
      <li><a href=\"/pages/about.html\">About</a></li>
      <li><a href=\"https://github.com/wose\">GitHub</a></li>
      <li><a href=\"/rss.xml\">RSS</a></li>
    </ul>")

(defvar zm/postamble "<span title=\"post date\" class=\"post-info\">published: %d</span>
        <span title=\"last modification date\" class=\"post-info\">updated: %C</span>
        <span title=\"author\" class=\"post-info\">%a</span>
        <span title=\"licence\" class=\"post-info\"><a href=\"https://creativecommons.org/publicdomain/zero/1.0/\">CC-0</a>")

(setq org-html-container-element "section"
      org-html-checkbox-type 'html
      org-html-html5-fancy nil
      org-html-validation-link nil
      org-html-doctype "html5"
      org-html-htmlize-output-type 'css
      org-src-fontify-natively t)

(setq org-html-html5-fancy nil
      org-html-validation-link nil
      org-html-head-include-scripts nil
      org-html-head-include-default-style nil
      org-html-head "<link rel=\"icon\" type=\"image/x-icon\" href=\"/images/favicon.ico\"/>
                     <link rel=\"stylesheet\" href=\"/css/main.css\" /><link rel=\"stylesheet\" href=\"/css/htmlize.css\" />")

(defun zm/generate-posts-sitemap(title list)
  (concat
   "#+TITLE: " title "\n"
   "#+DATE: " (org-format-time-string "<%F %a %R>")
   "\n\n"
   (org-list-to-org list)))

(defun zm/sitemap-format-entry (entry style project)
  (format "%s » [[file:%s][%s]]"
          (format-time-string "%Y-%m-%d" (org-publish-find-date entry project))
          entry
          (org-publish-find-title entry project)))

(defun zm/org-rss-publish-to-rss (plist filename pub-dir)
  "Publish RSS with PLIST, only when FILENAME is 'rss.org'.
PUB-DIR is when the output will be placed."
  (if (equal "rss.org" (file-name-nondirectory filename))
      (org-rss-publish-to-rss plist filename pub-dir)))

(defun zm/format-rss-feed-entry (entry style project)
  "Format ENTRY for the RSS feed.
ENTRY is a file name.  STYLE is either 'list' or 'tree'.
PROJECT is the current project."
  (cond ((not (directory-name-p entry))
         (let* ((base-directory (plist-get (cdr project) :base-directory))
                (filename (expand-file-name entry base-directory))
                (title (org-publish-find-title entry project))
                (date (format-time-string "%Y-%m-%d" (org-publish-find-date entry project)))
                (link (concat (file-name-sans-extension entry) ".html")))
           (with-temp-buffer
             (insert (concat "* " title "\n"))
             (org-set-property "RSS_PERMALINK" link)
             (org-set-property "PUBDATE" date)
             (insert-file-contents filename)
             (buffer-string))))
        ((eq style 'tree)
         ;; Return only last subdir.
         (file-name-nondirectory (directory-file-name entry)))
        (t entry)))

(defun zm/format-rss-feed (title list)
  "Generate RSS feed, as a string.
TITLE is the title of the RSS feed.
LIST is an internal representation for the files to include, as returned by `org-list-to-lisp'.
PROJECT is the current project."
  (concat "#+TITLE: " title "\n\n"
          (org-list-to-generic list '(:istart ""))))


(defun zm/org-html-format-headline-function (todo todo-type priority text tags info)
  "Format a headline with a link to itself. This function takes six arguments:
TODO      the todo keyword (string or nil).
TODO-TYPE the type of todo (symbol: ‘todo’, ‘done’, nil)
PRIORITY  the priority of the headline (integer or nil)
TEXT      the main headline text (string).
TAGS      the tags (string or nil).
INFO      the export options (plist)."
  (let* ((headline (get-text-property 0 :parent text))
         (id (or (org-element-property :CUSTOM_ID headline)
                 (org-export-get-reference headline info)
                 (org-element-property :ID headline)))
         (link (if id
                   (format "<a href=\"#%s\">%s</a>" id text)
                 text)))
    (org-html-format-headline-default-function todo todo-type priority link tags info)))

(setq org-publish-project-alist
      `(("posts"
         :author "wose"
         :auto-sitemap t
         :base-directory "posts/"
         :base-extension "org"
         :email "wose@zuendmasse.de"
         :exclude ,(regexp-opt '("draft" "index.org" "rss.org"))
         :html-format-headline-function zm/org-html-format-headline-function
         :html-postamble ,zm/postamble
         :html-preamble ,zm/preamble
         :htmlized-source t
         :publishing-function org-html-publish-to-html
         :publishing-directory "public/"
         :recursive t
         :sitemap-title ""
         :sitemap-filename "index.org"
         :sitemap-function zm/generate-posts-sitemap
         :sitemap-style list
         :sitemap-sort-files anti-chronologically
         :sitemap-date-format "%Y-%m-%d"
         :sitemap-format-entry zm/sitemap-format-entry
         :with-creator t)
        ("pages"
         :base-directory "pages/"
         :base-extension "org"
         :html-preamble ,zm/preamble
         :html-postamble ,zm/postamble
         :publishing-function org-html-publish-to-html
         :publishing-directory "./public/pages"
         :recursive t)
        ("css"
         :base-directory "css/"
         :base-extension "css"
         :publishing-directory "public/css"
         :publishing-function org-publish-attachment
         :recursive t)
        ("images"
         :base-directory "images/"
         :base-extension ,blog-images
         :publishing-directory "public/images"
         :publishing-function org-publish-attachment
         :recursive t)
        ("rss"
         :author "wose"
         :auto-sitemap t
         :base-directory "posts/"
         :base-extension "org"
         :creator "wose"
         :email "wose@zuendmasse.de"
         :exclude ,(regexp-opt '("draft" "index.org" "rss.org" "about.org" "rss.org"))
         :html-link-home "https://zuendmasse.de/"
         :html-link-org-files-as-html t
         :html-link-use-abs-url t
         :publishing-directory "./public"
         :publishing-function zm/org-rss-publish-to-rss
         :recurse nil
         :rss-extension "xml"
         :rss-image-url ""
         :rss-link-home "https://zuendmasse.de/"
         :section-number nil
         :sitemap-filename "rss.org"
         :sitemap-title "zuendmasse.de"
         :sitemap-style list
         :sitemap-sort-files anti-chronologically
         :sitemap-function zm/format-rss-feed
         :sitemap-format-entry zm/format-rss-feed-entry
         :table-of-contents nil
         :title "zuendmasse"
         :description "Adventures of a random geek"
         :with-author t
         :with-broken-links t
         :with-date t
         :with-description t
         :with-toc nil
         )
        ("zm" :components ("posts" "css" "images" "pages"))))

(org-mode)
(org-publish-all t)
