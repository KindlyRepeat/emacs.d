;; -*- lexical-binding: t; -*-

(defun od/get-sunrise-time (&optional hour-or-min)
  "Return the time of sunrise for the day in 24-hours form. Optionnaly return the hour or the minute only, as
an integer"
  (let* ((calendar-time-display-form '(24-hours ":" minutes " "))
	 (sunrise-time (nth 1 (split-string (sunrise-sunset)))))
    (cond ((eq hour-or-min 'hour) (string-to-number (nth 0 (split-string sunrise-time ":"))))
	  ((eq hour-or-min 'min) (string-to-number  (nth 1 (split-string sunrise-time ":"))))
	  (t sunrise-time))))

(defun od/get-sunset-time (&optional hour-or-min)
  "Return the time of sunset for the day in 24-hours form. Optionnaly return the hour or the minute only, as
an integer"
  (let* ((calendar-time-display-form '(24-hours ":" minutes " "))
	 (sunset-time (nth 4 (split-string (sunrise-sunset)))))
    (cond ((eq hour-or-min 'hour) (string-to-number (nth 0 (split-string sunset-time ":"))))
	  ((eq hour-or-min 'min) (string-to-number  (nth 1 (split-string sunset-time ":"))))
	  (t sunset-time))))

(defun od/before-sunset-p ()
  "Return `t' if current time is before sunset time."
  (let ((current-hour (nth 2 (decode-time)))
	(current-minute (nth 1 (decode-time)))
	(sunset-hour (od/get-sunset-time 'hour))
	(sunset-minute (od/get-sunset-time 'min)))
    (or (< current-hour sunset-hour)
	(and (= current-hour sunset-hour)
	     (< current-minute sunset-minute)))))

(defun od/after-sunrise-p ()
  "Return `t' if current time is after sunrise time."
  (let ((current-hour (nth 2 (decode-time)))
	(current-minute (nth 1 (decode-time)))
	(sunrise-hour (od/get-sunrise-time 'hour))
	(sunrise-minute (od/get-sunrise-time 'min)))
    (or (> current-hour sunrise-hour)
	(and (= current-hour sunrise-hour)
	     (> current-minute sunrise-minute)))))

(defun od/light-or-dark ()
  "Return `light' or `dark' depending on the time of day"
  (if (and (od/before-sunset-p) (od/after-sunrise-p))
      'light
    'dark))

(provide 'init-sunrise)
