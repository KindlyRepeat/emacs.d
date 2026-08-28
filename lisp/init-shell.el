;; -*- lexical-binding: t; -*-

(use-package eat
  :disabled t
  :hook ((eshell-load . eat-eshell-mode)
	 (eshell-load . eat-eshell-visual-command-mode))
  :bind
  (("M-&" . od/async-eat-command))
  :config
  (defun od/async-eat-command (command)
    "Like `async-shell-command' but uses `eat'."
    (interactive
     (list
      ;; This is shamelessly taken from `async-shell-command'.
      (read-shell-command (if shell-command-prompt-show-cwd
                              (format-message "Async shell command in `%s': "
                                              (abbreviate-file-name
                                               default-directory))
                            "Async shell command: ")
                          nil nil
			  (let ((filename
				 (cond
				  (buffer-file-name)
				  ((eq major-mode 'dired-mode)
				   (dired-get-filename nil t)))))
			    (and filename (file-relative-name filename))))))
    (let* ((process-environment (cons "PAGER=cat" process-environment))
	   (buffer (eat command t)))
      (with-current-buffer buffer
	;; (beginning-of-buffer)
	(rename-buffer (concat "*eat:" command "*"))))))

(use-package em-hist
  :bind
  (:map eshell-hist-mode-map
	(("M-r" . consult-history))))

(use-package eshell
  :commands (eshell)
  :init
  (defun eshell-here ()
    "Opens up a new shell in the directory associated with the
current buffer's file. The eshell is renamed to match that
directory to make multiple eshell windows easier."
    (interactive)
    (let* ((parent (if (buffer-file-name)
                       (file-name-directory (buffer-file-name))
                     default-directory))
           (height (/ (frame-height) 3))
           (name   (car (last (split-string parent "/" t))))
	   (window (split-window-vertically (- height))))

      (other-window 1)
      (eshell "new")
      (rename-buffer (concat "*eshell: " name "*"))

      (insert (concat "ls"))
      (eshell-send-input)

      (with-selected-window window
	(set-window-dedicated-p window t)))))

(use-package eshell-toggle
  :commands (eshell-toggle)
  :custom
  (eshell-toggle-size-fraction 3)
  (eshell-toggle-use-projectile-root nil)
  (eshell-toggle-run-command nil)
  ;; (eshell-toggle-init-function #'eshell-toggle-init-ansi-term)
  )

(use-package shell
  :hook (shell-mode . (lambda ()
			(setq-local bookmark-make-record-function
				    #'shell-bookmark--make-record)))
  :init
  (defun shell-bookmark--make-record ()
    "Create a shell bookmark.
The bookmark will try to open a shell session with the pwd set
to the location when the bookmark was created."
    (let ((bookmark `((handler . shell-bookmark--restore)
                      (filename . ,default-directory))))
      bookmark))

  (defun shell-bookmark--restore (bookmark)
    "Restore shell buffer according to BOOKMARK."
    (let ((shell-buffer-name (buffer-name))
	  (default-directory (alist-get 'filename bookmark)))
      (shell)))

  (defun od/shell-buffer-name (current-dir)
    "Name of the buffer for inferior shells."
    (concat "*shell - "
	    (if (tramp-tramp-file-p current-dir)
		(with-parsed-tramp-file-name current-dir file (concat file-user "@" file-host))
	      (concat (user-login-name) "@" (system-name)))
	    "*"))

  (defun od/set-shell-buffer-name (args)
    "Force the BUFFER argument of `shell' to include host and user name."
    (let ((shell-process (get-buffer-process (current-buffer))))
      (list (if (and (eq major-mode 'shell-mode) (not shell-process))
		(buffer-name)
	      (generate-new-buffer-name (od/shell-buffer-name default-directory)))
	    (cadr args))))

  (advice-add #'shell :filter-args #'od/set-shell-buffer-name))

(use-package shell-command-x
  :after (comint shell)
  :config
  (setq shell-command-x-buffer-name-async-format "*shell:%a*"
	shell-command-x-buffer-name-format "*shell:%a*")
  (shell-command-x-mode))

(provide 'init-shell)
