;;; init_new.el ---
;; Credentials

;;; Commentary:
;;

;;; Code:

(setq calendar-latitude 44.5
      calendar-longitude -73.6
      user-mail-address "nodermattlemay@gmail.com"
      user-full-name "Nicolas Odermatt-Lemay")

;; My emacs configuration directory
(defvar od/emacs-directory (concat (getenv "HOME") "/.config/emacs"))

;; My Emacs Lisp configuration directory
(add-to-list 'load-path (expand-file-name "lisp/" user-emacs-directory))

;; My Nextcloud directory
(defvar od/nextcloud-directory (concat (getenv "HOME") "/nc"))

;; My bibliography file
(defvar od/bibliography-path (concat od/nextcloud-directory "/zotero/library.bib"))

;; Current running desktop environment
(defvar od/desktop-environment (getenv "XDG_CURRENT_DESKTOP"))

;; My notes directory
(defvar od/notes-directory (expand-file-name "nc2/notes" "~"))

;; Is this system using EXWM
(defvar od/exwm-enabled (and (eq window-system 'x)
                             (seq-contains command-line-args "--use-exwm")))

;; Restore garbage collection to its initial value
(add-hook 'emacs-startup-hook
	  `(lambda ()
	     (setq gc-cons-threshold 800000
		   gc-cons-percentage 0.1)
	     (garbage-collect)) t)

;; Display emacs init time and number of garbage collections during initialization
(add-hook 'emacs-startup-hook
	  `(lambda ()
	     (let ((elapsed
		    (float-time
		     (time-subtract (current-time) emacs-start-time))))
	       (message "Loading Emacs... done (%.3fs). Garbage collections: %d"
			elapsed gcs-done))) t)

(when init-file-debug
  (setq use-package-verbose t
        use-package-expand-minimally nil
        use-package-compute-statistics t
        debug-on-error t))

(use-package use-package
  :config
  ;; This replaces the variable `use-package-enable-imenu-support' which doesn't work with `emacs-lisp-mode'
  (add-hook 'emacs-lisp-mode-hook
	    #'(lambda ()
		(add-to-list 'imenu-generic-expression
			     '("Packages"
			       "^\\s-*(\\(\\(?:requir\\|use-packag\\)e\\)\\s-+\\(\\(?:\\sw\\|\\s_\\|\\\\.\\)+\\)" ;; Use the value of `use-package-form-regexp-eval' to get this value.
			       2))))
  ;; Doesn't work as it adds the support to `lisp-mode' while I'd want it with `emacs-lisp-mode'. Surprisingly `emacs-lisp-mode' isn't a child of `lisp-mode' but of `lisp-data-mode'.
  ;; (use-package-enable-imenu-support t)
  :custom
  (use-package-always-ensure nil)
  (use-package-verbose t))

;; Try to find what messes up with `file-name-handler-alist' (it is not my early-init.el)
;; (defun my-variable-watcher (symbol newval operation where)
;;   (message "Symbol (%s) modified to %s.\n Operation: %s\n Where: %s"
;; 	   symbol newval operation where))
(setq default-file-name-handler-alist file-name-handler-alist)
;; (add-variable-watcher 'file-name-handler-alist 'my-variable-watcher)

;; TODO: refactor modules to have the following: safe-variables, default, org, completion, theme (or ui) and the rest a last module for all packages (init-???)
(use-package emacs
  :hook ((after-init . toggle-frame-maximized))
  :bind
  (("C-é" . undo)
   ("C-x x r" . od/rename-current-buffer-file)
   ("C-c y" . nol/kill-line-and-yank))
  :init
  (require 'safe-variables)		; Because init.el is read-only, I can't save to it interactively
  (require 'init-default)		; Packages included in Emacs by default
  (require 'init-completion)		; Consult, Embark, Marginalia, Vertico
  (require 'init-ui)
  (require 'init-dired)
  (require 'init-misc)
  (require 'init-window)
  (require 'init-org)
  (require 'init-prog)
  ;;(require 'init-transient)
  (require 'init-shell)
  (require 'init-bib)
  (require 'init-llm)
  (when od/exwm-enabled
    (require 'init-exwm))
  (require 'init-dashboard)
  (run-with-idle-timer (* 2 60 60) t '(lambda () (delete-other-windows) (my/dashboard)))
  :custom
  (initial-buffer-choice 'my/dashboard)
  :config				; Configuration not related to a package (C code)
  (defalias 'yes-or-no-p 'y-or-n-p)
  (setq command-switch-alist '(("-use-exwm" . (lambda (_) nil)))
	delete-by-moving-to-trash nil
	enable-recursive-minibuffers t
	load-prefer-newer t
	ring-bell-function 'timu-ui-flash-mode-line
	scroll-preserve-screen-position t
	window-resize-pixelwise t
	;; Try really hard to keep the cursor from getting stuck in the read-only prompt
	;; portion of the minibuffer.
	minibuffer-prompt-properties
	'(read-only t intangible t cursor-intangible t face minibuffer-prompt))

  (setq-default fill-column 120)
  (setq-default truncate-lines t)

  ;; Performance tweaks: https://emacsredux.com/blog/2026/04/07/stealing-from-the-best-emacs-configs/
  (setq-default bidi-display-reordering 'left-to-right
		bidi-paragraph-direction 'left-to-right)
  (setq bidi-inhibit-bpa t)
  (setq redisplay-skip-fontification-on-input t)
  (setq read-process-output-max (* 4 1024 1024))

  ;; Does this fix my problem where tinty apply doesn't apply to Emacs unless I've restarted (forced) the server ?
  (server-force-delete)
  (server-start)

  ;; Manage backup files. This takes care of files ending in ~
  (setq backup-directory-alist `(("." . ,(concat user-emacs-directory "saves")))))

(provide 'init_new)
