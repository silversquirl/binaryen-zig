;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.
;; RUN: wasm-opt %s --optimize-instructions --traps-never-happen --enable-gc-nn-locals -all -S -o - \
;; RUN:   | filecheck %s

(module
  ;; CHECK:      (func $set-of-as-non-null (type $none_=>_none)
  ;; CHECK-NEXT:  (local $x anyref)
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (ref.as_non_null
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $x
  ;; CHECK-NEXT:    (ref.as_non_null
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $set-of-as-non-null
    (local $x anyref)
    ;; As we ignore such traps, we can in principle remove the ref.as here.
    ;; However, as we allow non-nullable locals, we should not do that - if we
    ;; did it it might prevent specializing the local type later.
    (local.set $x
      (ref.as_non_null
        (local.get $x)
      )
    )
    ;; The same for a tee.
    (drop
      (local.tee $x
        (ref.as_non_null
          (local.get $x)
        )
      )
    )
  )
)