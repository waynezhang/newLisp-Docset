(module "sqlite3.lsp")

(xml-type-tags nil nil nil nil)

(define (prepare-db db)
  (sql3:open db)
  (sql3:sql "DROP TABLE IF EXISTS searchIndex;")
  (sql3:sql "CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);"))

(define (close-db) (sql3:close))

(define (insert-index name type path)
  (sql3:sql (format "INSERT INTO searchIndex (name,type,path) VALUES ('%s','%s','%s');" name type path)))

(define (insert-item l)
 (letn (name (last l)
        idx (ref 'href l)
        _ (inc (last idx))
        path (l idx)
        type "func")
  (insert-index name type path)))

(define (parse-index index-file)
  (letn (xml (xml-parse (read-file index-file) 15)
         link-idxs (ref-all 'a xml)
         links (map (fn (x) (xml (slice x 0 -1))) link-idxs))
   (dolist (l links)
     (insert-item l))))

;; .
;; |___newLisp.docset
;; | |___Contents
;; | | |___Info.plist
;; | | |___Resources
;; | | | |___Documents
;; | | | | |___index.html
;; | | | |___LICENSE
;; | | | |___docSet.dsidx
;;

(define (prepare-directories base)
 (!(string "rm -rf " base))
 (!(string "mkdir -p " base "/Contents/Resources/Documents")))

(define (build-meta-file base)
  (let (template [text]<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>CFBundleIdentifier</key>
    <string>%s</string>
    <key>CFBundleName</key>
    <string>%s</string>
    <key>DocSetPlatformFamily</key>
    <string>%s</string>
    <key>isDashDocset</key>
    <true/>
  </dict>
</plist>[/text])
  (write-file (string base "/Contents/Info.plist") (format template "org.newlisp" "newLisp" "newLisp"))))

(define (trim-manual manual-file target)
 ;; xml parse will be a litte pain
 (let (src (open manual-file "read")
       out (open target "write")
       status 0) ;; 0 -> start, 1 -> in body, 2 -> found funcs, 3 -> fin
  (while (read-line src)
   (case status
    (0 (begin
        (if (find {<body.*>} (current-line) 0)
         (inc status))
        (write-line out (current-line))))
    (1 (if (find {h2.*alphabetical.*} (current-line) 0)
        (inc status)))
    (2 (if (find {class.*license} (current-line) 0)
        (inc status)
        (write-line out (current-line))))
    (3 (begin
        (write-line out "</body></html>")
        (inc status)))
    (true nil)))
  (close src)
  (close out)))

(define (build-docset trim?)
  (let (base "newLisp.docset")
   (prepare-directories base)
   (build-meta-file base)
   (prepare-db (string base "/Contents/Resources/docSet.dsidx"))
   (parse-index "newlisp_index.html")
   ;; and appendix
   (insert-index "Appendix" "variable" "newlisp_manual.html#appendix")
   (close-db)
   (if trim?
    (begin
     (trim-manual "newlisp_manual.html" "newlisp_manual_trimmed.html")
     (! (string "mv newlisp_manual_trimmed.html " base "/Contents/Resources/Documents/newlisp_manual.html")))
    (! (string "cp newlisp_manual.html " base "/Contents/Resources/Documents/newlisp_manual.html")))))

(define (check-files files)
  (dolist (f files)
   (or (file? f) (throw-error (string f " not found"))))
  true)

(if (catch (check-files (list "newlisp_index.html" "newlisp_manual.html")) 'msg)
 (build-docset (ref "--trim" (main-args)))
 (println (first (parse msg {[\r\n]} 0))))
(exit)
