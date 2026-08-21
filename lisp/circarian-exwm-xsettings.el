;; -*- lexical-binding: t; -*-

;; When modifying those lists, re-evaluate `circadian-themes' and
;; run (circadian-setup).
(setq allowed-base16-light-themes '(base16-atelier-cave-light
				    base16-atelier-dune-light
				    base16-atelier-estuary-light
				    base16-atelier-forest-light
				    base16-atelier-heath-light
				    base16-atelier-lakeside-light
				    base16-atelier-plateau-light
				    base16-atelier-savanna-light
				    base16-atelier-seaside-light
				    base16-atelier-sulphurpool-light
				    base16-catppuccin-latte
				    base16-gruvbox-light
				    base16-nord-light
				    base16-one-light))

(setq allowed-base16-dark-themes '(base16-0x96f
				   base16-atelier-cave
				   base16-atelier-dune
				   base16-atelier-estuary
				   base16-atelier-forest
				   base16-atelier-heath
				   base16-atelier-lakeside
				   base16-atelier-plateau
				   base16-atelier-savanna
				   base16-atelier-seaside
				   base16-atelier-sulphurpool
				   base16-catppuccin-mocha
				   base16-catppuccin
				   base16-gruvbox-dark
				   base16-nord
				   base16-onedark))

;; Example .xsettingsd
;; Net/ThemeName         "base16-atelier-dune-light"
;; Net/IconThemeName     "Adwaita"
;; Gtk/DecorationLayout  "menu:close"
;; Gtk/FontName          "Atkinson Hyperlegible"
;; Gtk/MonospaceFontName "FiraCode Nerd Font Mono"
;; Gtk/CursorThemeName   "Adwaita"
;; Xft/Antialias         1
;; Xft/DPI               112640
;; Xft/Hinting           1
;; Xft/HintStyle         "hintfull"
;; Xft/lcdfilter         "lcddefault"
;; Xft/RGBA              "rgb"

(require 'exwm-xsettings)
(require 'seq)
(require 'subr-x)

(setq exwm-xsettings `(("Gtk/DecorationLayout" . "menu:close")
		       ("Gtk/FontName" . "Atkinson Hyperlegible")
		       ("Gtk/MonospaceFontName" . "FiraCode Nerd Font Mono")
		       ("Gtk/CursorThemeName" . "Adwaita")
		       ("Xft/Antialias" . 1)
		       ("Xft/Hinting" . 1)
		       ;; DPI is in 1024ths of an inch, so this is a DPI of
                       ;; 110, equivalent to a scaling factor ≅ 1.15
                       ;; (110 ≅ 1.15 * 96).
		       ("Xft/DPI" . ,(* 110 1024))
		       ("Xft/HintStyle" . "hintslight")
		       ("Xft/RGBA" . "none") ; Accoring to ChatGPT, this might make white text on black background less blurry
                       ("Xft/lcdfilter" . "lcddefault")))

(exwm-xsettings-mode 1)
;; Make sure to kill xsettingsd first.
;;(setopt exwm-xsettings-theme "base16-atelier-cave-light")
;;(setopt exwm-xsettings-theme "base16-atelier-cave")

(defun nol/xsettings-theme-directories ()
  "Return standard GTK theme directories."
  (let* ((xdg-data-home (or (getenv "XDG_DATA_HOME")
			    (expand-file-name "~/.local/share")))
	 (xdg-data-dirs (split-string (or (getenv "XDG_DATA_DIRS")
					  "/usr/local/share:/usr/share")
				      path-separator t)))
    (delete-dups
     (mapcar #'directory-file-name
	     (append (list (expand-file-name "themes" xdg-data-home)
			   (expand-file-name "~/.themes"))
		     (mapcar (lambda (dir)
			       (expand-file-name "themes" dir))
			     xdg-data-dirs))))))

(defun nol/xsettings-theme-exists-p (theme)
  "Return non-nil if THEME exists in a standard GTK theme directory.
Also accept a matching THEME-Dark directory."
  (let* ((theme-name (if (symbolp theme) (symbol-name theme) theme))
	 (theme-names (list theme-name (concat theme-name "-Dark"))))
    (seq-some (lambda (dir)
		(seq-some (lambda (theme-name)
			    (file-directory-p (expand-file-name theme-name dir)))
			  theme-names))
	      (nol/xsettings-theme-directories))))

(defun nol/xsettings-theme-name (theme)
  "Return the GTK theme name to use for Emacs THEME."
  (let ((theme-name (if (symbolp theme) (symbol-name theme) theme)))
    (if (string= theme-name "modus-vivendi")
	"modus-vivendi-Dark"
      theme-name)))

(defun nol/set-xsettings-theme (theme)
  "Set XSETTINGS theme. Also expose custom properties `Net/ThemeColorBG',
`Net/ThemeColorFG' and `Net/ThemeColorAccent'."
  (let ((theme-name (nol/xsettings-theme-name theme)))
    (unless (nol/xsettings-theme-exists-p theme-name)
      (display-warning
       'xsettings
       (format "GTK theme %s was not found in any standard theme directory: %s"
	       theme-name
	       (string-join (nol/xsettings-theme-directories) ", "))))
    (setopt exwm-xsettings-theme theme-name))
  ;; When the theme is active, expose its main background and foreground colors
  ;; as XSETTINGS properties.
  (let ((bg (face-background 'default))
	(fg (face-foreground 'default))
	(accent (face-foreground 'font-lock-constant-face))) ; base09
    (nconc exwm-xsettings `(("Net/ThemeColorBG" . ,bg)
			    ("Net/ThemeColorFG" . ,fg)
			    ("Net/ThemeColorAccent" . ,accent)))
    (exwm-xsettings--update-settings)))

;; (require 'circadian)

;; (setopt circadian-verbose t)

;; (setq circadian-themes `((:sunrise . modus-operandi)
;; 			 (:sunset . modus-vivendi)))

;; (setq circadian-after-load-theme-hook '(nol/set-xsettings-theme
;; 					;; nol/custom-set-faces
;; 					))

;; (circadian-setup)

;; To test the functions added to `circadian-after-load-theme-hook'
;;(run-hook-with-args 'circadian-after-load-theme-hook "base16-atelier-cave-light")
;;(run-hook-with-args 'circadian-after-load-theme-hook "base16-atelier-sulphurpool")
