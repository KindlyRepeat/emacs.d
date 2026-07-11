;; (straight-use-package 'org)
					; Make sure to use the `org' from straight to avoid mismatch

(use-package ob-clojure
  :disabled t
  :config
  (setq org-babel-clojure-backend 'cider))

(use-package ob-core
  :config
  (setq org-confirm-babel-evaluate nil))

(use-package oc
  :config
  (setq org-cite-global-bibliography (list "~/nc/zotero/library.bib")))

(use-package org
  :bind
  (:map org-mode-map
	(("C-c M-e" . org-edit-headline)
	 ("C-c C-p" . nol/org-previous-heading-at-top)
	 ("C-c C-n" . nol/org-next-heading-at-top)))
  :init
  (defun insert-tilde (&optional arg)
    "Enclose following ARG sexps or region in tildes (~).

If region is active, insert enclosing tildes around region boundaries.
If ARG is non-nil, enclose following ARG sexps (negative ARG for preceding).
No argument inserts a pair of tildes and leaves point between them."
    (interactive "P")
    (insert-pair arg ?~ ?~))
  :config

  (defun nol/org-previous-heading-at-top ()
    "Jump to the previous visible Org heading and recenter it at the top."
    (interactive)
    (org-previous-visible-heading 1)
    (recenter-top-bottom 0))

    (defun nol/org-next-heading-at-top ()
      "Jump to the next visible Org heading and recenter it at the top."
      (interactive)
      (org-next-visible-heading 1)
      (recenter-top-bottom 0))

  (with-eval-after-load 'markdown
    (defun od/markdown-link-p (text)
      (or (string-match-p markdown-regex-link-inline text)
	  (string-match-p markdown-regex-link-reference text)))

    (defun od/convert-md-link-to-org (link)
      (let* ((regex "\\[\\(.*\\)\\](\\([^\\)]*\\))")
	     (_ (string-match regex link))
	     (desc (match-string 1 link))
	     (url (match-string 2 link)))
	(concat "[[" url "][" desc "]]")))

    (defun od/yank-md-link-as-org ()
      (interactive)
      (let ((to-be-yanked (substring-no-properties (current-kill 0 t))))
	(if (od/markdown-link-p to-be-yanked)
	    (insert (od/convert-md-link-to-org to-be-yanked))
	  (org-yank))))

    (bind-key "C-y" #'od/yank-md-link-as-org org-mode-map))

  (defun od/get-all-links-from-buffer ()
    (interactive)
    (let ((links (org-element-map (org-element-parse-buffer) 'link
                   (lambda (link)
                     (let* ((type (org-element-property :type link))
                            (path (org-element-property :path link))
                            (full-link (concat type ":" path)))
                       full-link)))))
      (completing-read "Select a link: " links)))

  ;; (require 'org-habit)
  ;; (add-to-list 'org-modules 'org-habit)

  (setq org-agenda-files '("~/Nextcloud/org/")
	org-archive-location "::* Archive"
	org-deadline-warning-days 7
	org-directory "~/Nextcloud/org"
	org-ellipsis "  ▾"
	org-hide-emphasis-markers t
	org-insert-heading-respect-content t
	org-log-into-drawer "LOGBOOK"
	org-M-RET-may-split-line nil
	org-pretty-entities t
	;; Inserting a citation in an org-mode buffer, such as [cite:@judge23:_before_after_foo] causes a part of it
	;; to be interpreted as subscript, which I find annoying.
	org-pretty-entities-include-sub-superscripts nil
	org-src-fontify-natively t
	org-startup-indented t
	org-startup-with-inline-images nil
	org-startup-with-latex-preview t
	org-tags-alist '(("area")
			 ("bifl")	; Buy It For Life
			 ("data")	; data visualization
			 ("emacs")
			 ("finance")
			 ("family")
			 ("food")
			 ("giro")
			 ("hardware")
			 ("health")
			 ("history")	; genealogy as well
			 ("hmi")	; human-machine interface
			 ("home")
			 ("infosec")
			 ("language")
			 ("machinelearning")
			 ("montreal")
			 ("music")
			 ("network")
			 ("neuro")
			 ("philosophy")
			 ("pim")	; personal informatino management
			 ("privacy")
			 ("project")
			 ("programming")
			 ("society")
			 ("scifi")
			 ("selfhosting")
			 ("software"))
	;; Items marked as DONE, READ and CANCELLED won't be considered as todo by the function
	;; (org-element-property)
	org-todo-keywords '((sequence "TODO(t)" "STARTED(s)" "|" "DONE(d)")
			    (sequence "README(r)" "READING(e)" "|" "READ(R)")
			    (type "FIXME(f)" "NEXT(n)" "TODAY(T)" "WAITING(w)" "|" "CANCELLED(c)" "SOMEDAY(S)"))
	org-todo-keyword-faces '(("STARTED" . "orange")
				 ("READING" . "orange")
				 ("CANCELLED" . "grey")
				 ("SOMEDAY" . "grey")
				 ("WAITING" . org-latex-and-related)
				 ("FIXME" . org-imminent-deadline))
	org-use-fast-todo-selection 'expert)

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((clojure . t)
     (org .t)
     (plantuml . t)
     (python . t)
     (scheme . t)
     (shell . t)
     (sqlite .t))))

(use-package org-agenda
  :bind
  (("C-c a" . org-agenda)
   ("C-c i" . od/org-capture))
  :config
  (setq org-agenda-block-separator nil
	org-agenda-hide-tags-regexp nil
	org-agenda-include-diary t
	org-agenda-restore-windows-after-quit t
	org-agenda-span 14
        org-agenda-start-on-weekday nil
	org-agenda-sticky nil
        ;;org-archive-location "/home/nic/org/archive/archive.org::* From %s"
	org-agenda-window-setup 'current-window
	org-agenda-format-date (lambda (date) (concat "\n" (org-agenda-format-date-aligned date))))

  (setq org-capture-templates
        `(("i" "inbox" entry (file ,(concat org-directory "/inbox.org"))
             ,(concat "* TODO %?\n" "/Entered on/ %U"))
            ("p" "Protocol" entry
             (file ,(concat org-directory "/inbox.org"))
             "* TODO Source: [[%:link][%:description]]\n #+BEGIN_QUOTE\n%i\n#+END_QUOTE\n/Captured on/ %U" :immediate-finish t)
            ("L" "Protocol Link" entry
             (file ,(concat org-directory "/inbox.org"))
             "* TODO [[%:link][%:description]]\n/Captured on/ %U" :immediate-finish t)))

  (defun od/org-capture (arg)
    "Org capture to the inbox. If called with a prefix, do an org-capture depending on the major-mode"
    (interactive "P")
    (if arg
	(cond ((and (eq major-mode 'exwm-mode) exwm-class-name)
	       (exwm-input--fake-key od/firefox-org-capture-shortcut))
	      ((or (eq major-mode 'mu4e-headers-mode)
		   (eq major-mode 'mu4e-view-mode))
	       (org-capture nil "@")))
      (org-capture nil "i")))

  (defun od/count-todos-in-inbox (inbox)
    "Return the number of todos in the list of inbox files `inbox'. Used in `org-custom-agenda-view'."
    (interactive)
    (let ((total 0))
      (dolist (file inbox)
	(when (f-file-p file)
	  (let* ((buf (get-file-buffer file))
		 (tree (with-current-buffer buf
			 (cddr (org-element-parse-buffer))))
		 (todos (org-element-map tree 'headline
			  (lambda (headline)
			    (string= (symbol-name (org-element-property :todo-type headline)) "todo")))))
	    (setq total (+ total (length todos))))))
      total))

  (setq org-agenda-custom-commands
	'(("i" "Inbox" alltodo ""
	   ((org-agenda-files '("~/org/inbox.org" "~/Sync/Moto/inbox-mobile.org" "~/Sync/Moto/Inbox.org"))))
	  ("g" "GIRO"
	   ((org-agenda-files '("~/org/projects/giro/giro.org"))
	    (agenda ""
		    ((org-agenda-files '("~/org/projects/giro/giro.org"))
		     (org-agenda-span 7)
		     (org-deadline-warning-days 10)))
	    (todo "NEXT"
		  ((org-agenda-files '("~/org/projects/giro/giro.org"))
		   (org-agenda-overriding-header "\nNext\n")))
	    (todo "TODO"
		  ((org-agenda-files '("~/org/projects/giro/giro.org"))
		   (org-agenda-overriding-header "\nTODO items\n")))))
	  ("1" "Today"
	   ((agenda ""
		    ((org-agenda-span 3)
		     (org-deadline-warning-days 14)))))
	  ("2" "Tomorrow"
	   ((agenda ""
		    ((org-agenda-span 2)
		    ;; ((org-agenda-start-day "+1d")
		    ;;  (org-agenda-span 'day)
		    ;;  (org-agenda-start-on-weekday nil)
		    ;;  (calendar-week-start-day 1)
		     ;;(org-agenda-start-day "-1d")
		     ))))
	  ("3" "This week"
	   ((agenda ""
		    ((org-agenda-span 7)
		     (calendar-week-start-day 0)))))
	  ;; ("g" "GIRO"
	  ;;  ((org-agenda-files '("~/org/projects/giro/giro.org"))
	  ;;   (agenda ""
		    ;; ((org-agenda-span 7))))
             ;; ((agenda ""
             ;;          ((org-agenda-span 7)
             ;;           (org-deadline-warning-days 10)))
	     ;;  (todo "TODO"
             ;;        ((org-agenda-overriding-header "\nTasks\n")
             ;;         (org-agenda-skip-function '(org-agenda-skip-entry-if
             ;;                                     'regexp "\\(?:composte\\|Entrainement\\|recyclage\\)"
             ;;                                     'timestamp))
             ;;         (org-agenda-files (list (concat org-directory "/agenda.org")))))
             ;;  (todo "TEST"
             ;;        ((org-agenda-overriding-header
	     ;; 	      (format "\nItems in inbox: [%d]\n" (od/count-todos-in-inbox
	     ;; 						  '("~/org/inbox.org"
	     ;; 						    "~/Sync/Moto/Inbox.org"
	     ;; 						    "~/Sync/Moto/inbox-mobile.org"))))
	     ;; 	     (org-agenda-skip-function '(org-agenda-skip-entry-if 'regexp ".*")))))
	  ("t" "test"
	   ((agenda ""
		    ((org-agenda-span 7)
		     (org-deadline-warning-days 10)))
	    (todo "TODAY" ((org-agenda-overriding-header "\nToday\n")
			   (org-agenda-files (list (concat org-directory "/agenda.org")
						   (concat org-directory "/projects/projects.org")))))
	    (todo "NEXT" ((org-agenda-overriding-header "\nProjects\n")
			  (org-agenda-files (list (concat org-directory "/projects/projects.org")))))
	    (tags-todo "task" ((org-agenda-overriding-header "\nOther tasks\n")
			       (org-agenda-skip-function '(org-agenda-skip-entry-if
							   'todo '("WAITING" "TODAY")))
			       (org-agenda-files (list (concat org-directory "/agenda.org")))))
	    (todo "WAITING" ((org-agenda-overriding-header "\nWaiting\n")
			      (org-agenda-files (list (concat org-directory "/agenda.org")
						      (concat org-directory "/projects/projects.org")))))
	    (todo "NONE"
                    ((org-agenda-overriding-header
		      (format "\nItems in inbox: [%d]\n" (od/count-todos-in-inbox
							  '("~/org/inbox.org"
							    "~/Sync/Moto/Inbox.org"
							    "~/Sync/Moto/inbox-mobile.org"))))
		     (org-agenda-skip-function '(org-agenda-skip-entry-if 'regexp ".*"))))
	    ))))
  )

(use-package org-appear
  :hook ((org-mode . org-appear-mode)))

(use-package org-archive
  :after org
  :config
  (setq org-archive-mark-done t
	org-archive-subtree-add-inherited-tags nil))

(use-package org-attach
  :after org
  :config
  (setq org-attach-id-dir (concat org-directory "/data")))

;; TODO: what is this ?
(use-package org-compat
  :config
  (setq org-imenu-depth 5))

(use-package org-faces
  :config
  (set-face-attribute 'org-document-title nil :font "Iosevka Aile"
		      :weight 'light
		      :height 1.8
		      :underline t)
  (setq org-fontify-quote-and-verse-blocks t))

(use-package org-habit
  :after org-agenda
  :custom
  (org-habit-preceding days 10)
  (org-habit following-days 4))

(use-package org-id			; builtin
  :after org
  :init
  (defun nol/org-id-get-create ()
    (interactive)
    (org-id-get-create)
    (org-id-copy))
  :custom
  (org-id-track-globally t)
  (org-id-locations-file "~/.config/emacs/.org-id-locations"))

(use-package org-inlinetask
  :after org
  :config
  (setq org-inlinetask-default-state "TODO"))

(use-package org-journal
  :disabled t
  :config
  (setq org-journal-dir "~/Nextcloud/org/journal"
	org-journal-file-type 'yearly
	org-journal-hide-entries-p nil))

(use-package org-indent
  :init
  (add-to-list 'mode-line-collapse-minor-modes 'org-indent-mode))

(use-package org-keys
  :config
  (setq org-return-follows-link t
	org-use-speed-commands t))

(use-package org-list
  :config
  (setq org-list-demote-modify-bullet
	'(("+" . "-")
	  ("-" . "*"))
	org-list-indent-offset 4))

(use-package org-protocol
  :disabled t
  :config
  (require 'org-protocol))

(use-package org-refile
  :config
  (setq org-outline-path-complete-in-steps nil
	org-refile-use-outline-path t))

(use-package org-src
  :config
  (setq org-src-window-setup 'current-window))

(use-package org-modern
  :after org
  :hook
  (org-mode . org-modern-mode)
  (org-agenda-finalize . org-modern-agenda))

;; I get warning about `org-file-name-concat', which is in the library `org-compat'
(use-package ox
  :defer t
  :custom
  (org-export-with-sub-superscripts nil))

(use-package ox-icalendar
  :after ox
  :config
  (setq org-icalendar-alarm-time 30
	org-icalendar-include-todo t
	org-icalendar-timezone "America/New_York"
	org-icalendar-use-deadline '(todo-due event-if-todo event-if-not-todo)
	org-icalendar-use-scheduled '(todo-start event-if-todo event-if-not-todo)))

(provide 'init-org)
