;;; magit-collab.el --- collaboration tools       -*- lexical-binding: t -*-

;; Copyright (C) 2010-2017  The Magit Project Contributors
;;
;; You should have received a copy of the AUTHORS.md file which
;; lists all contributors.  If not, see http://magit.vc/authors.

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Maintainer: Jonas Bernoulli <jonas@bernoul.li>

;; Magit is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; Magit is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Magit.  If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; This library implements various collaboration tools.  These tools
;; are only early incarnation -- implementing collaboration tools is
;; a top priority for future development.

;; Currently these tools (including `magit-branch-pull-request', which
;; is defined elsewhere) only support Github, but support for other
;; Git forges as well as mailing list based collaboration is in
;; planning.

;;; Code:

(require 'magit)
(require 'ghub)

;;; Commands

;;;###autoload
(defun magit-browse-pull-request (pr)
  "Visit pull-request PR using `browse-url'.

Currently this only supports Github, but that restriction will
be lifted eventually to support other Git forges."
  (interactive (list (magit-read-pull-request "Visit pull request")))
  (browse-url (format "https://github.com/%s/pull/%s"
                      (--> pr
                           (cdr (assq 'base it))
                           (cdr (assq 'repo it))
                           (cdr (assq 'full_name it)))
                      (cdr (assq 'number pr)))))

;;; Utilities

(defun magit-read-pull-request (prompt)
  "Read a pull request from the user, prompting with PROMPT.
Return the Git forge's API response.  Currently this function
only supports Github, but that will change eventually."
  (let* ((origin (magit-upstream-repository))
         (url    (magit-get "remote" origin "url"))
         (prs    (ghub-get
                  (format "/repos/%s/pulls"
                          (and (string-match
                                "github.com[:/]\\(.+?\\)\\(?:\\.git\\)?\\'" url)
                               (match-string 1 url)))))
         (choice (magit-completing-read
                  prompt
                  (--map (format "%s  %s"
                                 (cdr (assq 'number it))
                                 (cdr (assq 'title  it)))
                         prs)
                  nil t))
         (number (and (string-match "\\([0-9]+\\)" choice)
                      (string-to-number (match-string 1 choice)))))
    (--first (eq (cdr (assq 'number it)) number) prs)))

(defun magit-upstream-repository ()
  "Return the remote name of the upstream repository.

If the Git variable `magit.upstream' is set, then return its
value.  Otherwise return \"origin\".  If the remote does not
exist, then raise an error.

Currently this function raises an error when the upstream
repository isn't located on Github because that's all that its
only caller can currently deal with.  However that will change
eventually."
  (let ((remote (or (magit-get "magit.upstream") "origin")))
    (unless (magit-remote-p remote)
      (error "No remote named `%s' exists (consider setting `magit.upstream')"
             remote))
    (unless (string-match-p "github\\.com" (magit-get "remote.origin.url"))
      (error "Currently only Github is supported"))
    remote))

(provide 'magit-collab)
;;; magit-collab.el ends here
