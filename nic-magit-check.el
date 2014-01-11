;;; nic-magit-check.el --- check magit buffers for unpushed things

;; Copyright (C) 2014  Nic Ferrier

;; Author: Nic Ferrier <nferrier@ferrier.me.uk>
;; Keywords: vc
;; Package-requires: ((dash "1.5.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Checks your open magit buffers for things that aren't pushed.

;;; Code:

(require 'dash)

(defvar nic-magit-check-status ""
  "Whether there is an unpushed magit buffer or not.

The value is a propertized string, the `:unpushed' property
contains the list of the unpushed repositories.")

(defun nic-magit/check-set (unpushed)
  (setq nic-magit-check-status
        (propertize 
         (if unpushed
             (propertize
              (format "%s[%d]"
                      (replace-regexp-in-string
                       "^\\*magit: " "*"
                       (buffer-name (car unpushed)))
                      (length unpushed))
              :unpushed unpushed)
             "") 'help-echo "Which magit buffers need pushing")))


(defvar nic-magit/idle-timer nil
  "Contains the idle timer for idly checking magit buffers.")

(defun nic-magit/check-init ()
  "Initializes `nic-magit/idle-timer'."
  (unless (timerp nic-magit/idle-timer)
    (setq nic-magit/idle-timer
          (run-with-idle-timer 10.0 t 'nic-magit-check))))

(defun nic-magit-check ()
  "Main function, checks unpushed magits.

Updates the variable `nic-magit-check-status'.

This also calls `nic-magit/check-init' which spawns a timer to
repeatedly do this if no timer is present."
  (interactive)
  (let ((unpushed
         (->> (buffer-list)
           (-filter
            (lambda (b)
              (with-current-buffer b
                (eq major-mode 'magit-status-mode))))
           (-filter
            (lambda (b)
              (with-current-buffer b
                (save-excursion
                  (save-match-data
                    (goto-char (point-min))
                    (re-search-forward "Unpushed commits" nil t)))))))))
    (nic-magit/check-set unpushed)
    ;; FIXME - the timer spawning should probably be a customize option
    (nic-magit/check-init)))

(defun nic-magit-next-buffer ()
  "Pop the next unpushed buffer into view."
  (interactive)
  (pop-to-buffer
   (let* ((ll (text-properties-at 0 nic-magit-check-status))
          (unpushed-l (plist-get ll :unpushed))
          (top (car unpushed-l)))
     (nic-magit-check-set (append (cdr unpushed-l) (list top)))
     top)))

(defun nic-magit/modeline-content ()
  (concat " " nic-magit-check-status))

;;;###autoload
(define-minor-mode nic-magit-track
    "Track `magit' buffers that are unsynced."
  nil nil nil
  :global t
  :lighter (:eval (nic-magit/modeline-content))
  (nic-magit-check))

(provide 'nic-magit-check)

;;; nic-magit-check.el ends here
