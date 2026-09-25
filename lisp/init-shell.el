;; -*- lexical-binding: t; -*-

(require 'cl-lib)

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
  :custom
  (comint-use-prompt-regexp t)
  :init
  (defun my-shell-highlight-multiline-prompt (_string)
    "Highlight a two-line Bash prompt in `shell-mode'."
    (when-let ((proc (get-buffer-process (current-buffer))))
      (let ((start comint-last-output-start)
            (end (process-mark proc))
            (inhibit-read-only t)
            beg match-end)
	(when (and start end)
          (save-excursion
            (goto-char start)
            ;; Match prompt inside the latest process output only.
            (while (re-search-forward
                    "^[^ \n]+@[^ \n]+ [^\n]*\n[$#] "
                    end t)
              (setq beg (match-beginning 0)
                    match-end (match-end 0)))

            ;; Only face it if the prompt reaches process-mark.
            (when (and beg (= match-end (marker-position end)))
              (font-lock-append-text-property
               beg match-end
               'font-lock-face
               'comint-highlight-prompt)))))))

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

  (defun od/project-shell-buffer-name (&optional directory)
    "Return the stable project shell name for DIRECTORY.
Include the remote user and host when DIRECTORY is a TRAMP path."
    (let ((default-directory (or directory default-directory)))
      (project-prefixed-buffer-name
       (if (tramp-tramp-file-p default-directory)
	   (with-parsed-tramp-file-name default-directory file
	     (format "shell - %s@%s"
		     (or file-user (user-login-name)) file-host))
	 "shell"))))

  (defun od/project-shell-with-remote-hostname (project-shell &rest args)
    "Call PROJECT-SHELL with a stable, host-qualified remote buffer name."
    (let* ((project-prefixed-buffer-name-original
	    (symbol-function 'project-prefixed-buffer-name))
	   (remote-shell-name
	    (when (tramp-tramp-file-p default-directory)
	      (od/project-shell-buffer-name
	       (project-root (project-current t))))))
      (cl-letf (((symbol-function 'project-prefixed-buffer-name)
		 (lambda (name)
		   (if (and (equal name "shell") remote-shell-name)
		       remote-shell-name
		     (funcall project-prefixed-buffer-name-original name)))))
	(apply project-shell args))))

  (defun od/set-shell-buffer-name (args)
    "Force the BUFFER argument of `shell' to include host and user name."
    (let ((shell-process (get-buffer-process (current-buffer))))
      (list (if (and (eq major-mode 'shell-mode) (not shell-process))
		(buffer-name)
	      (generate-new-buffer-name (od/shell-buffer-name default-directory)))
	    (cadr args))))

  ;; (advice-add #'shell :filter-args #'od/set-shell-buffer-name)
  (advice-add #'project-shell :around #'od/project-shell-with-remote-hostname)
  :config
  (add-hook 'shell-mode-hook
            (lambda ()
              ;; Directory tracking via OSC 7.
              (add-hook 'comint-output-filter-functions
			#'comint-osc-process-output
			nil
			t)

              ;; Important: append t, so this runs after OSC handling.
              (add-hook 'comint-output-filter-functions
			#'my-shell-highlight-multiline-prompt
			t
			t)))

  (add-hook 'shell-mode-hook
          '(lambda ()
             (setq-local comint-prompt-regexp
                         "^[^ \n]+@[^ \n]+ [^\n]*\n[$#] ")))
  )

(use-package shell-command-x
  :after (comint shell)
  :config
  (setq shell-command-x-buffer-name-async-format "*shell:%a*"
	shell-command-x-buffer-name-format "*shell:%a*")
  (shell-command-x-mode))

(provide 'init-shell)
