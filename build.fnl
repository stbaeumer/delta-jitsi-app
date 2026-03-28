;; A little build system for this project

(local fennel (require :fennel))
(local build (require :build-helpers))
(local posix (require :posix))
(local ci? (not= nil (os.getenv "CI")))

;; Let's do some building!
;;
;; - Compiles Fennel files into Lua
;; - Creates HTML files from Lua tables
;; - Creates our Webxdc file
;;
;; This also automatically checks if there are any changes to
;; our files by polling them for any changes every second

(let [;; These are the files that we want to build
      files    [{:file "main"  :from "fnl" :to "lua" }
                {:file "index" :from "fnl" :to "html"}]

      ;; These are the commands that we want to run
      cmds     ["mkdir -p dist"
                "rm -rf dist/*"
                "zip -9 -r dist/delta-wallet.xdc index.html icon.png icon.svg manifest.toml assets/pico.indigo.min.css style.css libs/retrov.min.js libs/fengari-web.js main.lua"]

      ;; These are the files that we want to watch
      ;; (not recursive, only the current directory is watched)
      modified (build.files-modified [:fnl :css :js])]

  (fn run-cmd [cmd]
    (print "Command" cmd)
    (let [(ok _ code) (os.execute cmd)]
      (if (or (= ok true) (= ok 0) (= code 0))
          true
          (do
            (print "Command failed" cmd)
            false))))

  (fn compile-lua-file [file from to]
    (let [filename (.. file "." from)]
      (case (io.open filename :r)
        f (let [source (f:read :*a)]
            (f:close)
            (let [(ok lua-source) (pcall fennel.compile-string source
                                         {:filename filename
                                          :requireAsInclude true})]
              (if ok
                  (do
                    (build.write-lua (.. file "." to) lua-source)
                    true)
                  (do
                    (print lua-source)
                    false))))
        (nil err) (do
                    (print "Could not read" filename err)
                    false))))

  (fn build-once []
    (var success? true)
    (print "\n 🔄 Rebuilding files ...\n")
    (each [_ { : file : from : to } (ipairs files)]
      (case to
        :html
        (let [(ok contents-or-error) (pcall fennel.dofile (.. file "." from))]
          (if ok
              (build.write-html (.. file "." to)
                                (contents-or-error.html build))
              (do
                (print contents-or-error)
                (set success? false))))

        :lua
        (when (not (compile-lua-file file from to))
          (set success? false))))

    (when success?
      (each [_ cmd (ipairs cmds)]
        (when (not (run-cmd cmd))
          (set success? false))))

    success?)
  
  (fn build-loop []
    ;; Rebuild the files whenever they're modified
    (when (modified)
      (build-once))

    ;; Let's pause the program for a bit
    (coroutine.yield)
    (build-loop))

  (if ci?
      (os.exit (if (build-once) 0 1))
      (let [co (coroutine.create build-loop)]
        (while true
          (coroutine.resume co)
          ;; We can use (os.clock) but that seems to consume
          ;; quite a bit of CPU. Sleep seems much more efficient.
          (posix.sleep 1)))))


