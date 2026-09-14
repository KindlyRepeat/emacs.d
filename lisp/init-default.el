;; -*- lexical-binding: t; -*-

(use-package auth-source
  :config
  (setq auth-sources '("~/.authinfo.gpg")))

(use-package auth-source-pass
  :config
  (setq auth-source-pass-filename "~/.password-store/"))

(use-package autorevert
  :config
  (setq auto-revert-check-vc-info t)
  (global-auto-revert-mode))

;; (use-package bindings
;;   :custom
;;   (mode-line-collapse-minor-modes '()))

(use-package browse-url
  :config
  (defun od/open-in-mpv (url &optional _new-window)
    "Open URL using mpv."
    (let* ((process-name (concat "mpv: " url)))
      (start-process process-name
		     (s-wrap process-name "*")
		     "nohup" "mpv" url)))

  (add-to-list 'browse-url-handlers
	     (cons "https://www\\.youtube.com/" 'od/open-in-mpv)))

(use-package calendar
  :config
  (setq calendar-holidays '((holiday-fixed 1 1 "Jour de l'An")
			    (holiday-fixed 2 14 "Saint-Valentin")
			    ;; Deuxième dimanche du mois de mars
			    (holiday-float 3 0 2 "Changement d'heure (avance l'heure)")
			    (holiday-fixed 3 17 "Fête de la Saint-Patrick")
			    (holiday-easter-etc 0 "Pâques")
			    (holiday-easter-etc 1 "Lundi de Pâques")
			    (holiday-easter-etc -2 "Vendredi saint")
			    (holiday-fixed 4 1 "Poisson d'avril")
			    ;; Deuxième dimanche de mai
			    (holiday-float 5 0 2 "Fête des Mères")
			    (holiday-fixed 4 22 "Jour de la Terre")
			    ;; Lundi qui précède le 25 mai
			    (holiday-float 5 1 -1 "Journée nationale des patriotes" 25)
			    (holiday-float 6 0 3 "Fête des Pères")
			    (holiday-fixed 6 24 "Fête nationale du Québec")
			    (holiday-fixed 7 1 "Fête du Canada")
			    ;; Deux derniers dimanches du mois de juillet
			    (holiday-float 7 0 -2 "Vacances de la construction (semaine 1)")
			    (holiday-float 7 0 -1 "Vacances de la construction (semaine 2)")
			    ;; Premier lundi de septembre
			    (holiday-float 9 1 1 "Fête du Travail")
			    (holiday-fixed 9 30 "Journée nationale de la vérité et de la réconciliation")
			    ;; Deuxième lundi d'octobre
			    (holiday-float 10 1 2 "Action de grâce")
			    (holiday-fixed 10 31 "Halloween")
			    (holiday-float 11 6 1 "Changement d'heure (recule l'heure)")
			    (holiday-fixed 12 24 "Veille de Noël")
			    (holiday-fixed 12 25 "Noël")
			    (holiday-fixed 12 31 "Veille du Jour de l'An"))))

(use-package comint
  :hook
  ((comint-mode . (lambda () (setq-local truncate-lines nil))))
  :config
  (add-to-list 'comint-output-filter-functions 'comint-osc-process-output)
  (set-face-attribute 'comint-highlight-input nil :weight 'bold)
  ;; This controls the prompt face in shell buffers.
  (set-face-attribute 'comint-highlight-prompt nil :weight 'semi-bold :underline t)
  (setq comint-prompt-read-only t))

;; (use-package compat
;;   :straight (compat :type git :host github :repo "emacs-compat/compat"))

(use-package compile ;; TODO put compilation buffer in the current window
  :hook ((compilation-filter . ansi-color-compilation-filter)
	 (compilation-filter . ansi-osc-compilation-filter))
  :bind (:map compilation-shell-minor-mode-map
	      (("C-c C-c" . recompile)))
  :custom
  (compilation-scroll-output t)
  :config
  ;; Force the `COMINT' argument of `compile' as `t'. Without this argument, we can't
  ;; use `sudo' commands as it won't prompt us for a password.
  (defun od/compile-force-comint (r)
    (list (car r) t))

  (advice-add #'compile :filter-args #'od/compile-force-comint))

(use-package completion-preview
  :hook (prog-mode . completion-preview-mode)
  :bind
  ( :map completion-preview-active-mode-map
    ("M-n" . completion-preview-next-candidate)
    ("M-p" . completion-preview-prev-candidate))
  :init
  (add-to-list 'mode-line-collapse-minor-modes 'completion-preview-mode))

(use-package cua-base
  :config
  (cua-mode 1))

(use-package cus-edit
  :config
  ;; Because I use `home-dotfiles-service-type', this prevent the file from being read-only.
  (setq custom-file (concat od/emacs-directory "/custom.el")))

(use-package delsel
  :demand t
  :config
  (delete-selection-mode 1))

(use-package desktop
  :disabled t
  :after tab-bar
  :config
  ;; Not sure what causes the desktop to be locked, but better without it
  (setq desktop-load-locked-desktop t)
  ;; Number of buffers to restore immediately. Remaining buffers are restored lazily
  (setq desktop-restore-eager t)
  ;; Restoring frames create more exwm workspaces then i need to
  (setq desktop-restore-frames t)
  (desktop-save-mode 1))

(use-package dictionary
  :custom
  (dictionary-create-buttons nil)
  (dictionary-word-definition-face 'variable-pitch)
  (dictionary-word-entry-face 'modus-themes-heading-1))

(use-package ediff-diff
  :custom
  (ediff-diff-options "-w")
  (ediff-split-window-function 'split-window-horizontally)
  ;; Don't let ediff break EXWM, keep it in one frame
  (ediff-window-setup-function 'ediff-setup-windows-plain))

;; Its enabled by default.
(use-package eldoc
  :init
  (add-to-list 'mode-line-collapse-minor-modes 'eldoc-mode))

(use-package epg-config
  :config
  (setq epg-gpg-program "gpg"
	epg-pinentry-mode 'loopback))

(use-package erc
  :config
  (setq erc-join-buffer 'buffer))

(use-package eww
  :commands (eww)
  :hook (eww-mode . (lambda ()
		      (setq-local line-spacing 4))))

(use-package face-remap
  :hook (text-mode . variable-pitch-mode)
  :bind ("C-x C-=" . global-text-scale-adjust)
  :custom
  (text-scale-mode-step 1.1)
  :init
  (add-to-list 'mode-line-collapse-minor-modes 'buffer-face-mode))

(use-package files
  :bind ("C-x f" . find-file)
  :custom
  (enable-local-variables :safe)
  (trash-directory "~/.config/emacs/trash"))

(use-package find-func
  :bind
  ("C-h l" . find-library))

(use-package flyspell
  :disabled t
  :hook (text-mode . flyspell-mode))

(use-package gnus
  :disabled t				; When enabled, create a circular dependency with modus themes... no idea why
  :config
  (when (boundp 'golden-ratio-exclude-modes)
    (add-to-list 'golden-ratio-exclude-modes 'gnus-summary-mode)
    (add-to-list 'golden-ratio-exclude-modes 'gnus-article-mode))

  ;; Define faces to use with `gnus-summary-line-format'.
  (defface od/gnus-date '((t (:inherit org-date)))
    "Face for date in summary buffer.")
  (setq gnus-face-7 'od/gnus-date)
  (setq gnus-face-8 'od/gnus-date)

  (defface od/gnus-size '((t (:inherit shadow)))
    "Face for size in summary buffer.")
  (setq gnus-face-9 'od/gnus-size)

  (defface od/gnus-poster '((t (:inherit change-log-name)))
    "Face for poster in summary buffer.")
  (setq gnus-face-10 'od/gnus-poster)

  ;; TODO: SHouldI use nnnmaildir ?
  (setq gnus-select-method '(nnnil "")
	gnus-secondary-select-methods '((nnmaildir "private"
						   (directory "~/mail/gmail"))))

  (setq gnus-summary-line-format
	(concat
	 "%U"                                ; "read" status
	 "%3{%R%}"                           ; "reply" status
	 "%7{%z%} "                          ; score
	 "%8{%~(pad-left 20)&user-date; %} " ; date
	 "%9{ %4k %}"                        ; size
	 "%*" "%10{%-50,50f %}"              ; cursor before name of the poster
	 ;; "%u&r;  "
	 "%B"
	 "%I%s"
	 "\n"))

    ;; Don't ask before displaying a newsgroup with a lot of articles.
  (setq gnus-large-newsgroup nil)
  ;; Don't ask before deleting news.
  (setq gnus-novice-user nil))

(use-package gnus-art
  :disabled t
  :bind (:map gnus-article-mode-map
	      (("q" . gnus-summary-expand-window))))

(use-package gnus-async
  :disabled t
  :custom
  (gnus-asynchronous t))

(use-package gnus-group
  :disabled t
  :hook ((gnus-group-mode . gnus-topic-mode))
  :config
  ;; List all groups in the group buffer even if they don't have unread articles.
  (setq gnus-permanently-visible-groups ""))

(use-package gnus-start
  :disabled t
  :config
  ;; Save some startup time. See (gnus) New Groups.
  (setq gnus-check-new-newsgroups nil)
  (setq gnus-save-newsrc-file nil)
  (setq gnus-read-newsrc-file nil))

(use-package gnus-sum
  :disabled t
  :hook ((gnus-summary-exit . gnus-summary-bubble-group))
  :bind (:map gnus-summary-mode-map
	      (("g" . gnus-summary-insert-new-articles) ;; TODO: I also want to delete execute marks
	       ("u" . gnus-summary-put-mark-as-unread-next)
	       ("r" . gnus-summary-put-mark-as-read-next)
	       ("d" . gnus-summary-put-mark-as-expirable-next) ; Like dired's `dired-flag-file-deletion'.
	       ("x" . gnus-summary-expire-articles-now)        ; Like dired's `dired-do-flagged-delete'.

	       ))
  :config
  ;; I'd rather have it bold.
  (set-face-attribute 'gnus-summary-normal-unread nil :weight 'bold)
  (set-face-attribute 'gnus-summary-normal-ticked nil :weight 'bold)
  (setq-default gnus-sum-thread-tree-leaf-with-other "├── "
		gnus-sum-thread-tree-single-leaf "└── "
		gnus-sum-thread-tree-vertical "│ ")
  ;; Center the summary buffer around the selected article.
  (setq gnus-auto-center-summary t)
  ;; Don't go to the next group when at the end of the current one.
  (setq gnus-auto-select-next nil)
  ;; Show read articles in threads. This gives us a complete tree.
  (setq gnus-fetch-old-headers t)
  (setq gnus-user-date-format-alist
        '(((gnus-seconds-today) . "Today at %R")
          ((+ (* 60 60 24) (gnus-seconds-today)) . "Yesterday, %R")
          (t . "%Y-%m-%d %R")))
  (setq gnus-thread-sort-functions '(gnus-thread-sort-by-most-recent-date)))

(use-package hl-line-mode		; +eww
  :after eww
  :hook ((eww-mode . hl-line-mode)))

(use-package ibuffer
  :bind
  (("C-x C-b" . ibuffer))
  :custom
  (ibuffer-formats '((" "
		      (name 30 30 :left :elide) " "
		      (size 9 -1 :right) " "
		      (mode 16 16 :left :elide) " "
		      filename-and-process)
		     (mark " " (name 16 -1) " " filename))))

(use-package icomplete
  :disabled t
  :bind (:map icomplete-minibuffer-map
              ("C-n" . icomplete-forward-completions)
              ("C-p" . icomplete-backward-completions)
              ("C-v" . icomplete-vertical-toggle)
              ("RET" . icomplete-force-complete-and-exit))
  :hook
  (after-init . (lambda ()
                  (icomplete-vertical-mode 1)))
  :config
  (setq tab-always-indent 'complete)  ;; Starts completion with TAB
  (setq icomplete-delay-completions-threshold 0)
  (setq icomplete-compute-delay 0)
  (setq icomplete-show-matches-on-no-input t)
  (setq icomplete-hide-common-prefix nil)
  (setq icomplete-prospects-height 10)
  (setq icomplete-separator " . ")
  (setq icomplete-with-completion-tables t)
  (setq icomplete-in-buffer t)
  (setq icomplete-max-delay-chars 0)
  (setq icomplete-scroll t)
  (advice-add 'completion-at-point
              :after #'minibuffer-hide-completions)

  (setq icomplete-vertical-in-buffer-adjust-list t)
  (setq icomplete-vertical-render-prefix-indicator t))

(use-package imenu
  :hook (imenu-after-jump . (lambda () (recenter nil))))

(use-package isearch
  :commands (isearch)
  :custom
  (isearch-allow-scroll t)
  (isearch-lazy-count t)
  ;; For "a" to match "a", "à" and "â".
  (search-default-mode 'char-fold-to-regexp))

(use-package ispell
  :custom
  (ispell-dictionary "en_US")
  (ispell-program-name (executable-find "hunspell")))

(use-package lisp
  :bind (("M-\"" . insert-double-quotes))
  :init
  (defun insert-double-quotes (&optional arg)
    "Enclose following ARG sexps or region in double quotes.

If region is active, insert enclosing quotes around region boundaries.
If ARG is non-nil, enclose following ARG sexps (negative ARG for preceding).
No argument inserts a pair of quotes and leaves point between them."
    (interactive "P")
    (insert-pair arg ?\" ?\")))

(use-package lisp-mode
  :config

  ;;`emacs-lisp-mode' and `lisp-mode' are both derived from `lisp-data-mode'.
  (defun od/lisp-data-mode-before-save-hook ()
    (when (derived-mode-p 'lisp-data-mode)
      (save-excursion
	(check-parens))))

  ;; Can't add to `before-save-hook' because the message saying that the buffer is
  ;; written to a file overwrites the error.
  (add-hook 'after-save-hook #'od/lisp-data-mode-before-save-hook))

(use-package man)

(use-package message
  :custom (message-send-mail-function 'message-send-mail-with-sendmail))

(use-package minibuffer
  :bind
  ( :map minibuffer-mode-map
    (("<prior>" . scroll-down-command)
     ("<next>" . scroll-up-command)))
  :custom
  (completion-eager-update t)
  (completion-eager-display 'auto)
  (minibuffer-visible-completions 'up-down))

(use-package mule-util
  :config
  ;; By default, Emacs use the … character, which is larger than a normal character and causes misalignment
  ;; in the Ebib index buffer for example.
  (setq truncate-string-ellipsis "..."))

(use-package mwheel
  :config
  ;; Enable horizontal scrolling. I might prefer to not truncate-lines and horizontal scroll instead
  ;; `scroll-bar-height' in `default-frame-alist' controls the height of the bar
  ;; Horizontal bar is enabled in package `scroll-bar.el'
  (setq mouse-wheel-progressive-speed nil ; Otherwise it is way too sensitive
	mouse-wheel-tilt-scroll t))

(use-package recentf
  ;; Add more recent file to `consult-buffer'.
  :custom (recentf-max-saved-items 50)
  :config
  (recentf-mode))

(use-package repeat
  :config
  (repeat-mode 1))

(use-package replace)

(use-package savehist
  :config
  ;; Save history between sessions
  (setq savehist-file (concat od/emacs-directory "/savehist"))
  (setq savehist-save-minibuffer-history t)
  (setq savehist-additional-variables '( search-ring regexp-search-ring
					 kill-ring browse-url-history))
  ;; save minibuffer history between sessions
  (savehist-mode 1))

(use-package saveplace
  :config
  ;; Messes up the org startup visibility. If the point is inside a heading, it
  ;; shows as unfolded even if I've set `org-startup-folded' to `folded'.
  (save-place-mode -1))

(use-package scheme
  :config

  (defun od/scheme-mode-before-save-hook ()
    (when (eq major-mode 'scheme-mode)
      (check-parens)))

  ;; Can't add to `before-save-hook' because the message saying that the buffer is
  ;; written to a file overwrites the error.
  (add-hook 'after-save-hook #'od/scheme-mode-before-save-hook)

  (defun od/guix-build-current-file ()
    "Call `guix build' on the current file."
    (interactive)
    (compile (format "guix build -L ~/dotfiles -L ~/dotfiles/guix-dotfiles/packages/patches --no-offload --keep-failed --file=%s" (buffer-file-name)) t)))

;; (use-package scroll-bar
;;   :init
;;   (defun od/set-horizontal-scroll-bar ()
;;     (modify-all-frames-parameters '((horizontal-scroll-bars . t)
;; 				    (scroll-bar-height . 4))))
;;   ;; What a mess, but I can't make it work otherwise.
;;   (add-hook 'emacs-startup-hook
;; 	    '(lambda () (run-with-timer 1 nil 'od/set-horizontal-scroll-bar))))

(use-package sendmail
  :config
  (setq sendmail-program "msmtp"))

(use-package shr)

(use-package shr			; +eww
  :after eww
  :hook ((eww-mode . shr-heading-setup-imenu))
  :bind (:map eww-mode-map
	      (("C-c C-p" . shr-heading-previous)
	       ("C-c C-n" . shr-heading-next)))
  :config
  (defun shr-heading-next (&optional arg)
    "Move forward by ARG headings (any h1-h4).
If ARG is negative move backwards, ARG defaults to 1."
    (interactive "p")
    (unless arg (setq arg 1))
    (catch 'return
      (dotimes (_ (abs arg))
	(when (> arg 0) (end-of-line))
	(if-let ((match
                  (funcall (if (> arg 0)
                               #'text-property-search-forward
                             #'text-property-search-backward)
                           'face '(shr-h1 shr-h2 shr-h3 shr-h4)
                           (lambda (tags face)
                             (cl-loop for x in (if (consp face) face (list face))
                                      thereis (memq x tags))))))
            (goto-char
             (if (> arg 0) (prop-match-beginning match) (prop-match-end match)))
          (throw 'return nil))
	(when (< arg 0) (beginning-of-line)))
      (beginning-of-line)
      (point)))

  (defun shr-heading-previous (&optional arg)
    "Move backward by ARG headings (any h1-h4).
If ARG is negative move forwards instead, ARG defaults to 1."
    (interactive "p")
    (shr-heading-next (- (or arg 1))))

  (defun shr-heading--line-at-point ()
    "Return the current line."
    (buffer-substring (line-beginning-position) (line-end-position)))

  (defun shr-heading-setup-imenu ()
    "Setup imenu for h1-h4 headings in eww buffer.
Add this function to appropriate major mode hooks such as
`eww-mode-hook' or `elfeed-show-mode-hook'."
    (setq-local
     imenu-prev-index-position-function #'shr-heading-previous
     imenu-extract-index-name-function  #'shr-heading--line-at-point)))

(use-package simple
  :hook ((before-save . delete-trailing-whitespace)
	 (text-mode . visual-line-mode))
  :bind
  (("C-c C-j" . join-line)
   ("<XF86Paste>" . yank)
   ("<XF86Copy>" . kill-ring-save)
   ("<XF86Cut>" . kill-region)
   ("M-g g" . od/goto-line)
   :map minibuffer-local-shell-command-map
   ("C-e" . end-of-line))
  :custom
  (set-mark-command-repeat-pop t)
  (shell-command-prompt-show-cwd t)
  (save-interprogram-paste-before-kill t)
  (kill-do-not-save-duplicates t)
  :init
  (add-to-list 'mode-line-collapse-minor-modes 'visual-line-mode)
  :config
  (column-number-mode 1))

(use-package speedbar
  :if (not (version< emacs-version "30.0.50"))
  :custom
  (speedbar-prefer-window t))

(use-package sql
  :commands (sql-connect)
  :config
  (setq sql-sqlite-program "/usr/bin/sqlite3"))

(use-package paren
  :config
  (show-paren-mode 1))

(use-package pixel-scroll
  :disabled t
  :if (not (version< emacs-version "29"))
  :config
  (pixel-scroll-precision-mode 1))

(use-package proced
  :hook (proced-mode . (lambda () (proced-toggle-auto-update 1)))
  :config
  (setq proced-auto-update-interval 1))

(use-package project
  :config
  (setq project-switch-commands '((project-find-file "Find file")
				  (consult-ripgrep "Find regexp")
				  (project-find-dir "Find directory")
				  (project-vc-dir "VC-Dir")
				  (project-shell "Shell")
				  (project-compile "Compile"))
	project-vc-extra-root-markers '(".project")) ; This variable was added in version 0.9.0

  ;; Overwrite this function, adding spaces before and after the '-'.
  (defun project-prefixed-buffer-name (mode)
    (concat "*"
            (if-let* ((proj (project-current nil)))
		(project-name proj)
              (file-name-nondirectory
               (directory-file-name default-directory)))
            " - "
            (downcase mode)
            "*"))

  (defun od/project-filter-remote-projects (r)
    "Prevent saving of remote projects because Tramp trying to establish a connection is annoying."
    (if (file-remote-p (project-root (car r)))
	(list (car r) t)
      r))

  (advice-add #'project-remember-project :filter-args #'od/project-filter-remote-projects))

(use-package tab-bar
  :custom
  (tab-bar-show 1)
  :config
  (defun od/tab-bar-tab-name-format-default (tab i)
    "Center the tab name and add spaces if it is shorter than 15 characters."
    (require 's)
    (let ((current-p (eq (car tab) 'current-tab)))
      (propertize
       (concat (if tab-bar-tab-hints (format "%d " i) "")
               (s-center 15 (alist-get 'name tab))
               (or (and tab-bar-close-button-show
			(not (eq tab-bar-close-button-show
				 (if current-p 'non-selected 'selected)))
			tab-bar-close-button)
                   ""))
       'face (funcall tab-bar-tab-face-function tab))))

  (setq tab-bar-close-button-show nil
	tab-bar-new-tab-to 'rightmost
	tab-bar-tab-name-format-function 'od/tab-bar-tab-name-format-default)

  (tab-bar-mode -1))

(use-package text-mode
  :hook (text-mode . (lambda ()
		       (setq-local line-spacing 4))))

(use-package tramp
  :config
  (connection-local-set-profile-variables
   'remote-bash
   `((explicit-shell-file-name . "bash")
     (explicit-bash-args . ("--noediting" "--login"))))

  (connection-local-set-profiles
   '(:application tramp :protocol "ssh" :user "nic" :machine "kakistocrat")
   'remote-bash)
  (connection-local-set-profiles
   '(:application tramp :protocol "ssh" :user "nic" :machine "exaltation")
   'remote-bash)

  ;; (match-string 2) is the user, (match-string 1) is the host.
  (setq od/ssh-config-host-and-user-regexp
	"Host \\([^ \n]+\\)\\(?:\n.+\\)*User \\([^ \n]+\\)")

  (defun od/ssh-config-get-user-and-host (regexp)
    "Return a list of (user host) tuples from ~/.ssh/config."
    (let ((matches))
      (save-match-data
	(save-excursion
          (with-current-buffer (get-file-buffer "~/.ssh/config")
            (save-restriction
              (widen)
              (goto-char 1)
              (while (search-forward-regexp regexp nil t 1)
		(push (cons (match-string 2) (match-string 1)) matches)))))
	matches)))

  (defun od/parse-ssh-config-as-tramp-paths ()
    (mapcar (lambda (tuple)
	  (let ((user (car tuple))
		(host (cdr tuple)))
	    (concat "/ssh:" user "@" host ":~")))
	(matches-in-buffer od/ssh-config-host-and-user-regexp)))


  )

(use-package vc-hooks
  :defer t
  :config
  (setq vc-follow-symlinks t))		; Don't ask if I want to follow symbolic link (I always do)

(use-package warnings
  :custom
  (warning-minimum-level :error))

(use-package which-key
  :demand t
  :init
  (add-to-list 'mode-line-collapse-minor-modes 'which-key-mode)
  :config
  (which-key-mode))

(use-package windmove
  :bind
  (("s-h" . windmove-left)
   ;;("<escape> h" . windmove-left)
   ("s-j" . windmove-down)
   ;;("<escape> j" . windmove-down)
   ("s-k" . windmove-up)
   ;;("<escape> k" . windmove-up)
   ("s-l" . windmove-right)
   ;;("<escape> l" . windmove-right)
   ("C-s-h" . windmove-swap-states-left)
   ("C-s-j" . windmove-swap-states-down)
   ("C-s-k" . windmove-swap-states-up)
   ("C-s-l" . windmove-swap-states-right)))

(provide 'init-default)
