(use-package async
  :after dired
  :config
  (dired-async-mode))

(use-package dired
  :bind
  (:map dired-mode-map
	(("M-s f" . consult-find)
	 ;; ("C-s" . consult-line)
	 ("r" . dired-do-rename)))
  :hook
  (dired-mode . (lambda () (toggle-truncate-lines -1)))
  :config
  ;; Automatically revert Dired buffers on revisiting their directory
  (setq dired-auto-revert-buffer t
	dired-dwim-target t ; Guess a default target directory
	dired-listing-switches "-alh") ;; --group-directories-first isn't supported on KOBO ereader

  (when (>= emacs-major-version 28)
    (setq dired-kill-when-opening-new-dired-buffer nil))

  (defun od/dired-find-file-other-window-and-fit-window ()
    "In Dired, visit this file or directory in another window. Resize the Dired buffer."
    (interactive)
    (let ((dired-window (selected-window)))
      (dired-find-file-other-window)
      (with-selected-window dired-window
	(fit-window-to-buffer))))

  (add-hook 'dired-mode-hook #'(lambda () (dired-hide-details-mode 1)))
  ;;(add-hook 'dired-mode-hook #'(lambda () (text-scale-set -1)))
  (add-hook 'dired-mode-hook 'hl-line-mode)
  )

(use-package diredfl
  :hook
  ;; I want denote-dired-mode instead
  (dired-mode . (lambda () (unless (string= dired-directory "~/nc/notes/") (diredfl-mode 1)))))

(use-package dired-sidebar
  :disabled t
  :bind
  (("C-x C-j" . od/dired-sidebar-toggle-sidebar))
  :hook
  (dired-sidebar-mode . hl-line-mode)
  :config
  (setq dired-sidebar-window-fixed nil
	dired-sidebar-subtree-line-prefix "__"
	dired-sidebar-use-custom-modeline nil)

  ;; My version of this function. When the sidebar is visible but not on the current directory, don't hide the sidebar. Instead show the current directory in it.
  (defun od/dired-sidebar-toggle-sidebar (&optional dir)
  "Toggle the project explorer window.
Optional argument DIR Use DIR as sidebar root if available.

With universal argument, use current directory."
  (interactive)

    (let* ((old-buffer (dired-sidebar-buffer (selected-frame)))
           (file-to-show (dired-sidebar-get-file-to-show))
           (dir-to-show (or dir
                            (when current-prefix-arg
                              (expand-file-name default-directory))
                            (dired-sidebar-get-dir-to-show)))
           (sidebar-buffer (dired-sidebar-get-or-create-buffer dir-to-show)))

      (if (and (dired-sidebar-showing-sidebar-p)
	       (not (string= dir-to-show default-directory)))
	  (dired-sidebar-hide-sidebar)

      (dired-sidebar-show-sidebar sidebar-buffer)
      (when (and dired-sidebar-use-one-instance old-buffer
		 (not (eq sidebar-buffer old-buffer)))
        (kill-buffer old-buffer))
      (if (and dired-sidebar-follow-file-at-point-on-toggle-open
               file-to-show)
          (if dired-sidebar-pop-to-sidebar-on-toggle-open
              (dired-sidebar-point-at-file file-to-show dir-to-show)
            (with-selected-window (selected-window)
              (dired-sidebar-point-at-file file-to-show dir-to-show)))
        (when dired-sidebar-pop-to-sidebar-on-toggle-open
          (pop-to-buffer (dired-sidebar-buffer))))))))

(use-package dired-subtree
  :bind
  (:map dired-mode-map
	(("TAB" . dired-subtree-toggle))))

(use-package wdired
  :after dired
  :config
  (setq wdired-allow-to-change-permissions t
	wdired-allow-to-redirect-links t))

(provide 'init-dired)
