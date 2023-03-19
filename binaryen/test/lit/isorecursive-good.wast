;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.

;; RUN: wasm-opt %s -all --hybrid -S -o - | filecheck %s --check-prefix HYBRID
;; RUN: wasm-opt %s -all --hybrid --roundtrip -S -o - | filecheck %s --check-prefix HYBRID
;; RUN: wasm-opt %s -all --nominal -S -o - | filecheck %s --check-prefix NOMINAL

(module
  (rec
    ;; HYBRID:      (rec
    ;; HYBRID-NEXT:  (type $super-struct (struct (field i32)))
    ;; NOMINAL:      (type $super-array (array (ref $super-struct)))

    ;; NOMINAL:      (type $sub-array (array_subtype (ref $sub-struct) $super-array))

    ;; NOMINAL:      (type $super-struct (struct (field i32)))
    (type $super-struct (struct i32))
    ;; HYBRID:       (type $sub-struct (struct_subtype (field i32) (field i64) $super-struct))
    ;; NOMINAL:      (type $sub-struct (struct_subtype (field i32) (field i64) $super-struct))
    (type $sub-struct (struct_subtype i32 i64 $super-struct))
  )

  (rec
    ;; HYBRID:      (rec
    ;; HYBRID-NEXT:  (type $super-array (array (ref $super-struct)))
    (type $super-array (array (ref $super-struct)))
    ;; HYBRID:       (type $sub-array (array_subtype (ref $sub-struct) $super-array))
    (type $sub-array (array_subtype (ref $sub-struct) $super-array))
  )

  (rec
    ;; HYBRID:      (rec
    ;; HYBRID-NEXT:  (type $super-func (func (param (ref $sub-array)) (result (ref $super-array))))
    ;; NOMINAL:      (type $super-func (func (param (ref $sub-array)) (result (ref $super-array))))
    (type $super-func (func (param (ref $sub-array)) (result (ref $super-array))))
    ;; HYBRID:       (type $sub-func (func_subtype (param (ref $super-array)) (result (ref $sub-array)) $super-func))
    ;; NOMINAL:      (type $sub-func (func_subtype (param (ref $super-array)) (result (ref $sub-array)) $super-func))
    (type $sub-func (func_subtype (param (ref $super-array)) (result (ref $sub-array)) $super-func))
  )

  ;; HYBRID:      (func $make-super-struct (type $none_=>_ref|$super-struct|) (result (ref $super-struct))
  ;; HYBRID-NEXT:  (call $make-sub-struct)
  ;; HYBRID-NEXT: )
  ;; NOMINAL:      (func $make-super-struct (type $none_=>_ref|$super-struct|) (result (ref $super-struct))
  ;; NOMINAL-NEXT:  (call $make-sub-struct)
  ;; NOMINAL-NEXT: )
  (func $make-super-struct (result (ref $super-struct))
    (call $make-sub-struct)
  )

  ;; HYBRID:      (func $make-sub-struct (type $none_=>_ref|$sub-struct|) (result (ref $sub-struct))
  ;; HYBRID-NEXT:  (unreachable)
  ;; HYBRID-NEXT: )
  ;; NOMINAL:      (func $make-sub-struct (type $none_=>_ref|$sub-struct|) (result (ref $sub-struct))
  ;; NOMINAL-NEXT:  (unreachable)
  ;; NOMINAL-NEXT: )
  (func $make-sub-struct (result (ref $sub-struct))
    (unreachable)
  )

  ;; HYBRID:      (func $make-super-array (type $none_=>_ref|$super-array|) (result (ref $super-array))
  ;; HYBRID-NEXT:  (call $make-sub-array)
  ;; HYBRID-NEXT: )
  ;; NOMINAL:      (func $make-super-array (type $none_=>_ref|$super-array|) (result (ref $super-array))
  ;; NOMINAL-NEXT:  (call $make-sub-array)
  ;; NOMINAL-NEXT: )
  (func $make-super-array (result (ref $super-array))
    (call $make-sub-array)
  )

  ;; HYBRID:      (func $make-sub-array (type $none_=>_ref|$sub-array|) (result (ref $sub-array))
  ;; HYBRID-NEXT:  (unreachable)
  ;; HYBRID-NEXT: )
  ;; NOMINAL:      (func $make-sub-array (type $none_=>_ref|$sub-array|) (result (ref $sub-array))
  ;; NOMINAL-NEXT:  (unreachable)
  ;; NOMINAL-NEXT: )
  (func $make-sub-array (result (ref $sub-array))
    (unreachable)
  )

  ;; HYBRID:      (func $make-super-func (type $none_=>_ref|$super-func|) (result (ref $super-func))
  ;; HYBRID-NEXT:  (call $make-sub-func)
  ;; HYBRID-NEXT: )
  ;; NOMINAL:      (func $make-super-func (type $none_=>_ref|$super-func|) (result (ref $super-func))
  ;; NOMINAL-NEXT:  (call $make-sub-func)
  ;; NOMINAL-NEXT: )
  (func $make-super-func (result (ref $super-func))
    (call $make-sub-func)
  )

  ;; HYBRID:      (func $make-sub-func (type $none_=>_ref|$sub-func|) (result (ref $sub-func))
  ;; HYBRID-NEXT:  (unreachable)
  ;; HYBRID-NEXT: )
  ;; NOMINAL:      (func $make-sub-func (type $none_=>_ref|$sub-func|) (result (ref $sub-func))
  ;; NOMINAL-NEXT:  (unreachable)
  ;; NOMINAL-NEXT: )
  (func $make-sub-func (result (ref $sub-func))
    (unreachable)
  )
)