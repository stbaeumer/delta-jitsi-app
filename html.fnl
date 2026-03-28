(local {:global { : document
                  : RV } &as js} (require :js))
(local Array (fn [...] (js.global:Array ...)))
(local log (fn [...] (js.global.console:log ...)))
(local utils (require :utils))

;; Create a virtual DOM node including its children nodes by recursively 
;; iterating through a table that represents the DOM.
;; 
;; Input:
;; [:element {:attribute value} & children]
;; 
;; Output:
;; Virtual DOM 
;;
;; Partly based on https://wiki.fennel-lang.org/html
(lambda html [doc]
  ;; Create the vdom using RetroV
  (let [[element attrs & children] doc]
    (Array element (utils.objectify attrs)
           (table.unpack
            (icollect [_ child (ipairs children)]
              (case (type child)
                ;; If it's an SVG, wrap it in an Array
                :string  (if (string.find child "^<svg")
                             (Array child)
                             child)
                ;; If it's a boolean, return it on its own
                :boolean child
                ;; Otherwise, let's continue recursing!
                _        (html child)))))))

;; TODO: Maybe storing the reference instead of querying each time
;; is better?
(local ref {})

(fn render [doc selector]
  (if (. ref selector)
      (RV:render (. ref selector) (html doc))
      (let [root (document:querySelector selector)]
        (set (. ref selector) root)
        (RV:render root (html doc)))))

{ : render : RV }
