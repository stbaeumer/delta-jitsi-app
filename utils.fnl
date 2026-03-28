(local js (require :js))

;; Convert a Lua table into a JS object
(fn objectify [tbl]
  (let [obj (js.new js.global.Object)]
    (each [k v (pairs tbl)]
      (if (= (type v) :table)
          (set (. obj k) (objectify v))
          (set (. obj k) v)))
    obj))

{ : objectify }
