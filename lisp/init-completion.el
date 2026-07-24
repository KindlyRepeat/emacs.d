;; -*- lexical-binding: t; -*-

(use-package consult
  :demand t
  :bind
  (("C-x b" . consult-buffer)
   ("s-b" . consult-buffer)
   ("M-y" . consult-yank-from-kill-ring)
   ("M-s l" . consult-line)
   ("M-s g" . od/consult-ripgrep-or-grep)
   ("M-s f" . od/consult-find)
   ([remap imenu] . consult-imenu)
   ([remap goto-line] . consult-goto-line)
   ("C-h i" . consult-info)
   ("C-h w" . consult-man)
   ("C-c c f" . od/dotfiles-find-file)
   ("C-c c g" . od/config-consult-grep)
   ;("C-x p b" . consult-project-buffer)	; orig. project-switch-to-buffer
   ;([remap project-find-regexp] . consult-git-grep) ; We also need to change `project-switch-commands'
   :map comint-mode-map 		; for shell-mode and others
   ("M-r" . consult-history)
   :map minibuffer-local-map
   ("M-r" . consult-history))
  :config
  (setq consult-async-min-input 2
	consult-narrow-key "<"
	consult-preview-key 'any)	; This is great when using `completion-at-point'

  (setq default-consult-ripgrep-args consult-ripgrep-args
	consult-ripgrep-args (concat default-consult-ripgrep-args " --hidden"))

  ;; When calling `consult-git-grep' from `project-switch-project', the value of
  ;; `this-command' is not preserved, which cause `vertico-multiform' to misbehave.
  ;; Not sure if this deserves a bug report. It also doesn't work when called with
  ;; `(call-inveratively `consult-git-grep'.
  (defun consult-git-grep (&optional dir initial)
    "Search with `git grep' for files in DIR with INITIAL input.
See `consult-grep' for details."
    (interactive "P")
    (let ((this-command 'consult-git-grep))
      (consult--grep "Git-grep" #'consult--git-grep-make-builder dir initial)))

  (defun consult-ripgrep (&optional dir initial)
    "Search with `rg' for files in DIR with INITIAL input.
See `consult-grep' for details."
    (interactive "P")
    (let ((this-command 'consult-ripgrep))
      (consult--grep "Ripgrep" #'consult--ripgrep-make-builder dir initial)))

  ;; TODO: this must move
  (add-to-list 'consult-mode-histories '(cider-repl-mode . cider-repl-input-history))

  (add-to-list 'display-buffer-alist
	       '("\\*Embark Collect:.*"
		 (display-buffer-in-side-window)
		 (side . left)
		 (window-height . 35)
		 (dedicated . t)
		 (slot . 1)
		 (preserve-size . (t . t))))

  ;; Use Orderless as pattern compiler for consult-grep/ripgrep/find
  ;; How to make it work for consult-man ?
  (defun consult--orderless-regexp-compiler (input type &rest _config)
    (setq input (orderless-pattern-compiler input))
    (cons
     (mapcar (lambda (r) (consult--convert-regexp r type)) input)
     (lambda (str) (orderless--highlight input str))))

  ;; I remember it worked at first, but it doesn't anymore
  ;; (setq consult--regexp-compiler #'consult--orderless-regexp-compiler)

  ;; (consult-customize	;; THIS FUCKS UP WITH EMACS 29-28 compat (key-valid-p warning)
  ;;  consult-buffer			; I don't want preview for `consult-buffer'
  ;;  :preview-key (kbd "M-."))
  ;; consult-grep				; No initial input for `consult-grep' (use orderless)
  ;; :initial nil
  ;; consult-find				; No initial input for `consult-find' (use orderless)
  ;; :initial nil)

  (defun od/config-consult-grep ()
    "Grep in all my config files. Doesn't look in `init.el' as its not in the `/lisp' directory"
    (interactive)
    (consult-grep (concat od/emacs-directory "/lisp")))

  (defun od/dotfiles-find-file ()
    (interactive)
    (let ((default-directory "~/dotfiles"))
      (project-find-file)))

  (defun od/consult-ripgrep-or-grep ()
    "Call `consult-ripgrep' or `consult-grep' depending on their availability."
    (interactive)
    (let ((this-command
	   (if (not (string-empty-p (shell-command-to-string "which rg")))
	       'consult-ripgrep
	     'consult-grep)))
      (funcall-interactively this-command '(4))))

  (defun od/consult-find ()
    "Function for `consult-find' with the `universal-argument'."
    (interactive)
    (consult-find (list 4))))

(use-package consult			; +project
  :after project
  :config
  (let ((command (if (executable-find "rg")
		     #'consult-ripgrep
		   #'consult-git-grep)))
    (require 'keymap) ;; keymap-substitute requires emacs version 29.1? TODO, change for something what works prior to 29.1
    (require 'cl-seq)

    (keymap-substitute project-prefix-map #'project-find-regexp command)
    (cl-nsubstitute-if
     `(,command "Find regexp")
     (pcase-lambda (`(,cmd _)) (eq cmd #'project-find-regexp))
     project-switch-commands)))
  ;; (setf
  ;;  (car (assq 'project-find-regexp project-switch-commands))
  ;;  'consult-git-grep)

(use-package consult			; +shell
  :after shell
  :bind (:map shell-mode-map
	      (("M-r" . consult-history))))

(use-package consult			; +vertico
  :after vertico
  :bind (:map vertico-map
	      (("M-r" . consult-history))))

(use-package consult-dir
  :bind
  (("C-x C-d" . consult-dir)))

(use-package consult-dir		; +vertico
  :after vertico
  :bind (:map vertico-map
	      (("C-x C-d" . consult-dir)
	       ("C-x C-j" . consult-dir-jump-file))))

(use-package consult-imenu
  :bind
  (("C-c c i" . od/config-consult-imenu-multi))
  :config
  ;; My version of consult-imenu which run standard imenu hooks
  (defun consult-imenu ()
    "Select item from flattened `imenu' using `completing-read' with preview.

The command supports preview and narrowing. See the variable
`consult-imenu-config', which configures the narrowing.
The symbol at point is added to the future history.

See also `consult-imenu-multi'."
    (interactive)
    (consult-imenu--select "Go to item: " (consult-imenu--items))
    (run-hooks 'imenu-after-jump-hook))

  (defun od/config-consult-imenu-multi ()
    "Imenu for all my Emacs configuration files"
    (interactive)
    (consult-imenu--select "Go to item: "
			   (consult-imenu--multi-items (od/get-all-init-buffers))))

  (defun od/get-all-init-files ()
    "Return a list of all files used to configure emacs"
    (flatten-list (list
		   (concat od/emacs-directory "/init.el")
		   (directory-files (concat od/emacs-directory "/lisp")
				    t directory-files-no-dot-files-regexp nil nil))))

  (defun od/get-all-init-buffers ()
    "Return a list of buffers visiting the files that are used to configure Emacs. This function is intended to be used `consult-imenu--multi-items'"
    (seq-map #'find-file-noselect
	     (od/get-all-init-files))))

(use-package consult-org
  :after org				; Load this package when `org-mode' is loaded. `consult' is required by this package so we know it will be loaded.
  :bind (:map org-mode-map
	      (("M-g i" . consult-org-heading))))

(use-package embark
  :after which-key
  :bind
  (("C-." . embark-act)
   :map vertico-map
   ("C-." . embark-act)
   ("M-." . embark-dwim)
   ("C->" . embark-act-noquit)
   ("M-?" . embark-collect))
  :config
  (setq embark-indicators '(embark-highlight-indicator embark-mixed-indicator))
  (setq embark-prompter 'embark-keymap-prompter)

  ;; Don't use the universal-argument when calling `shell' from embark because I don't
  ;; want to be prompted for `default-directory' before spawning a shell buffer.
  (delete '(shell embark--universal-argument) embark-pre-action-hooks)

  (defvar-keymap embark-file-map
    :doc "A simple keymap with a few file actions"
    :parent embark-general-map
    "&" #'async-shell-command
    "s" #'shell)

  (defun embark-act-noquit ()
    "Run action but don't quit the minibuffer afterwards."
    (interactive)
    (let ((embark-quit-after-action nil))
      (embark-act)))

  (defun embark-act-dwim-noquit ()
    "Run action but don't quit the minibuffer afterwards."
    (interactive)
    (let ((embark-quit-after-action nil))
      (embark-dwim)))

  (eval-when-compile
  (defmacro my/embark-ace-action (fn)
    `(defun ,(intern (concat "my/embark-ace-" (symbol-name fn))) ()
       (interactive)
       (with-demoted-errors "%s"
         (require 'ace-window)
         (let ((aw-dispatch-always t))
           (aw-switch-to-window (aw-select nil))
           (call-interactively (symbol-function ',fn)))))))

(define-key embark-file-map     (kbd "M-o") (my/embark-ace-action find-file))
(define-key embark-buffer-map   (kbd "M-o") (my/embark-ace-action switch-to-buffer))
(define-key embark-bookmark-map (kbd "M-o") (my/embark-ace-action bookmark-jump))


(eval-when-compile
  (defmacro my/embark-split-action (fn split-type)
    `(defun ,(intern (concat "my/embark-"
                             (symbol-name fn)
                             "-"
                             (car (last  (split-string
                                          (symbol-name split-type) "-"))))) ()
       (interactive)
       (funcall #',split-type)
       (call-interactively #',fn))))

(define-key embark-file-map     (kbd "2") (my/embark-split-action find-file split-window-below))
(define-key embark-buffer-map   (kbd "2") (my/embark-split-action switch-to-buffer split-window-below))
(define-key embark-bookmark-map (kbd "2") (my/embark-split-action bookmark-jump split-window-below))

(define-key embark-file-map     (kbd "3") (my/embark-split-action find-file split-window-right))
(define-key embark-buffer-map   (kbd "3") (my/embark-split-action switch-to-buffer split-window-right))
(define-key embark-bookmark-map (kbd "3") (my/embark-split-action bookmark-jump split-window-right))

(defun embark-which-key-indicator ()
  "An embark indicator that displays keymaps using which-key.
The which-key help message will show the type and value of the
current target followed by an ellipsis if there are further
targets."
  (lambda (&optional keymap targets prefix)
    (if (null keymap)
        (which-key--hide-popup-ignore-command)
      (which-key--show-keymap
       (if (eq (plist-get (car targets) :type) 'embark-become)
           "Become"
         (format "Act on %s '%s'%s"
                 (plist-get (car targets) :type)
                 (embark--truncate-target (plist-get (car targets) :target))
                 (if (cdr targets) "…" "")))
       (if prefix
           (pcase (lookup-key keymap prefix 'accept-default)
             ((and (pred keymapp) km) km)
             (_ (key-binding prefix 'accept-default)))
         keymap)
       nil nil t (lambda (binding)
                   (not (string-suffix-p "-argument" (cdr binding))))))))

(setq embark-indicators
  '(embark-which-key-indicator
    embark-highlight-indicator
    embark-isearch-highlight-indicator))

(defun embark-hide-which-key-indicator (fn &rest args)
  "Hide the which-key indicator immediately when using the completing-read prompter."
  (which-key--hide-popup-ignore-command)
  (let ((embark-indicators
         (remq #'embark-which-key-indicator embark-indicators)))
      (apply fn args)))

(advice-add #'embark-completing-read-prompter
            :around #'embark-hide-which-key-indicator))

;; TODO: check the use-package definition. I just want this package to be loaded when embark-act is called.
(use-package embark-consult
  :after embark)

(use-package marginalia
  :demand t
  :after vertico
  :custom
  (marginalia-align 'right)
  :config
  ;; Make Embark work with helpful-variable
  (add-to-list 'marginalia-prompt-categories '("\\<Variable\\>" . variable))
  ;; Don't use marginalia with `switch-to-buffer'
  ;; (setf (alist-get 'buffer marginalia-annotator-registry) '(marginalia-annotate-buffer builtin none))
  (marginalia-mode 1)

  ;; TODO: Delete me if something like this goes upstream.
  ;; For now bookmarks visiting remote files are annotated, causing a slowdown.
  ;; See https://github.com/minad/marginalia/issues/191
  (defun marginalia-annotate-bookmark (cand)
    "Annotate bookmark CAND with its file name and front context string."
    (marginalia-annotate-file cand)))

(use-package openwith
  :defer 10				; this seems to solve the problem when it would only work the second time
  ;;:demand t
  :config
  (setq openwith-associations
        (list
         (list (openwith-make-extension-regexp
                '("mpg" "mpeg" "mp3" "mp4"
                  "avi" "wmv" "wav" "mov" "flv"
                  "ogm" "ogg" "mkv" "webm"))
               "mpv"
               '(file))
         ;; (list (openwith-make-extension-regexp
         ;;        '("xbm" "pbm" "pgm" "ppm" "pnm"
         ;;          "png" "gif" "bmp" "tif" "jpeg" "jpg"))
         ;;       "sxiv"
         ;;       '(file)) ; This tries to display images in external application when I want
	 ;;                ; to display them in an org-mode buffer.
         (list (openwith-make-extension-regexp
                '("doc" "xls" "ppt" "odt" "ods" "odg" "odp" "rtf"))
               "libreoffice"
               '(file))
         '("\\.lyx" "lyx" (file))
         '("\\.chm" "kchmviewer" (file))
         ;; (list (openwith-make-extension-regexp
         ;;        '("pdf" "ps" "ps.gz" "dvi"))
         ;;       "okular"
         ;;       '(file))
         ))
  (openwith-mode 1)
  (setq large-file-warning-threshold nil))

(use-package orderless
  :demand t
  :custom
  (completion-styles '(orderless partial-completion;; basic
				 ))
  ;; /h/n/do will match /home/nic/downloads
  ;; Note that this prevents char fold matching. Solution: Don't use accents in file names
  (completion-category-overrides '((file (styles . (partial-completion)))))
  :config				; Make sure that `char-fold-to-regexp' is loaded
  (require 'char-fold)
  (defalias 'od/orderless-literal-char-fold #'char-fold-to-regexp
    "Match a component as a literal string with character folding.
This means that \"a\" would match \"a\", \"à\" and \"â\".")
  (setq orderless-matching-styles '(od/orderless-literal-char-fold orderless-regexp)))

(use-package vertico
  :demand t
  :bind (:map vertico-map
	      ("C-n" . vertico-next)
	      ("C-p" . vertico-previous)
	      ("C-M-n" . vertico-next-group)
	      ("C-M-p" . vertico-previous-group)
	      ("M-<return>" . vertico-exit-input)
	      ("C-l" . backward-kill-sexp))
  :config
  (setq vertico-count 19
	vertico-resize nil)

  (add-hook 'vertico-mode-hook (lambda ()
                           (setq completion-in-region-function
                                 (if vertico-mode
                                     #'consult-completion-in-region
                                   #'completion--in-region))))

  ;; Allow completion for remote files
  (defun basic-remote-try-completion (string table pred point)
    (and (vertico--remote-p string)
	 (completion-basic-try-completion string table pred point)))
  (defun basic-remote-all-completions (string table pred point)
    (and (vertico--remote-p string)
	 (completion-basic-all-completions string table pred point)))
  (add-to-list
   'completion-styles-alist
   '(basic-remote basic-remote-try-completion basic-remote-all-completions nil))
  (setq completion-styles '(orderless basic)
	completion-category-overrides '((file (styles basic-remote partial-completion))))

  ;; Does this improve tramp hanging ? See https://github.com/minad/vertico/issues/329
  (defun pcm-remote-try-completion (string table pred point)
    (if (vertico--remote-p string)
	(completion-basic-try-completion string table pred point)
      (completion-pcm-try-completion string table pred point)))
  (defun pcm-remote-all-completions (string table pred point)
    (if (vertico--remote-p string)
	(completion-basic-all-completions string table pred point)
      (completion-pcm-all-completions string table pred point)))
  (add-to-list
   'completion-styles-alist
   '(partial-completion-remote-fix
     pcm-remote-try-completion
     pcm-remote-all-completions
     "Partial completion for local path and basic completion for remote path"))
  (setq completion-category-overrides
	'((file (styles orderless partial-completion-remote-fix))))
  ;; End of snippet

  (vertico-mode))

(use-package vertico-directory
  :after vertico
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy)
  :bind (:map vertico-map
	      ("M-<backspace>" . vertico-directory-delete-word)))

(use-package vertico-mouse
  :disabled t
  :after vertico
  :config
  (vertico-mouse-mode))

(use-package vertico-multiform
  :disabled t
  :demand t
  :after vertico
  :config
  ; Enable vertico-multiform
  (vertico-multiform-mode)
  (setq vertico-multiform-categories
	'((file vertico-grid-mode)
	  (project-file vertico-grid-mode)))
  ;; Configure the display per command
  (setq vertico-multiform-commands
	'((consult-imenu buffer)
	  (consult-line buffer)
	  (consult-git-grep buffer)
	  (consult-org-heading buffer)
	  (consult-outline buffer)
	  (consult-ripgrep buffer)
	  (consult-grep buffer))))

(use-package vertico-buffer
  :after vertico
  :config
  (setq vertico-buffer-display-action 'display-buffer-reuse-window))

(use-package vertico-posframe
  :disabled t
  :demand t
  :after vertico
  :config
  (defun od/vertico-posframe-get-size (buffer)
    (list
     :height (1+ vertico-count)
     :width 170
     :min-height (1+ vertico-count)
     :min-width (round (* 0.9 (frame-width)))))

  (setq vertico-posframe-border-width 1)
  (setq vertico-posframe-size-function #'od/vertico-posframe-get-size))

(provide 'init-completion)
