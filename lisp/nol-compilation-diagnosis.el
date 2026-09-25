;;; nol-compilation-diagnosis.el --- Diagnose failed builds with gptel -*- lexical-binding: t; -*-

(require 'compile)
(require 'project)
(require 'cl-lib)

(defvar-local nol/compilation-diagnosis-failed nil
  "Non-nil if this compilation buffer's last run failed.")

(defun nol/compilation-diagnosis-finish (buffer status)
  "Offer diagnosis in compilation BUFFER if STATUS reports a failure."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (setq nol/compilation-diagnosis-failed
            (and (stringp status)
                 (string-match-p "exited abnormally" status)))
      (when nol/compilation-diagnosis-failed
        (let ((key
               (read-key
                (format "Compilation failed. Press %s to invoke LLM diagnosis; any other key dismisses this message."
                        (propertize "RET" 'face 'help-key-binding)))))
          (message nil)
          (when (memq key '(return kp-enter ?\n ?\r))
            (call-interactively #'nol/compilation-diagnose)))))))

(defun nol/compilation-diagnosis--path (root path kind)
  "Resolve PATH inside ROOT, requiring KIND to be `file' or `directory'."
  (unless (and (stringp path) (not (file-remote-p path))
               (not (file-name-absolute-p path)))
    (error "Expected a relative local path"))
  (let* ((candidate (expand-file-name path root))
         (resolved (file-truename candidate)))
    (unless (or (equal (directory-file-name resolved)
                       (directory-file-name root))
                (file-in-directory-p resolved root))
      (error "Path escapes compilation project: %s" path))
    (unless (pcase kind
              ('directory (file-directory-p resolved))
              ('file (file-regular-p resolved)))
      (error "Not a readable %s: %s" kind path))
    resolved))

(defun nol/compilation-diagnosis-tools (root)
  "Return only read-only gptel tools confined to ROOT."
  (require 'gptel)
  (when (file-remote-p root) (user-error "Remote projects are not supported"))
  (let ((root (file-name-as-directory (file-truename root))))
    (list
     (gptel-make-tool
      :name "list_project_directory"
      :description "List up to 100 entries in a directory under the compilation project. Pass a relative path, or . for project root."
      :args '((:name "path" :type string :description "Relative directory path, or ."))
      :function (lambda (path)
                  (let* ((dir (nol/compilation-diagnosis--path root path 'directory))
                         (entries (directory-files dir nil directory-files-no-dot-files-regexp)))
                    (mapconcat #'identity (cl-subseq entries 0 (min 100 (length entries))) "\n")))
      :confirm nil :category "compilation-diagnosis")
     (gptel-make-tool
      :name "read_project_file"
      :description "Read at most 12000 bytes of a regular file under the compilation project. Pass a relative path. Read-only."
      :args '((:name "path" :type string :description "Relative file path"))
      :function (lambda (path)
                  (let ((file (nol/compilation-diagnosis--path root path 'file)))
                    (with-temp-buffer
                      (insert-file-contents file nil 0 12000)
                      (buffer-string))))
      :confirm nil :category "compilation-diagnosis"))))

(defun nol/compilation-diagnose ()
  "Immediately diagnose this failed compilation with project-scoped gptel tools."
  (interactive)
  (unless (or (derived-mode-p 'compilation-mode)
	      (member 'compilation-shell-minor-mode local-minor-modes))
    (user-error "Run this from a compilation buffer"))
  (unless nol/compilation-diagnosis-failed
    (user-error "This compilation did not fail"))
  (let* ((project (project-current nil default-directory))
         (root (if project (project-root project) default-directory))
         (output (buffer-substring-no-properties (point-min) (point-max)))
         (command (or (car-safe compilation-arguments) compile-command)))
    (when (file-remote-p root) (user-error "Remote projects are not supported"))
    (let ((tools (nol/compilation-diagnosis-tools root))
          (chat (gptel (generate-new-buffer-name "*gptel: compilation diagnosis*") nil
                       (format "Diagnose this failed compilation. Explain the likely cause and suggest a fix. Use the scoped, read-only tools to inspect relevant files as needed.\nProject root: %s\nCommand: %s\nCompilation output:\n%s"
                               root command output))))
      (with-current-buffer chat
        (setq default-directory (file-name-as-directory (file-truename root)))
        ;; Do not inherit globally enabled tools (including write/shell/MCP tools).
        (setq-local gptel-tools tools)
        (setq-local gptel-use-tools t)
        (goto-char (point-max))
        (gptel-send))
      (display-buffer chat))))

(define-key compilation-shell-minor-mode-map (kbd "C-c C-d") #'nol/compilation-diagnose)
(add-hook 'compilation-finish-functions #'nol/compilation-diagnosis-finish)

(provide 'nol-compilation-diagnosis)
;;; nol-compilation-diagnosis.el ends here
