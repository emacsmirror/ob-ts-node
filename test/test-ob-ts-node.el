(require 'ert)
(require 'ob-ts-node)

(defun ob-ts-node--run-org-test (filename strategy)
  "Run integration test on FILENAME (relative to test/ dir) using STRATEGY.
Strategy can be 'idempotency (check #+RESULTS match) or 'non-empty."
  (require 'org)
  (let ((org-file (expand-file-name filename (expand-file-name "test")))
        (org-confirm-babel-evaluate nil)
        (temporary-file-directory (expand-file-name "tmp"))
        (default-directory (expand-file-name "..")))
    (unless (file-exists-p temporary-file-directory)
      (make-directory temporary-file-directory))
    (message "Testing %s..." org-file)
    (with-current-buffer (find-file-noselect org-file)
      (org-babel-map-src-blocks org-file
        (let* ((result-loc (org-babel-where-is-src-block-result))
               (expected (when result-loc
                           (save-excursion
                             (goto-char result-loc)
                             (org-babel-read-result))))
               (result (org-babel-execute-src-block)))
          (message "Block Result: %s" result)
          (if (eq strategy 'non-empty)
              (should (and result (not (string-empty-p (format "%s" result)))))

            ;; Idempotency check
            (when result-loc
              (let ((exp-str (if expected (format "%s" expected) ""))
                    (res-str (if result (format "%s" result) "")))
                (unless (equal (org-trim exp-str) (org-trim res-str))
                  (message "Failed Block in %s:\n%s" filename (nth 1 (org-babel-get-src-block-info)))
                  (message "Expected: '%s' (raw: %S)" exp-str expected)
                  (message "Actual:   '%s' (raw: %S)" res-str result))
                (should (equal (org-trim exp-str) (org-trim res-str)))))))))))

(ert-deftest ob-ts-node-test-org-basic ()
  "Run idempotency tests on test_basic.org."
  (ob-ts-node--run-org-test "test_basic.org" 'idempotency))

(ert-deftest ob-ts-node-test-org-extended ()
  "Run idempotency tests on test_extended.org."
  (ob-ts-node--run-org-test "test_extended.org" 'idempotency))

(ert-deftest ob-ts-node-test-org-https ()
  "Run non-empty tests on test-https.org."
  (ob-ts-node--run-org-test "test-https.org" 'non-empty))