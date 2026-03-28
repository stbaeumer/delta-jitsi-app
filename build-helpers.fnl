;; Functions used by build.fnl

(local lfs (require :lfs))

;; Converts a Lua table into an HTML string
;; HTML code generation is from https://wiki.fennel-lang.org/html
(fn tag [tag-name attrs]
  (assert (= (type attrs) "table") (.. "Missing attrs table: " tag-name))
  (let [attr-str (table.concat (icollect [k v (pairs attrs)]
                                 (if (= v true) k
                                     (.. k "=\"" v "\""))) " ")]
    (.. "<" tag-name " " attr-str ">")))

(fn html [document]
  (if (= (type document) :string)
      document
      (let [[tag-name attrs & body] document]
        (.. (tag tag-name attrs)
            (table.concat (icollect [_ element (ipairs body)]
                            (html element)) " ")
            "</" tag-name ">"))))

(fn read-file [file]
  (print "Reading" file)
  (let [f (assert (io.open file "r"))
        contents (f.read f "a")]
    (f.close f) contents))

;; Adds JS, CSS, and Lua assets into the file
;; It's possible to choose between inline and an external link
;; through the `inline` variable 
(fn load-assets [assets]
  (table.unpack
   (icollect [_ [asset filetype inline] (ipairs assets)]
     (if inline
         (case filetype
           :js   [:script {} (read-file asset)]
           :css  [:style {} (read-file asset)]
           :lua  [:script {:type "application/lua"} (read-file asset)])
         (case filetype
           :js   [:script {:src asset :type "text/javascript"}]
           :css  [:link {:rel "stylesheet" :href asset :type "text/css"}]
           :lua  [:script {:src asset :type "application/lua" :async true}])))))

;; This writes the actual HTML file into the disk
(fn write-html [filename contents]
  (print "Writing" filename)
  (let [f (assert (io.open filename "w"))]
    (f.write f (.. "<!doctype html>" (html contents true)))
    (f.close f)))

;; Write a Lua file
(fn write-lua [filename contents]
  (print "Writing" filename)
  (let [f (assert (io.open filename "w"))]
    (f.write f contents)
    (f.close f)))

;; This function checks if our files have been modified
(fn files-modified [watch]
  
  ;; Get all the files in the current directory
  ;; Store them in a table containing modification times of files
  (let [file-mods {}]
    (each [file _ (lfs.dir ".")]
      ;; See if the file matches our watch patterns
      ;; Let's ignore hidden files as well (looking at you, emacs!)
      (each [_ ext (ipairs watch)]
        (when (and
               (string.find file (.. "%." ext "$"))
               (not (string.find file "^%.")))
          (print "✅ Watching" file)
          (set (. file-mods file) 0))))

    ;; Return a function that already has the watched files ready to use
    (fn []
      (var modified? false)
      (each [file modification (pairs file-mods)]
        ;; Get the attributes of the file
        (let [attr (lfs.attributes file)]
          ;; Check if there's a mismatch with the modification dates
          (when (and (not= modification attr.modification)
                     (= "file" attr.mode))

            (when (not= modification 0)
              (print "\n🌺 Modified file found" file)
              (print "Modification times" modification attr.modification))
            
            (set modified? true)
            (set (. file-mods file) attr.modification))))
      modified?)))

{ : html
  : read-file
  : load-assets
  : write-html
  : write-lua
  : files-modified }
