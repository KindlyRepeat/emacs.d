;; -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'json)
(require 'org-element)
(require 'project)
(require 'seq)
(require 'subr-x)

(defface my/dashboard-project-title
  '((t :inherit font-lock-function-name-face))
  "Face for project titles in the dashboard."
  :group 'my/dashboard)

(defface my/dashboard-label
  '((t :inherit font-lock-comment-face))
  "Face for field labels like \"Next:\" and \"Path:\"."
  :group 'my/dashboard)

(defface my/dashboard-next
  '((t :inherit default))
  "Face for project next-action text in the dashboard."
  :group 'my/dashboard)

(defface my/dashboard-path
  '((t :inherit shadow))
  "Face for project paths in the dashboard."
  :group 'my/dashboard)

(defface my/dashboard-todo-today
  '((t :inherit success :weight bold))
  "Face for todoman entries due today."
  :group 'my/dashboard)

(defface my/dashboard-todo-overdue
  '((t :inherit error :weight bold))
  "Face for overdue todoman entries."
  :group 'my/dashboard)

(defface my/dashboard-todo-future
  '((t :inherit font-lock-doc-face))
  "Face for future todoman due dates."
  :group 'my/dashboard)

(defun my/org-first-next-heading (tree)
  "Return the first headline text in TREE with the NEXT keyword."
  (catch 'found
    (org-element-map tree 'headline
      (lambda (hl)
        (when (equal (org-element-property :todo-keyword hl) "NEXT")
          (throw 'found (org-element-property :raw-value hl)))))
    nil))

(defun my/project-info (root)
  "Extract dashboard info from PROJECT.org in ROOT."
  (let ((file (expand-file-name "PROJECT.org" root)))
    (when (file-exists-p file)
      (with-temp-buffer
	(insert-file-contents file)
	(org-mode)
	(let* ((tree (org-element-parse-buffer))
	       (todos 0))
	  (org-element-map tree 'headline
	    (lambda (hl)
	      (when (eq (org-element-property :todo-type hl) 'todo)
		(cl-incf todos))))
	  (list :name   (file-name-nondirectory (directory-file-name root))
		:root   root
		:next   (or (my/org-first-next-heading tree) "")
		:todos  todos))))))

(require 'magit-section)

(defvar-keymap my/dashboard-mode-map
  :parent magit-section-mode-map
  "RET" #'my/dashboard-visit
  "g"   #'my/dashboard-refresh)

(define-derived-mode my/dashboard-mode magit-section-mode "Projects"
  "Dashboard of active projects.")

(defun my/dashboard-insert-header ()
  "Insert title and optional logo."
  (when (display-graphic-p)
    (let ((img (expand-file-name "logo.png" user-emacs-directory)))
      (when (file-exists-p img)
	(insert-image (create-image img))
	(insert "\n\n"))))
  (insert (propertize "Project Dashboard\n\n"
		      'font-lock-face 'org-document-title)))

(defun my/dashboard-insert-project (info)
  "Insert one collapsible section for project INFO."
  (magit-insert-section (project (plist-get info :root))
    (magit-insert-heading
      (format "%-20s  %s TODO"
	      (propertize (plist-get info :name) 'font-lock-face 'magit-section-heading)
	      (plist-get info :todos)))
    (insert (propertize "  Next: " 'font-lock-face 'my/dashboard-label)
            (propertize (plist-get info :next) 'font-lock-face 'my/dashboard-next)
            "\n")
    (insert (propertize "  Path:   " 'font-lock-face 'my/dashboard-label)
            (propertize (plist-get info :root) 'font-lock-face 'my/dashboard-path)
            "\n")
    (insert ?\n)))

(defun my/todoman-list ()
  "Return todoman tasks as a list of alists."
  (let ((output
         (with-temp-buffer
           (unless (zerop
                    (call-process
                     "todo" nil t nil
                     "--porcelain" "list"))
             (error "todo failed: %s" (string-trim (buffer-string))))
           (buffer-string))))
    (json-parse-string output
                       :array-type 'list
                       :object-type 'alist
                       :null-object nil
                       :false-object nil)))

(defun my/todoman-due-time (task)
  "Return TASK's due time, or nil."
  (when-let* ((due (alist-get 'due task)))
    (ignore-errors
      (cond
       ((numberp due)
        (seconds-to-time due))
       ((and (stringp due)
             (string-match-p "\\`[0-9]+\\'" due))
        (seconds-to-time (string-to-number due)))
       ((stringp due)
        (date-to-time due))))))

(defun my/todoman-day-number (time)
  "Return local calendar day number for TIME."
  (pcase-let ((`(,_sec ,_min ,_hour ,day ,month ,year . ,_)
               (decode-time time)))
    (time-to-days (encode-time 0 0 0 day month year))))

(defun my/todoman-format-due (task)
  "Return TASK's due time as a propertized readable string."
  (when-let* ((due-time (my/todoman-due-time task)))
    (let* ((today (my/todoman-day-number (current-time)))
           (due-day (my/todoman-day-number due-time))
           (days-difference (- due-day today)))
      (cond
       ((zerop days-difference)
        (propertize "Today" 'font-lock-face 'my/dashboard-todo-today))
       ((< days-difference 0)
        (let ((days-ago (abs days-difference)))
          (propertize (format "%d %s ago"
                              days-ago
                              (if (= days-ago 1) "day" "days"))
                      'font-lock-face 'my/dashboard-todo-overdue)))
       (t
        (propertize (format-time-string "%b %-d" due-time)
                    'font-lock-face 'my/dashboard-todo-future))))))

(defun my/todoman-insert-due (task width)
  "Insert TASK's due date padded to WIDTH columns."
  (let* ((due (or (my/todoman-format-due task) ""))
         (due-width (string-width due)))
    (insert due)
    (insert (make-string (max 1 (- width due-width)) ?\s))))

(defun my/todoman-due-soon-p (task)
  "Return non-nil if TASK is overdue or due within the next 7 days."
  (when-let* ((due-time (my/todoman-due-time task)))
    (let ((week-from-now (time-add (current-time) (days-to-time 7))))
      (and (not (alist-get 'completed task))
           (time-less-p due-time week-from-now)))))

(defun my/todoman-due-soon-list ()
  "Return incomplete tasks overdue or due within the next 7 days.
The list is sorted from most overdue to farthest future due date."
  (seq-sort (lambda (a b)
              (time-less-p (my/todoman-due-time a)
                           (my/todoman-due-time b)))
            (seq-filter #'my/todoman-due-soon-p
                        (my/todoman-list))))

(defun my/insert-todoman-section ()
  (magit-insert-section (todoman)
    (magit-insert-heading "Todos")
    (dolist (task (my/todoman-due-soon-list))
      (magit-insert-section (todoman-task task)
        (my/todoman-insert-due task 16)
        (insert (alist-get 'summary task) "\n")))))

(defun my/dashboard-refresh ()
  "Render the whole dashboard buffer."
  (interactive)
  (let ((inhibit-read-only t)
        (projects '()))
    (erase-buffer)
    (magit-insert-section (dashboard)
      (magit-insert-heading
        (concat (propertize "Project Dashboard\n" 'font-lock-face 'org-document-title) "\n"))
      (dolist (root (project-known-project-roots))
        (when-let* ((info (my/project-info root)))
          (push info projects)
          (my/dashboard-insert-project info)))
      ;; store the list of project infos as the section value
      (oset (magit-current-section) value (nreverse projects)))
    (my/insert-todoman-section)
    (goto-char (point-min))))

(defun my/dashboard-visit ()
  "Visit the project at point."
  (interactive)
  (when-let* ((section (magit-current-section))
	      (root (oref section value))
	      ((stringp root)))
    (project-switch-project root)))

(defun my/dashboard ()
  "Show the projects dashboard."
  (interactive)
  (let ((buf (get-buffer-create "*Projects dashboard*")))
    (with-current-buffer buf
      (my/dashboard-mode)
      (my/dashboard-refresh))
    (switch-to-buffer buf)))

(provide 'init-dashboard)
