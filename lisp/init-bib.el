;; -*- lexical-binding: t; -*-

(use-package bibtex
  :custom
  (bibtex-set-dialect 'biblatex)
  (bibtex-user-optional-fields
     '(("keywords" "Keywords to describe the entry" "")))
  :config
  ;; Add the @audio non-standard entry type, using the fields from the @misc entry type.
  ;; See https://mirror.its.dal.ca/ctan/macros/latex/contrib/biblatex/doc/biblatex.pdf
  (setq od/bibtex-audio-entry-type (append '("Audio" "Audio")
					   (seq-subseq
					    (seq-find
					     (lambda (elt) (equal (car elt) "Misc"))
					     bibtex-biblatex-entry-alist)
					    2))
	od/bibtex-movie-entry-type (append '("Movie" "Movie")
					   (seq-subseq
					    (seq-find
					     (lambda (elt) (equal (car elt) "Misc"))
					     bibtex-biblatex-entry-alist)
					    2))
	od/bibtex-video-entry-type (append '("Video" "Video")
					   (seq-subseq
					    (seq-find
					     (lambda (elt) (equal (car elt) "Misc"))
					     bibtex-biblatex-entry-alist)
					    2)))
  (add-to-list 'bibtex-biblatex-entry-alist od/bibtex-audio-entry-type)
  (add-to-list 'bibtex-biblatex-entry-alist od/bibtex-movie-entry-type)
  (add-to-list 'bibtex-biblatex-entry-alist od/bibtex-video-entry-type))

(use-package ebib
  :after citar 				; TODO : This is wrong, I don't need to require citar before loading this package, I only need to load citar if `od/ebib-popup-note' is called.
  :commands (ebib)
  ;; Those two hooks are only useful if using reading list state icons.
  :hook ((ebib-reading-list-new-item . ebib--update-index-buffer)
	 (ebib-reading-list-remove-item . ebib--update-index-buffer))
  :bind (:map ebib-entry-mode-map
	      ("C-x b" . nil)
	      ("C-x k" . nil)
	      :map ebib-index-mode-map
	      ("C-x b" . nil)
	      ("<return>" . ebib-edit-entry)
	      ("g" . od/ebib-update-index-buffer)
	      ("N" . od/ebib-popup-note))
  :config
  (setq ebib-bibtex-dialect 'biblatex
	ebib-index-columns '(("Reading" 1 t)
			     ("Title" 80 t)
			     ("Author/Editor" 35 t)
			     ("=type=" 10 t)
			     ;; ("Year" 6 t)
			     ;; ("Entry Key" 32 t)
			     )
	ebib-index-window-size 15
	ebib-preload-bib-files `(,od/bibliography-path)
	ebib-reading-list-file (concat od/nextcloud-directory
				       "/notes/20240222T221039--ebib-reading-list.org"))

  ;; TODO : This can be improved. Prompting for the state with the same menu than `org-todo' would be nice.
  ;; Also how does org define the ordering of states (like a state machine ?). Here it is : https://orgmode.org/manual/Workflow-states.html
  ;; Maybe set it as a file-local variable ?
  (defun ebib-reading-list-change-item-state (new-state)
    "Change the state of reading list item at point to NEW-STATE."
    (let ((key (ebib--get-key-at-point)))
      (with-current-buffer (ebib--reading-list-buffer)
	(let ((loc (ebib--reading-list-locate-item key)))
          (if loc
              (progn
		(goto-char loc)
		(org-todo new-state)
		(save-buffer))
            (error "No reading list item found with key: %s" key))))))

  (defun ebib-mark-reading-list-item-as-started ()
    (interactive)
    (ebib-reading-list-change-item-state "STARTED"))

  (defun od/ebib-update-index-buffer ()
    "Update the index buffer."
    (interactive)
    (ebib--update-index-buffer)
    (beginning-of-buffer))

  (defun od/ebib-popup-note (key)
    (interactive (list (ebib--get-key-at-point)))
    (citar-open-notes `(,key)))

  (defun ebib-reading-list-get-org-state (key)
    "Return the org state for KEY. Can be TODO, DONE, `nil', ..."
    (save-current-buffer
      (set-buffer (ebib--reading-list-buffer))
      (save-excursion
	(when-let ((loc (ebib--reading-list-locate-item key)))
	  (progn
	    (goto-char loc)
	    (org-get-todo-state))))))

  (setq ebib-blank-icon (propertize (nerd-icons-mdicon "nf-md-select") 'invisible t))
  (setq ebib-todo-icon (nerd-icons-mdicon "nf-md-checkbox_blank_outline"))
  (setq ebib-done-icon (nerd-icons-mdicon "nf-md-checkbox_outline"))
  (setq ebib-started-icon (nerd-icons-mdicon "nf-md-checkbox_intermediate"))
  ;; (setq ebib-reading-list-markers-list
  ;; 	`((:marker nil :icon ,ebib-blank-icon :sort-index 4)
  ;; 	  (:marker "TODO" :icon "[ ]" :sort-index 1)
  ;; 	  (:marker "STARTED" :icon "[.]" :sort-index 0)
  ;; 	  (:marker "DONE" :icon "[x]" :sort-index 2)))
  ;; (setq ebib-marker-icons-alist `(("TODO" . "[ ]")
  ;; 				  ("DONE" . "[x]")
  ;; 				  ("STARTED" . "[.]")
  ;; 				  (nil    . ",ebib-blank-icon")))

  (setq ebib-reading-list-markers-list
	`((:org-state nil :icon ,ebib-blank-icon :sort-index 4)
	  (:org-state "TODO" :icon ,ebib-todo-icon :sort-index 1)
	  (:org-state "STARTED" :icon ,ebib-started-icon :sort-index 0)
	  (:org-state "DONE" :icon ,ebib-done-icon :sort-index 2)))

  ;; (setq ebib-marker-icons-alist '(("TODO" . "[ ]")
  ;; 				  ("DONE" . "[x]")
  ;; 				  ("STARTED" . "[.]")
  ;; 				  (nil    . "   ")))

  (defun ebib-display-reading-marker (field key db)
    "Return the icon of KEY according to its org state as defined by `ebib-reading-list-markers-list'."
    (let ((org-state (ebib-reading-list-get-org-state key)))
      (plist-get
       (list-of-plist-get ebib-reading-list-markers-list :org-state org-state)
       :icon)))

  (setq ebib-field-transformation-functions
	'(("Reading" . ebib-display-reading-marker)
	  ("Title" . ebib-clean-TeX-markup-from-entry)
	  ("Doi" . ebib-display-www-link)
	  ("Url" . ebib-display-www-link)
	  ("Note" . ebib-notes-display-note-symbol)))

  (defun ebib-get-sort-index-from-icon (icon)
    ""
    (let ((matched-plist (seq-find
			  `(lambda (plist) (string= (plist-get plist :icon) ,icon))
			  ebib-reading-list-markers-list)))
      (plist-get matched-plist :sort-index)))

  ;; The sorting is done according to the field as displayed by ebib-display-reading-marker.
  (defun ebib-compare-reading-state (state-a state-b)
    "Compare using the sort-index prop of ebib-reading-list-markers-list"
    (let ((index-a (or (ebib-get-sort-index-from-icon state-a) 0))
	  (index-b (or (ebib-get-sort-index-from-icon state-b) 0)))
      (< index-a index-b)))

(add-to-list 'ebib-field-sort-functions-alist '("Reading" . ebib-compare-reading-state)))

(use-package zotra
  :disabled t
  :config
  (setq zotra-backend 'translation-server
	zotra-default-bibliography od/bibliography-path
	zotra-default-entry-format "biblatex"))

(provide 'init-bib)
