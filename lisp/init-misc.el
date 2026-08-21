;; -*- lexical-binding: t; -*-

;; for QMK
(defun nol/centered-identifier (text)
  "Prompt for TEXT and insert it centered between underscores to a total length of 43."
  (interactive "sIdentifier: ")
  (let* ((pad-length (- 43 (length text)))
         (left (make-string (/ pad-length 2) ?_))
         (right (make-string (- pad-length (/ pad-length 2)) ?_)))
    (insert (concat left text right))))

(defun tts-send ()
  "Send the active region or prompted text to a TTS script for speech synthesis."
  (interactive)
  (let* ((script "~/dotfiles/scripts/bin/tts")
         (text (if (use-region-p)
                   (buffer-substring-no-properties (region-beginning) (region-end))
                 (read-string "Text for TTS: "))))
    (unless (file-executable-p script)
      (error "Script not found or not executable: %s" script))
    ;; Send text to the script via stdin
    (let ((process
           (make-process
            :name "tts-process"
            :buffer "*tts*"
            :command (list script)
            :connection-type 'pipe)))
      (process-send-string process text)
      (process-send-eof process)
      (message "Sent text to TTS process"))))

;; This is an attempt to improve base16 themes contrast.
;; TODO: Move somewhere more appropriate
(defun nol/base16-theme-with-contrast-min (colors pairs contrast-ratio)
  "Return a modified version of COLORS where foreground/background PAIRS have
a minimum CONTRAST-RATIO."
  (let ((new-colors (copy-sequence colors))) ; Make sure we return a copy of colors to avoid side-effects
    (cl-loop for (fg-key bg-key) in pairs
	     for fg = (plist-get new-colors fg-key)
	     for bg = (plist-get new-colors bg-key)
	     do (plist-put new-colors fg-key (ct-contrast-min fg bg contrast-ratio)))
    new-colors))

;;; Speech to text
(defvar stt-executable "~/dotfiles/scripts/bin/stt")

(defun stt-begin ()
  "Begin stt recording."
  (interactive)
  (call-process-shell-command (concat stt-executable " begin &")))

(defun stt-cancel ()
  "Cancel stt recording."
  (interactive)
  (call-process-shell-command (concat stt-executable " cancel")))

(defun stt-end ()
  "End stt recording."
  (interactive)
  (let* ((raw (shell-command-to-string (concat stt-executable " end")))
	 (processed (string-trim raw)))
    (insert processed)))

;; TODO : Find keybindings that I won't accidently fire.
;; (keymap-global-set "<insert>" 'stt-begin)
;; (keymap-global-set "<delete>" 'stt-cancel)
;; (keymap-global-set "<end>" 'stt-end)

;; (nol/base16-theme-with-contrast-min base16-nord-light-theme-colors '((:base00 :base01)) 3.0)

(defun nol/base16-theme--format-line (base-key other-keys colors)
  "Given a plist of COLORS, return a list where BASE-KEY is formatted as the
first element of a line's table and the rest is the colors given by OTHER-KEYS in COLORS."
  (let ((base-color (plist-get colors base-key)))
    (append
     (list (format "%s (%s)" base-key base-color))
     (cl-loop for key in other-keys
	      collect (format "%.2f" (ct-contrast-ratio base-color (plist-get colors key)))))))

(defun nol/base16-ratio-contrast-table (colors)
  "Insert the table of ratios at point."

  (let* ((base00 (plist-get colors :base00))
	 (base01 (plist-get colors :base01))
	 (base02 (plist-get colors :base02))
	 (other-keys '(:base03 :base04 :base05 :base06
			       :base07 :base08 :base09 :base0A
			       :base0B :base0C :base0D :base0E :base0F))
	 (rest (seq-drop colors 6))	; 6 = 3 properties and their value
	 (data `(,(append '(nil)
			  (cl-loop for (k v) on rest by #'cddr
				   collect (format "%S (%S)" k v)))
		 ,(nol/base16-theme--format-line :base00 other-keys colors)
		 ,(nol/base16-theme--format-line :base01 other-keys colors)
		 ,(nol/base16-theme--format-line :base02 other-keys colors)
		 ))
	 (params '(:lstart "| " :sep " | " :lend " |" :hline "-")))
    (newline)
    (newline)
    (insert (orgtbl-to-orgtbl data params))
    (org-table-align)))

(defun nol/mark-outside-pairs (&optional arg)
  (interactive "p")
  (backward-up-list arg (point) (point))
  (mark-sexp))

(defun nol/exwm-aware-yank ()
  "Like `yank' but also work if the current window is an EXWM managed window."
  (interactive)
  (if (bound-and-true-p exwm-class-name)
      (exwm-input--fake-key ?\C-v)
    (yank)))

(defun nol/kill-line-and-yank ()
  "An sample use case would be in shell buffer where there's a command
written at the prompt. Use this command to replace the current command
by what's in the kill ring"
  (interactive)
  (progn
    (kill-line)
    (yank 2)))

(defun list-of-plist-get (list-of-plist prop value)
  "Given a list of plist, return the plist where prop is equal to value."
  (seq-find (lambda (plist) (equal (plist-get plist prop) value)) list-of-plist))

(defun od/rename-current-buffer-file ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
	(call-interactively 'rename-buffer)
      (let ((new-name (read-file-name "New name: " filename)))
        (if (get-buffer new-name)
            (error "A buffer named '%s' already exists!" new-name)
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil)
          (message "File '%s' successfully renamed to '%s'"
                   name (file-name-nondirectory new-name)))))))

(defun od/delete-current-buffer-file ()
  "Removes file connected to current buffer and kills buffer."
  (interactive)
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        (name (buffer-name)))
    (if (not (and filename (file-exists-p filename)))
        (kill-buffer buffer)
      (when (yes-or-no-p "Are you sure you want to remove this file? ")
        (move-file-to-trash filename)
        (kill-buffer buffer)
        (message "File '%s' successfully removed" filename)))))

(defun od/add-to-load-path (path)
  "Add a directory to `load-path'."
  (interactive "DDirectory to add: ")
  (add-to-list 'load-path path))

(defun od/test-emacs-config ()
  "Launch an instance of Emacs that uses `~/dotfiles/emacs/.config/emacs/' as init file.
Useful for testing purposes before deploying my dotfiles using `guix home reconfigure'."
  (interactive)
  (start-process "Emacs configuration test"
		 "*emacs-config-test*"
		 "emacs"
		 "--debug-init"
		 "--no-desktop"
		 ;; "--init-directory=~/dotfiles/emacs/.config/emacs/"
		 ))

(defun od/dedicate-window (&optional arg)
  "Set current window to be dedicated.
With prefix ARG, undedicate it."
  (interactive "P")
  (set-window-dedicated-p (get-buffer-window (current-buffer)) (not arg))
  (message (if arg
               "Window '%s' is normal"
             "Window '%s' is dedicated")
           (current-buffer)))

(defun od/send-region-to-piper-tts ()
  (interactive)
  (let ((region-string (buffer-substring-no-properties
                        (region-beginning) (region-end)))
	;; This fix some issue about .so libraries missing. Would probably be fixed if
	;; I used pure Guix instead of Python venv.
	(process-environment (cons (concat "LD_LIBRARY_PATH=" (getenv "LIBRARY_PATH"))
				   process-environment))
	;; Otherwise piper-tts.py is confused about its current directory.
	(default-directory "~/src/piper-tts"))
    (start-process "*piper-tts*" "*piper-tts*"
		   "~/src/piper-tts/bin/python"
		   "/home/nic/src/piper-tts/piper-tts.py" region-string)))

(use-package ace-window
  :demand t 				; demand it to have the mode-line indicator at startup
  :bind
  (("M-o" . ace-window))
  :config
  ;; Make sure I can go back to the previous window configuration.
  (advice-add 'ace-delete-window :before 'winner-save-unconditionally)
  (advice-add 'ace-delete-other-windows :before 'winner-save-unconditionally)

  ;; Change aw-show-dispatch-help from 63 (?) to 8 (h, and C-h by extension)
  (setq aw-dispatch-alist
	'((120 aw-delete-window "Delete Window")
	  (109 aw-swap-window "Swap Windows")
	  (77 aw-move-window "Move Window")
	  (99 aw-copy-window "Copy Window")
	  (106 aw-switch-buffer-in-window "Select Buffer")
	  (110 aw-flip-window)
	  (117 aw-switch-buffer-other-window "Switch Buffer Other Window")
	  (101 aw-execute-command-other-window "Execute Command Other Window")
	  (70 aw-split-window-fair "Split Fair Window")
	  (118 aw-split-window-vert "Split Vert Window")
	  (98 aw-split-window-horz "Split Horz Window")
	  (111 delete-other-windows "Delete Other Windows")
	  (84 aw-transpose-frame "Transpose Frame")
	  (8 aw-show-dispatch-help)))

  (when (bound-and-true-p exwm--root)
    (exwm-input-set-key (kbd "M-o") 'ace-window))
  (setq aw-background t
	aw-dispatch-always t
	aw-display-mode-overlay nil
	aw-keys '(?m ?n ?e ?i ?k ?h ?, ?.))
  (ace-window-display-mode))

;; Default configuration copied from (info "(activities) Configuration")
(use-package activities
  :init
  (activities-mode)
  (activities-tabs-mode)
  ;; Prevent `edebug' default bindings from interfering.
  (setq edebug-inhibit-emacs-lisp-mode-bindings t)

  :bind
  (("C-x C-a C-n" . activities-new)
   ("C-x C-a C-d" . activities-define)
   ("C-x C-a C-a" . activities-resume)
   ("C-x C-a C-s" . activities-suspend)
   ("C-x C-a C-k" . activities-kill)
   ("C-x C-a RET" . activities-switch)
   ("C-x C-a b" . activities-switch-buffer)
   ("C-x C-a g" . activities-revert)
   ("C-x C-a l" . activities-list)))

(use-package avy
  :init (global-set-key (kbd "M-i") nil)
  :bind
  (("M-i i" . avy-goto-char-timer)
   ("M-i l" . avy-goto-line))
  (:map isearch-mode-map
	(("M-i" . avy-isearch)))
  (:map dired-mode-map
	(("N" . avy-goto-line-below)
	 ("P" . avy-goto-line-above))))

(use-package awesome-tray
  :custom
  (awesome-tray-separator "   ")
  (awesome-tray-update-interval 1)
  (awesome-tray-date-format "   %A, %B %-d %Y - ")
  (awesome-tray-essential-modules '())
  :custom-face
  (battery-load-critical
   ((t (:foreground "red"))))
  (awesome-tray-default-face ((t :inherit fixed-pitch :weight regular)))
  (awesome-tray-module-date-face ((t :inherit awesome-tray-default-face)))
  (awesome-tray-volume-bluetooth-face
   ((((background dark))
     (:inherit awesome-tray-default-face
      :foreground "DeepSkyBlue"))
    (((background light))
     (:inherit awesome-tray-default-face
      :foreground "RoyalBlue"))))
  :init
    (defvar awesome-tray-cpu-usage-threshold 30
    "Only show CPU usage above this percentage.")
  (defvar awesome-tray-ram-usage-threshold 90
    "Only show RAM usage above this percentage.")
  (defvar awesome-tray-disk-usage-threshold 90
    "Only show disk usage above this percentage.")
  (defvar awesome-tray-network-bitrate-threshold 5.0
    "Only show connected WiFi below this tx bitrate, in Mbit/s.")

  (defun awesome-tray--ordinal-day (day)
    "Return DAY with its English ordinal suffix."
    (format "%d%s" day
            (if (memq (% day 100) '(11 12 13))
                "th"
              (pcase (% day 10)
                (1 "st")
                (2 "nd")
                (3 "rd")
                (_ "th")))))

  (defun awesome-tray-module-pretty-date-info ()
    "Return the current date with an ordinal day."
    (let* ((time (decode-time))
           (day (decoded-time-day time)))
      (format "%s, %s %s %s - %s"
              (format-time-string "%A")
              (format-time-string "%B")
              (awesome-tray--ordinal-day day)
              (format-time-string "%Y")
              (format-time-string "%H:%M"))))

  (defun awesome-tray--wifi-interface ()
    "Return the first wireless interface reported by iw."
    (when (executable-find "iw")
      (let ((output (shell-command-to-string "iw dev 2>/dev/null")))
        (when (string-match "Interface[ \t]+\\([^ \t\n]+\\)" output)
          (match-string 1 output)))))

  (defun awesome-tray--wifi-tx-bitrate (link-output)
    "Return tx bitrate parsed from LINK-OUTPUT, or nil if unavailable."
    (when (string-match "tx bitrate:[ \t]+\\([0-9.]+\\)[ \t]+MBit/s" link-output)
      (string-to-number (match-string 1 link-output))))

  (defun awesome-tray-module-network-info ()
    "Show WiFi only when disconnected or below `awesome-tray-network-bitrate-threshold'."
    (let* ((interface (awesome-tray--wifi-interface))
           (ssid (string-trim (shell-command-to-string "iwgetid -r 2>/dev/null"))))
      (cond
       ((string-empty-p ssid)
        "WiFi:down")
       (interface
        (let* ((link-output
                (shell-command-to-string
                 (format "iw dev %s link 2>/dev/null" (shell-quote-argument interface))))
               (tx-bitrate (awesome-tray--wifi-tx-bitrate link-output)))
          (if (and tx-bitrate
                   (< tx-bitrate awesome-tray-network-bitrate-threshold))
              (format "WiFi:%s %.1fM" ssid tx-bitrate)
            "")))
       (t ""))))

  (defvar awesome-tray--cpu-stat-last-total 0)
  (defvar awesome-tray--cpu-stat-last-idle 0)
  (defvar awesome-tray--cpu-stat-last-update 0)
  (defvar awesome-tray--cpu-usage-cache "")

  (defun awesome-tray--read-cpu-stat ()
    "Read aggregate cpu stat from /proc/stat, return list of numbers."
    (when (file-exists-p "/proc/stat")
      (with-temp-buffer
	(insert-file-contents "/proc/stat")
	(when (looking-at "^cpu\\s-+\\([0-9 ]+\\)")
          (mapcar #'string-to-number (split-string (match-string 1) " " t))))))

  (defun awesome-tray-module-cpu-info ()
    "Show CPU usage (%), computed as running avg since last call."
    (let ((now (float-time)))
      (if (> (- now awesome-tray--cpu-stat-last-update) 1) ; throttle 1s
          (let* ((fields (awesome-tray--read-cpu-stat)))
            (when fields
              (let* ((total (apply #'+ fields))
                     (idle (nth 3 fields))) ; user nice system idle ...
		(unless (zerop (- total awesome-tray--cpu-stat-last-total))
                  (let* ((diff-total (- total awesome-tray--cpu-stat-last-total))
			 (diff-idle (- idle awesome-tray--cpu-stat-last-idle))
			 (usage (/ (* (- diff-total diff-idle) 100.0) diff-total)))
                    (setq awesome-tray--cpu-usage-cache
			  ;; (svg-lib-progress-pie 0.2 nil
			  ;; :margin 1 :stroke 2 :padding 1)
			  ;; (propertize "foo" 'display (svg-lib-progress-pie 0.2 nil
			  ;; :margin 1 :stroke 2 :padding 1))
                          (if (> usage awesome-tray-cpu-usage-threshold)
                              (format "CPU:%.0f%%" usage)
                            "")
			  )))
		(setq awesome-tray--cpu-stat-last-total total)
		(setq awesome-tray--cpu-stat-last-idle idle)
		(setq awesome-tray--cpu-stat-last-update now)))))
      awesome-tray--cpu-usage-cache))

  (defvar awesome-tray-ram-status-last-time 0
    "Last time we updated the RAM status.")
  (defvar awesome-tray-ram-status-cache ""
    "Cached RAM status string.")
  (defvar awesome-tray-ram-update-duration 10
    "How often (in seconds) to refresh RAM info.")

  (defun awesome-tray-get-ram-info ()
    "Return cons cell (TOTAL-KB . USED-KB) parsed from /proc/meminfo."
    (if (file-exists-p "/proc/meminfo")
	(with-temp-buffer
          (insert-file-contents "/proc/meminfo")
          (let ((total 0) (available 0))
            (goto-char (point-min))
            (when (re-search-forward "^MemTotal:[ \t]+\\([0-9]+\\)" nil t)
              (setq total (string-to-number (match-string 1))))
            (goto-char (point-min))
            (when (re-search-forward "^MemAvailable:[ \t]+\\([0-9]+\\)" nil t)
              (setq available (string-to-number (match-string 1))))
            (cons total (- total available))))
      (cons 0 0)))

  (defun awesome-tray-module-ram-info ()
    "Return a string showing current RAM usage percentage."
    (let ((current-seconds (awesome-tray-current-seconds)))
      (if (> (- current-seconds awesome-tray-ram-status-last-time)
             awesome-tray-ram-update-duration)
          (let* ((mem-info (awesome-tray-get-ram-info))
		 (total (car mem-info))
		 (used  (cdr mem-info))
		 (percent (if (> total 0)
                              (* 100.0 (/ (float used) total))
                            0)))
            (setq awesome-tray-ram-status-last-time current-seconds)
            (setq awesome-tray-ram-status-cache
                  (if (> percent awesome-tray-ram-usage-threshold)
                      (format "RAM:%.0f%%" percent)
                    "")))
	awesome-tray-ram-status-cache)))

  (defvar awesome-tray-disk-status-last-time 0
    "Last time we updated the disk status.")
  (defvar awesome-tray-disk-status-cache ""
    "Cached disk status string.")
  (defvar awesome-tray-disk-update-duration 30
    "How often (in seconds) to refresh disk info.")
  (defvar awesome-tray-disk-mount-point "/"
    "Mount point whose usage will be reported.")

  (defun awesome-tray-get-disk-info (mount-point)
    "Return disk usage percentage string for MOUNT-POINT, or nil on failure."
    (when (executable-find "df")
      (let* ((cmd (format "df -Pk %s" (shell-quote-argument mount-point)))
             (output (shell-command-to-string cmd))
             (lines (split-string output "\n" t)))
	(when (>= (length lines) 2)
          (let* ((fields (split-string (nth 1 lines) "[ \t]+" t))
		 ;; df -P columns: FS  1K-blocks  Used  Available  Use%  Mounted
		 (use-percent (nth 4 fields)))
            use-percent)))))

  (defun awesome-tray-module-disk-info ()
    "Return a string showing disk usage for `awesome-tray-disk-mount-point'."
    (let ((current-seconds (awesome-tray-current-seconds)))
      (if (> (- current-seconds awesome-tray-disk-status-last-time)
             awesome-tray-disk-update-duration)
          (let ((usage (awesome-tray-get-disk-info awesome-tray-disk-mount-point)))
            (setq awesome-tray-disk-status-last-time current-seconds)
            (setq awesome-tray-disk-status-cache
                  (if (and usage
                           (> (string-to-number usage)
                              awesome-tray-disk-usage-threshold))
                      (format "DISK:%s" usage)
                    "")))
	awesome-tray-disk-status-cache)))

  (defvar awesome-tray-nextcloud-status-last-time 0
    "Last time when nextcloud status was updated.")
  (defvar awesome-tray-nextcloud-status-cache ""
    "Cache of nextcloud status.")
  (defvar awesome-tray-nextcloud-update-duration 5
    "Update duration for nextcloud status, in seconds.")
  (defvar awesome-tray-nextcloud-sync-dir "~/nc2"
    "Nextcloud sync directory to scan for conflicted files.")

  (defun awesome-tray-module-nextcloud-info ()
    (let ((current-seconds (awesome-tray-current-seconds)))
      (if (> (- current-seconds awesome-tray-nextcloud-status-last-time)
             awesome-tray-nextcloud-update-duration)
          (let* ((nextcloud-running
                  (not (string-empty-p
			(shell-command-to-string "pgrep nextcloud"))))
		 (conflicted-files
                  (string-to-number
                   (shell-command-to-string
                    (format "fd 'conflicted copy' %s | wc -l"
                            (expand-file-name
                             awesome-tray-nextcloud-sync-dir)))))
		 (status
                  (cond ((and nextcloud-running (> conflicted-files 0))
			 (format " (%d!)" conflicted-files))
			(nextcloud-running
			 "")
			(t
			 "󰅤"))))
            (setq awesome-tray-nextcloud-status-last-time current-seconds)
            (setq awesome-tray-nextcloud-status-cache status))
	awesome-tray-nextcloud-status-cache)))

  (defvar awesome-tray-svg-last-time 0
    "Last time ...")
  (defvar awesome-tray-svg-status-cache ""
    "Cache of ... status.")
  (defvar awesome-tray-svg-update-duration 1
    "Update duration for ..., in seconds.")
  (defvar awesome-tray-svg-sizes '(0.5 0.8 1.0)
    "The circle will use these sizes, one at a time")
  (defvar awesome-tray-svg-last-size 1.0
    "Size of the last circle that got displayed")

  (defun nol/next-value (current values)
    (or (cadr (member current values))
	(car values)))

  (defun svg-circle-glyph (size &optional color)
  "Return an SVG image of a circle with relative SIZE (0.0 to 1.0)
sized to match one text character. SIZE is the diameter as a
fraction of the character size. COLOR defaults to foreground."
  (let* ((size (or size 1.0))
         (color (or color (face-attribute 'default :foreground)))
         ;; Character dimensions in pixels
         (char-width  (window-font-width))
         (char-height (window-font-height))
         ;; Use the smaller dimension to keep circle proportional
         (radius (* (/ (min char-width char-height) 2.0) size))
         (cx (/ char-width  2.0))
         (cy (/ char-height 2.0))
         (svg (svg-create char-width char-height)))
    (svg-circle svg cx cy radius :stroke color :stroke-width 2.0 :fill "none")
    (svg-image svg :ascent 'center :scale 1)))

  (defun awesome-tray-module-svg-info ()
    (let ((current-seconds (awesome-tray-current-seconds)))
      (if (> (- current-seconds awesome-tray-svg-last-time)
             awesome-tray-svg-update-duration)
	  (let* ((new-size (nol/next-value awesome-tray-svg-last-size
					   awesome-tray-svg-sizes))
		 (status (propertize " " 'display (svg-circle-glyph new-size "white"))))
	    (setq awesome-tray-svg-last-time current-seconds)
	    (setq awesome-tray-svg-last-size new-size)
	    (setq awesome-tray-svg-status-cache status))
	awesome-tray-svg-status-cache)))

  (defvar awesome-tray-battery-critical-threshold 20
  "Battery percentage below which to use `battery-load-critical' face.")

  (defun awesome-tray-battery-bar (percent)
    "Return a 5-cell battery bar for PERCENT."
    (let* ((p (max 0 (min 100 percent)))
           (filled (ceiling (/ p 20.0)))
           (empty (- 5 filled)))
      (concat
       (make-string filled ?▰)
       (make-string empty ?▱))))

  (defun awesome-tray-battery-maybe-critical (string percent plugged-in)
    "Apply the appropriate face to battery STRING."
    (propertize
     string 'face
     (if (and (not plugged-in)
              (<= percent awesome-tray-battery-critical-threshold))
         '(battery-load-critical awesome-tray-default-face)
       'awesome-tray-default-face)))

  (defun awesome-tray-module-battery-info-v2 ()
    (let ((current-seconds (awesome-tray-current-seconds)))
      (if (> (- current-seconds awesome-tray-battery-status-last-time)
             awesome-tray-battery-update-duration)
          (let* ((battery-info (funcall battery-status-function))
		 (battery-type (battery-format "%L" battery-info))
		 (battery-percent-string (battery-format "%p" battery-info))
		 (battery-percent (string-to-number battery-percent-string))
		 (plugged-in (member battery-type '("on-line" "AC")))
		 (on-battery (member battery-type '("off-line" "BAT" "Battery")))
		 battery-status)
            (setq awesome-tray-battery-status-last-time current-seconds)

            (setq battery-status
                  (cond
                   (plugged-in
                    (format "%s %d%%+"
                            (awesome-tray-battery-bar battery-percent)
                            battery-percent))
                   (on-battery
                    (format "↯ %s %d%%"
                            (awesome-tray-battery-bar battery-percent)
                            battery-percent))
                   (t
                    "")))

            ;; Apply critical face if needed.
            (setq battery-status
                  (awesome-tray-battery-maybe-critical
                   battery-status battery-percent plugged-in))

            ;; Update battery cache.
            (setq awesome-tray-battery-status-cache battery-status))
	awesome-tray-battery-status-cache)))

  (defvar awesome-tray-volume-status-cache ""
  "Cached volume status for awesome-tray.")

  (defvar awesome-tray-volume-status-last-time 0
    "Last time volume status was updated.")

  (defvar awesome-tray-volume-update-duration 5
    "Seconds between volume status updates.")

  (defun awesome-tray-volume-bar (percent)
    "Return a 5-cell volume bar for PERCENT."
    (let* ((p (max 0 (min 100 percent)))
           (filled (ceiling (/ p 20.0)))
           (empty (- 5 filled)))
      (concat
       (make-string filled ?▰)
       (make-string empty ?▱))))

  (defun awesome-tray-volume-format (info)
    "Format volume INFO for awesome-tray."
    (let* ((percent (plist-get info :percent))
           (muted (plist-get info :muted))
           (bluetooth (plist-get info :bluetooth))
           (text
            (if muted
                (format "♪ %s mute"
                        (awesome-tray-volume-bar 0))
              (format "♪ %s %d%%"
                      (awesome-tray-volume-bar percent)
                      percent))))
      (propertize
       text 'face
       (if bluetooth
           'awesome-tray-volume-bluetooth-face
         'awesome-tray-default-face))))

  (defun awesome-tray-volume-refresh ()
    "Force refresh awesome-tray volume cache."
    (interactive)
    (condition-case nil
	(let ((info (awesome-tray-volume-from-pactl)))
          (when info
            (setq awesome-tray-volume-status-cache
                  (awesome-tray-volume-format info))
            (setq awesome-tray-volume-status-last-time
                  (awesome-tray-current-seconds))))
      (error nil))
    (force-mode-line-update t))

  (defun awesome-tray-volume-from-pactl ()
    "Return volume information for the default PulseAudio sink."
    (let* ((sink
            (string-trim
             (car (process-lines "pactl" "get-default-sink"))))
           (volume-output
            (string-join
             (process-lines "pactl" "get-sink-volume" sink)
             " "))
           (mute-output
            (string-join
             (process-lines "pactl" "get-sink-mute" sink)
             " "))
           (muted (string-match-p "yes" mute-output))
           (bluetooth
            (let ((case-fold-search t))
              (string-match-p "bluez" sink))))
      (when (string-match "\\([0-9]+\\)%" volume-output)
        (list :percent
              (string-to-number (match-string 1 volume-output))
              :muted muted
              :bluetooth bluetooth
              :sink sink))))

  (defun awesome-tray-module-volume-info-v2 ()
    "Return volume status for awesome-tray."
    (let ((current-seconds (awesome-tray-current-seconds)))
      (when (> (- current-seconds awesome-tray-volume-status-last-time)
               awesome-tray-volume-update-duration)
	(awesome-tray-volume-refresh))
      awesome-tray-volume-status-cache))

      :config
      (add-to-list 'awesome-tray-module-alist
		   '("network" . (awesome-tray-module-network-info awesome-tray-default-face)))
      (add-to-list 'awesome-tray-module-alist
		   '("cpu" . (awesome-tray-module-cpu-info awesome-tray-default-face)))
      (add-to-list 'awesome-tray-module-alist
		   '("ram-info" . (awesome-tray-module-ram-info awesome-tray-default-face)))
      (add-to-list 'awesome-tray-module-alist
		   '("disk-info" . (awesome-tray-module-disk-info awesome-tray-default-face)))
      (add-to-list 'awesome-tray-module-alist
		   '("nextcloud" . (awesome-tray-module-nextcloud-info awesome-tray-default-face)))
      (add-to-list 'awesome-tray-module-alist
		   '("circle" . (awesome-tray-module-svg-info nil)))
      (add-to-list 'awesome-tray-module-alist
		   '("pretty-date" . (awesome-tray-module-pretty-date-info awesome-tray-default-face)))
      ;; Overwrite default battery module to use default face (and
      ;; battery-load-critical if low battery)
      (add-to-list 'awesome-tray-module-alist
		   '("battery" . (awesome-tray-module-battery-info-v2 nil)))
      ;; Overwrite default volume module. Use pactl directly instead of `volume'
      ;; package.
      (setq awesome-tray-module-alist
	    (assoc-delete-all "volume" awesome-tray-module-alist))
      (add-to-list 'awesome-tray-module-alist
		   '("volume" . (awesome-tray-module-volume-info-v2 nil)))

      (setq awesome-tray-hide-mode-line nil
	    awesome-tray-active-modules '(;; "nextcloud"
					  "disk-info" "ram-info" "cpu" "network"
					  "volume" "battery" "pretty-date"))
      (awesome-tray-mode 1))

(use-package burly
  :disabled t
  :commands (burly-open-bookmark)
  :config
  (burly-tabs-mode))

;; There is an issue with the guix version
;; TODO : Delete if ebib is sufficient
;; (straight-use-package 'citar)
;; (with-eval-after-load 'citar
;;   (require 'denote)
;;   (setq citar-bibliography '("~/nc/zotero/library.bib")
;; 	citar-link-fields '((doi . "https://doi.org/%s")
;; 			    (pmid . "https://www.ncbi.nlm.nih.gov/pubmed/%s")
;; 			    (pmcid . "https://www.ncbi.nlm.nih.gov/pmc/articles/%s")
;; 			    (url . "%s")
;; 			    (howpublished . "%s"))
;; 	citar-notes-paths `(,denote-directory))
;;   ;; Add icons when using commands such as `citar-open'.
;;   (with-eval-after-load 'nerd-icons
;;     (defvar citar-indicator-files-icons
;;       (citar-indicator-create
;;        :symbol (nerd-icons-faicon "nf-fa-file_o" :face 'nerd-icons-green :v-adjust -0.1)
;;        :function #'citar-has-files
;;        :padding "  "			; need this because the default padding is too low for these icons
;;        :tag "has:files"))
;;     (defvar citar-indicator-links-icons
;;       (citar-indicator-create
;;        :symbol (nerd-icons-faicon "nf-fa-link" :face 'nerd-icons-orange :v-adjust 0.01)
;;        :function #'citar-has-links
;;        :padding "  "
;;        :tag "has:links"))
;;     (defvar citar-indicator-notes-icons
;;       (citar-indicator-create
;;        :symbol (nerd-icons-codicon "nf-cod-note" :face 'nerd-icons-blue :v-adjust -0.3)
;;        :function #'citar-has-notes
;;        :padding "    "
;;        :tag "has:notes"))
;;     (defvar citar-indicator-cited-icons
;;       (citar-indicator-create
;;        :symbol (nerd-icons-faicon "nf-fa-circle_o" :face 'nerd-icon-green)
;;        :function #'citar-is-cited
;;        :padding "  "
;;        :tag "is:cited")))
;;   (setq citar-indicators
;; 	(list citar-indicator-files-icons
;;               citar-indicator-links-icons
;;               citar-indicator-notes-icons
;;               citar-indicator-cited-icons)))

;; (straight-use-package 'citar-embark)

;; There is an issue with the guix version
;; (straight-use-package 'citar-denote)
;; (with-eval-after-load 'citar
;;   (require 'citar-denote)
;;   (setq citar-denote-file-type 'org
;;  	citar-notes-paths `(,denote-directory)
;; 	citar-file-note-extensions '("org"))
;;   (citar-denote-mode))

;; (use-package citar
;;   :after denote
;;   :commands (citar-create-note citar-insert-reference)
;;   :init
;;   (defvar citar-indicator-create)
;;   :custom
;;   (citar-bibliography '("~/nc/zotero/library.bib"))
;;   :config
;;   (setq citar-notes-paths `(,denote-directory)))
;; (use-package citar)

(use-package diff-hl
  :demand t
  :config
  (global-diff-hl-mode)
  ;; TODO
  ;; it would seem that this function is not loaded when global-diff-hl-mode is enabled ?
  ;; should probably load the package diff-hl-margin mode
  ;; (diff-hl-margin-mode -1)
  )

(use-package diff-hl			;+magit
  :after magit
  :hook ((magit-pre-refresh . diff-hl-magit-pre-refresh)
	 (magit-post-refresh . diff-hl-magit-post-refresh)))

(use-package direnv
  :if (executable-find "direnv")
  :demand t
  :config
  (direnv-mode 1))

(use-package elisp-demos
  :after helpful
  :config
  (advice-add 'helpful-update :after #'elisp-demos-advice-helpful-update))

(use-package expand-region
  :bind (("C-M-SPC" . er/expand-region)))

(use-package gcmh
  :hook
  (after-init . gcmh-mode)
  :custom
  (gcmh-idle-delay 10)
  :init
  (add-to-list 'mode-line-collapse-minor-modes 'gcmh-mode))

(use-package geiser
  :config

  (defun od/sudo-guix-repl ()
    (interactive)
    (let ((geiser-guile-binary "/home/nic/dotfiles/scripts/bin/sudo-guix-repl"))
      (geiser 'guile))))

(use-package god-mode
  :disabled t
  :demand t
  :config
  (setq god-mode-alist '((nil . "C-")
			 ("m" . "M-")
			 ("," . "C-M-")))

  (global-set-key (kbd "<escape>") #'god-local-mode)
  (define-key god-local-mode-map (kbd "i") #'god-local-mode)
  (define-key god-local-mode-map (kbd ".") #'repeat)

  (defun my-god-mode-update-mode-line ()
    "Make `mode-line' blue if God local mode is active."
    (modus-themes-with-colors
      (if god-local-mode
          (set-face-attribute 'mode-line nil
                              :foreground fg-main
                              :background fg-special-mild
                              :box fg-alt)
	(set-face-attribute 'mode-line nil
                            :foreground bg-main
                            :background blue-active
                            :box fg-alt))))

  (add-hook 'post-command-hook 'my-god-mode-update-mode-line)
  (god-mode))

(use-package help
  :hook
  (help-mode . (lambda () (toggle-truncate-lines -1)))
  :custom
  (help-window-select t)
  (help-enable-variable-value-editing t)
  :config
  (add-to-list 'display-buffer-alist
	       '("\\*Help\\*"
		 (display-buffer-reuse-mode-window)
		 (inhibit-same-window . t))))

(use-package helpful
  :disabled t
  :after window				; For `od/display-buffer-in-side-window'
  :demand t
  :bind (([remap describe-function] . helpful-callable)
	 ([remap describe-variable] . helpful-variable)
	 ([remap describe-symbol] . helpful-symbol)
	 ([remap describe-key] . helpful-key)
	 ("C-h ." . helpful-at-point))
  (:map helpful-mode-map
	("s" . od/helpful-goto-source))
  :hook
  (helpful-mode . (lambda () (toggle-truncate-lines -1)))
  ;;:hook
  ;; (helpful-mode . (lambda () (text-scale-decrease 1)))
  :init
  (defun od/helpful-goto-source ()
    (interactive)
    (xref-find-definitions (symbol-name helpful--sym)))
  :config
  (setq helpful-max-buffers 10
	helpful-switch-buffer-function 'display-buffer) ; This is so useful with `embark-act-noquit'.

  (add-to-list 'display-buffer-alist
	       '("\\*helpful.*\\*"
		 (display-buffer-reuse-mode-window)
		 (inhibit-same-window . t))))

(use-package hide-mode-line
  :bind (("C-x x h" . hide-mode-line-mode)))

(use-package inspector
  :init
  ;; doesn't work
  ;; (add-to-list 'display-buffer-alist '("*inspector*"
  ;; 				       (display-buffer-reuse-window)))
  :config
  (defun od/eval-last-sexp (arg)
    (interactive "P")
    (cond (arg (call-interactively 'inspector-inspect-last-sexp))
	  ((fboundp 'eros-eval-last-sexp) (call-interactively 'eros-eval-last-sexp))
	  (t (call-interactively 'eval-last-sexp))))

  (defun od/eval-expression (arg)
    (interactive "P")
    (cond (arg (call-interactively 'inspector-inspect-expression))
	  (t (call-interactively 'eval-expression))))
  :bind
  (("C-x C-e" . od/eval-last-sexp)
   ("M-:" . od/eval-expression)))

(use-package jinx
  :disabled nil 				; TODO: fixme, broken in Guix
  :if (string= system-name "perfidy")
  :hook ((text-mode . jinx-mode))
  :bind (("M-$" . jinx-correct))
  :config
  (setq jinx-languages "en_US fr_FR"))
;; (unless (executable-find "guix")
;;   (straight-use-package
;;    '(jinx :type git :host github :repo "minad/jinx")))
;; (add-hook 'text-mode-hook 'jinx-mode)
;; (with-eval-after-load 'jinx
;;   (setq jinx-languages "en_US fr_FR")
;;   (bind-keys ("M-$" . jinx-correct)))

(use-package meow
  :disabled t
  :demand t
  :bind
  (("C-h C-f" . helpful-function)
   ("C-h C-v" . helpful-variable)
   ("C-h C-k" . meow-describe-key)
   ("C-h C-o" . helpful-symbol)
   ("C-x C-0" . delete-window)
   (:map dired-mode-map
	 (("a" . dired-mark))))
  :config
  (defvar od/windmove-map
    (let ((map (make-keymap)))
      (define-key map (kbd "m") 'windmove-left)
      (define-key map (kbd "n") 'windmove-down)
      (define-key map (kbd "e") 'windmove-up)
      (define-key map (kbd "i") 'windmove-right)
      map))
  (defalias 'od/windmove-map od/windmove-map)

  (setq meow-cheatsheet-layout meow-cheatsheet-layout-colemak-dh
	meow-use-clipboard t)

  ;;(meow-setup-indicator)

  (meow-motion-overwrite-define-key
   ;; Use e to move up, n to move down.
   ;; Since special modes usually use n to move down, we only overwrite e here.
   '("m" . meow-left)
   '("e" . meow-prev)
   '("n" . meow-next)
   '("i" . meow-right)
   '("'" . repeat)
   '("<escape>" . ignore))

  (meow-leader-define-key
   '("?" . meow-cheatsheet)
   '("b" . consult-buffer)
   '("f" . find-file)
   '("k" . kill-buffer)
   '("K" . kill-buffer-and-window)
   (cons "t" tab-prefix-map)
   (cons "w" 'od/windmove-map) ;; Add the quote for name instead of `+prefix'
   (cons "4" ctl-x-4-map)
   ;; To execute the originally e in MOTION state, use SPC e.
   '("e" . "H-e")
   '("1" . meow-digit-argument)
   '("2" . meow-digit-argument)
   '("3" . meow-digit-argument)
   ;;'("4" . meow-digit-argument)
   '("5" . meow-digit-argument)
   '("6" . meow-digit-argument)
   '("7" . meow-digit-argument)
   '("8" . meow-digit-argument)
   '("9" . meow-digit-argument)
   '("0" . meow-digit-argument))

  (meow-normal-define-key
   '("0" . meow-expand-0)
   '("1" . meow-expand-1)
   '("2" . meow-expand-2)
   '("3" . meow-expand-3)
   '("4" . meow-expand-4)
   '("5" . meow-expand-5)
   '("6" . meow-expand-6)
   '("7" . meow-expand-7)
   '("8" . meow-expand-8)
   '("9" . meow-expand-9)
   '("-" . negative-argument)
   '(";" . meow-reverse)
   '("," . meow-inner-of-thing)
   '("." . meow-bounds-of-thing)
   '("[" . meow-beginning-of-thing)
   '("]" . meow-end-of-thing)
   '("/" . meow-visit)
   '("a" . meow-append)
   '("A" . meow-open-below)
   '("b" . meow-back-word)
   '("B" . meow-back-symbol)
   '("c" . meow-change)
   '("d" . meow-delete)
   '("e" . meow-prev)
   '("E" . meow-prev-expand)
   '("f" . meow-find)
   '("g" . meow-cancel-selection)
   '("G" . meow-grab)
   '("m" . meow-left)
   '("M" . meow-left-expand)
   '("i" . meow-right)
   '("I" . meow-right-expand)
   '("j" . meow-join)
   '("k" . meow-kill)
   '("l" . meow-line)
   '("L" . meow-goto-line)
   '("h" . meow-mark-word)
   '("H" . meow-mark-symbol)
   '("n" . meow-next)
   '("N" . meow-next-expand)
   '("o" . meow-block)
   '("O" . meow-to-block)
   '("p" . meow-yank)
   '("q" . meow-quit)
   '("r" . meow-replace)
   '("s" . meow-insert)
   '("S" . meow-open-above)
   '("t" . meow-till)
   '("u" . meow-undo)
   '("U" . meow-undo-in-selection)
   '("v" . meow-search)
   '("w" . meow-next-word)
   '("W" . meow-next-symbol)
   '("x" . meow-delete)
   '("X" . meow-backward-delete)
   '("y" . meow-save)
   '("z" . meow-pop-selection)
   '("'" . repeat)
   '("<escape>" . ignore))

  (defface meow-insert-hl-line
    '((t :inherit modus-themes-subtle-magenta
	 :underline t
	 ))
    "Face for function parameters."
    :group 'meow)
  (defface meow-normal-hl-line
    '((t :inherit modus-themes-subtle-blue
	 :underline t
	 ))
    "Face for function parameters."
    :group 'meow)

  (require 'hl-line)
  (defun od/set-hl-line-face-insert-state ()
    (when hl-line-mode
      (hl-line-mode -1)))

  (defun od/set-hl-line-face-normal-state ()
    (setq hl-line-face 'meow-normal-hl-line)
    (hl-line-mode 1))

  (add-hook 'meow-insert-enter-hook 'od/set-hl-line-face-insert-state)
  (add-hook 'meow-normal-mode-hook 'od/set-hl-line-face-normal-state)

  ;;(global-hl-line-mode 1)
  (add-hook 'text-mode-hook 'hl-line-mode)
  (add-hook 'prog-mode-hook 'hl-line-mode)

  (meow-global-mode)

  ;; (meow-define-keys
  ;;     ;; state
  ;;     'keypad

  ;;   ;; bind to a command
  ;;   '("b" . switch-to-buffer)

  ;;   ;; bind to a keymap
  ;;   (cons "t" tab-prefix-map))
  )

(use-package magit
  :bind
  ("C-x g" . magit-status)
  :init
  ;; Fontify symbols starting with ` and ending with ' such as `foo'.
  (font-lock-add-keywords 'magit-log-mode
                          '(("`\\([^\']*\\)'"
                             1 'Info-quoted prepend))))

;; Load `magit-extras' when `project.el' is loaded to have the magit status command available
;; TODO: fix me, the startup is so slow
(use-package magit-extras
  :after project
  :config
  ;; This code was adapted from `magit-bind-magit-project-status' in `magit-extras.el'.
  ;; Add Magit to `project-switch-commands' even if it has been modified.
  (when (and (boundp 'project-prefix-map)
	     (boundp 'project-switch-commands))
    (keymap-set project-prefix-map "m" #'magit-project-status)
    (add-to-list 'project-switch-commands '(magit-project-status "Magit") t)))

(use-package magit-todos
  :after magit
  :config
  (magit-todos-mode 1))

(use-package markdown-mode
  :bind
  (:map markdown-mode-map
	("M-<left>" . markdown-promote)
	("M-<right>" . markdown-demote)
	("M-<up>" . markdown-move-up)
	("M-<down>" . markdown-move-down))
  :hook (;;(markdown-mode . markdown-toggle-markup-hiding)
	 (markdown-mode . markdown-toggle-url-hiding))
  :config
  (set-face-attribute 'markdown-header-face-1 nil :underline t)
  (set-face-attribute 'markdown-header-face-2 nil :underline t)
  (set-face-attribute 'markdown-header-face-3 nil :underline t)
  (autoload 'markdown-mode "markdown-mode"
    "Major mode for editing Markdown files" t)
  (add-to-list 'auto-mode-alist
               '("\\.\\(?:md\\|markdown\\|mkd\\|mdown\\|mkdn\\|mdwn\\)\\'" . markdown-mode))

  (autoload 'gfm-mode "markdown-mode"
    "Major mode for editing GitHub Flavored Markdown files" t)
  (add-to-list 'auto-mode-alist '("README\\.md\\'" . gfm-mode))

  (setq markdown-hide-urls t
	markdown-hide-markup t))

(use-package nov
  :mode ("\\.epub\\'" . nov-mode)
  :hook ((nov-mode . (lambda ()
			(setq-local line-spacing 4)))
	 (nov-mode . visual-line-mode))
  :config
  (setq nov-text-width t))

(use-package olivetti
  :commands (olivetti-mode)
  :bind
  (("C-x x o" . olivetti-mode))
  :init
  (add-to-list 'mode-line-collapse-minor-modes 'olivetti-mode)
  :config
  (setq olivetti-body-width 95))

(use-package org-roam
  :custom
  (org-roam-directory od/notes-directory)
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n g" . org-roam-graph)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ;; Dailies
         ("C-c n j" . org-roam-dailies-capture-today))
  :config
  ;; (setq org-roam-directory od/notes-directory)
  ;; If you're using a vertical completion framework, you might want a more informative completion interface
  (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
  (org-roam-db-autosync-mode)
  ;; If using org-roam-protocol
  (require 'org-roam-protocol))

(use-package pass
  :bind
  (("s-s p w" . password-store-copy)
   ("C-c p w" . password-store-copy)
   ("C-c p y" . od/password-store-yank)
   ("C-c p <RET>" . password-store-edit))
  (:map pass-mode-map
	("<return>" . pass-view)
	("w" . pass-copy))
  :config
  ;; I've seen some times when this wasn't activated which kept the password encrypted
  ;; when I tried to copy them
  (epa-file-enable)
  (setq password-store-password-length 20)
  ;; If I don't disable view-mode, "w" keybinding is shadowed
  (add-hook 'pass-mode-hook #'(lambda () (view-mode -1)))

  (defun od/password-store-yank ()
    "Yank password at point. Also works for EXWM managed windows."
    (interactive)
    (let ((proc (call-interactively 'password-store-copy)))
      (while (process-live-p proc)
	(accept-process-output proc))
      (nol/exwm-aware-yank))))

;; TODO: Spawn a popup shell buffer at startup
(use-package popper
  :disabled t				; TODO: It breaks `moody-replace-mode-line-buffer-identification' with *Help* buffer
  :bind (("C-'"   . popper-toggle)
         ("M-'"   . popper-cycle)
         ("C-M-'" . popper-toggle-type))
  :init
  (setq popper-reference-buffers
        '("\\*Messages\\*"
          "Output\\*$"
          ;; "\\*Async Shell Command\\*"
	  shell-mode
          help-mode
          compilation-mode))
  (popper-mode +1)
  (popper-echo-mode +1) ; For echo area hints
  :config
  (when (bound-and-true-p exwm--root)
    (exwm-input-set-key (kbd "C-'") 'popper-toggle)))

(use-package ready-player
  :demand t
  :config
  (ready-player-mode +1))

(use-package sudo-edit
  :commands (sudo-edit sudo-edit-find-file))

;; Use prefix with C-/ ?
(use-package vundo)

(use-package vterm
  :commands (vterm)
  :bind
  (:map vterm-mode-map
	(("C-y" . vterm-yank)
	 ("C-v" . vterm-yank)))
  :config
  ;; To be used as `xdg-launcher-terminal-function'.
  (defun vterm-make-term (name program &optional startfile &rest switches)
    "Make a vterm process NAME in a buffer, running PROGRAM.
If STARTFILE is non-nil, insert its contents.
SWITCHES are passed as arguments to PROGRAM.
If buffer already exists and is alive, do not restart the process."
    (let* ((bufname (format "*%s*" name))
           (existing (get-buffer bufname)))
      (if (and existing (buffer-live-p existing)
               (buffer-local-value 'vterm--process existing)
               (process-live-p (buffer-local-value 'vterm--process existing)))
          existing
	(let* ((default-directory (or default-directory "~/"))
	       (cmd (mapconcat #'shell-quote-argument
                               (cons program switches) " "))
	       (vterm-kill-buffer-on-exit t)
	       (vterm-shell (s-concat "sh -c " cmd)))
          (with-current-buffer (vterm bufname)
            (when startfile
              (insert-file-contents-literally startfile)
              (vterm-send-input))
            (current-buffer)))))))

(use-package xdg-launcher
  :custom
  (xdg-launcher-terminal-function 'vterm-make-term)
  :bind
  (("s-d" . xdg-launcher-run-app)))

(provide 'init-misc)
