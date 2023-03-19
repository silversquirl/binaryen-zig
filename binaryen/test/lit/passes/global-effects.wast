;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.

;; Run without global effects, and run with, and also run with but discard them
;; first (to check that discard works; that should be the same as without).

;; RUN: foreach %s %t wasm-opt -all                                                    --vacuum -S -o - | filecheck %s --check-prefix WITHOUT
;; RUN: foreach %s %t wasm-opt -all --generate-global-effects                          --vacuum -S -o - | filecheck %s --check-prefix INCLUDE
;; RUN: foreach %s %t wasm-opt -all --generate-global-effects --discard-global-effects --vacuum -S -o - | filecheck %s --check-prefix DISCARD

(module
  ;; WITHOUT:      (type $none_=>_none (func))

  ;; WITHOUT:      (type $none_=>_i32 (func (result i32)))

  ;; WITHOUT:      (type $i32_=>_none (func (param i32)))

  ;; WITHOUT:      (tag $tag (param))
  ;; INCLUDE:      (type $none_=>_none (func))

  ;; INCLUDE:      (type $none_=>_i32 (func (result i32)))

  ;; INCLUDE:      (type $i32_=>_none (func (param i32)))

  ;; INCLUDE:      (tag $tag (param))
  ;; DISCARD:      (type $none_=>_none (func))

  ;; DISCARD:      (type $none_=>_i32 (func (result i32)))

  ;; DISCARD:      (type $i32_=>_none (func (param i32)))

  ;; DISCARD:      (tag $tag (param))
  (tag $tag)

  ;; WITHOUT:      (func $main (type $none_=>_none)
  ;; WITHOUT-NEXT:  (call $nop)
  ;; WITHOUT-NEXT:  (call $unreachable)
  ;; WITHOUT-NEXT:  (call $call-nop)
  ;; WITHOUT-NEXT:  (call $call-unreachable)
  ;; WITHOUT-NEXT:  (drop
  ;; WITHOUT-NEXT:   (call $unimportant-effects)
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $main (type $none_=>_none)
  ;; INCLUDE-NEXT:  (call $unreachable)
  ;; INCLUDE-NEXT:  (call $call-nop)
  ;; INCLUDE-NEXT:  (call $call-unreachable)
  ;; INCLUDE-NEXT: )
  ;; DISCARD:      (func $main (type $none_=>_none)
  ;; DISCARD-NEXT:  (call $nop)
  ;; DISCARD-NEXT:  (call $unreachable)
  ;; DISCARD-NEXT:  (call $call-nop)
  ;; DISCARD-NEXT:  (call $call-unreachable)
  ;; DISCARD-NEXT:  (drop
  ;; DISCARD-NEXT:   (call $unimportant-effects)
  ;; DISCARD-NEXT:  )
  ;; DISCARD-NEXT: )
  (func $main
    ;; Calling a function with no effects can be optimized away in INCLUDE (but
    ;; not WITHOUT or DISCARD, where the global effect info is not available).
    (call $nop)
    ;; Calling a function with effects cannot.
    (call $unreachable)
    ;; Calling something that calls something with no effects can be optimized
    ;; away in principle, but atm we don't look that far, so this is not
    ;; optimized.
    (call $call-nop)
    ;; Calling something that calls something with effects cannot.
    (call $call-unreachable)
    ;; Calling something that only has unimportant effects can be optimized
    ;; (see below for details).
    (drop
      (call $unimportant-effects)
    )
  )

  ;; WITHOUT:      (func $cycle (type $none_=>_none)
  ;; WITHOUT-NEXT:  (call $cycle)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $cycle (type $none_=>_none)
  ;; INCLUDE-NEXT:  (call $cycle)
  ;; INCLUDE-NEXT: )
  ;; DISCARD:      (func $cycle (type $none_=>_none)
  ;; DISCARD-NEXT:  (call $cycle)
  ;; DISCARD-NEXT: )
  (func $cycle
    ;; Calling a function with no effects in a cycle cannot be optimized out -
    ;; this must keep hanging forever.
    (call $cycle)
  )

  ;; WITHOUT:      (func $nop (type $none_=>_none)
  ;; WITHOUT-NEXT:  (nop)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $nop (type $none_=>_none)
  ;; INCLUDE-NEXT:  (nop)
  ;; INCLUDE-NEXT: )
  ;; DISCARD:      (func $nop (type $none_=>_none)
  ;; DISCARD-NEXT:  (nop)
  ;; DISCARD-NEXT: )
  (func $nop
    (nop)
  )

  ;; WITHOUT:      (func $unreachable (type $none_=>_none)
  ;; WITHOUT-NEXT:  (unreachable)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $unreachable (type $none_=>_none)
  ;; INCLUDE-NEXT:  (unreachable)
  ;; INCLUDE-NEXT: )
  ;; DISCARD:      (func $unreachable (type $none_=>_none)
  ;; DISCARD-NEXT:  (unreachable)
  ;; DISCARD-NEXT: )
  (func $unreachable
    (unreachable)
  )

  ;; WITHOUT:      (func $call-nop (type $none_=>_none)
  ;; WITHOUT-NEXT:  (call $nop)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $call-nop (type $none_=>_none)
  ;; INCLUDE-NEXT:  (nop)
  ;; INCLUDE-NEXT: )
  ;; DISCARD:      (func $call-nop (type $none_=>_none)
  ;; DISCARD-NEXT:  (call $nop)
  ;; DISCARD-NEXT: )
  (func $call-nop
    ;; This call to a nop can be optimized out, as above, in INCLUDE.
    (call $nop)
  )

  ;; WITHOUT:      (func $call-unreachable (type $none_=>_none)
  ;; WITHOUT-NEXT:  (call $unreachable)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $call-unreachable (type $none_=>_none)
  ;; INCLUDE-NEXT:  (call $unreachable)
  ;; INCLUDE-NEXT: )
  ;; DISCARD:      (func $call-unreachable (type $none_=>_none)
  ;; DISCARD-NEXT:  (call $unreachable)
  ;; DISCARD-NEXT: )
  (func $call-unreachable
    (call $unreachable)
  )

  ;; WITHOUT:      (func $unimportant-effects (type $none_=>_i32) (result i32)
  ;; WITHOUT-NEXT:  (local $x i32)
  ;; WITHOUT-NEXT:  (local.set $x
  ;; WITHOUT-NEXT:   (i32.const 100)
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT:  (return
  ;; WITHOUT-NEXT:   (local.get $x)
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $unimportant-effects (type $none_=>_i32) (result i32)
  ;; INCLUDE-NEXT:  (local $x i32)
  ;; INCLUDE-NEXT:  (local.set $x
  ;; INCLUDE-NEXT:   (i32.const 100)
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT:  (return
  ;; INCLUDE-NEXT:   (local.get $x)
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT: )
  ;; DISCARD:      (func $unimportant-effects (type $none_=>_i32) (result i32)
  ;; DISCARD-NEXT:  (local $x i32)
  ;; DISCARD-NEXT:  (local.set $x
  ;; DISCARD-NEXT:   (i32.const 100)
  ;; DISCARD-NEXT:  )
  ;; DISCARD-NEXT:  (return
  ;; DISCARD-NEXT:   (local.get $x)
  ;; DISCARD-NEXT:  )
  ;; DISCARD-NEXT: )
  (func $unimportant-effects (result i32)
    (local $x i32)
    ;; Operations on locals should not prevent optimization, as when we return
    ;; from the function they no longer matter.
    (local.set $x
      (i32.const 100)
    )
    ;; A return is an effect that no longer matters once we exit the function.
    (return
      (local.get $x)
    )
  )

  ;; WITHOUT:      (func $call-throw-and-catch (type $none_=>_none)
  ;; WITHOUT-NEXT:  (try $try
  ;; WITHOUT-NEXT:   (do
  ;; WITHOUT-NEXT:    (call $throw)
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:   (catch_all
  ;; WITHOUT-NEXT:    (nop)
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $call-throw-and-catch (type $none_=>_none)
  ;; INCLUDE-NEXT:  (nop)
  ;; INCLUDE-NEXT: )
  ;; DISCARD:      (func $call-throw-and-catch (type $none_=>_none)
  ;; DISCARD-NEXT:  (try $try
  ;; DISCARD-NEXT:   (do
  ;; DISCARD-NEXT:    (call $throw)
  ;; DISCARD-NEXT:   )
  ;; DISCARD-NEXT:   (catch_all
  ;; DISCARD-NEXT:    (nop)
  ;; DISCARD-NEXT:   )
  ;; DISCARD-NEXT:  )
  ;; DISCARD-NEXT: )
  (func $call-throw-and-catch
    (try
      (do
        ;; This call cannot be optimized out, as the target throws. However, the
        ;; entire try-catch can be, since the call's only effect is to throw,
        ;; and the catch_all catches that.
        (call $throw)
      )
      (catch_all)
    )
  )

  ;; WITHOUT:      (func $call-unreachable-and-catch (type $none_=>_none)
  ;; WITHOUT-NEXT:  (try $try
  ;; WITHOUT-NEXT:   (do
  ;; WITHOUT-NEXT:    (call $unreachable)
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:   (catch_all
  ;; WITHOUT-NEXT:    (nop)
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $call-unreachable-and-catch (type $none_=>_none)
  ;; INCLUDE-NEXT:  (call $unreachable)
  ;; INCLUDE-NEXT: )
  ;; DISCARD:      (func $call-unreachable-and-catch (type $none_=>_none)
  ;; DISCARD-NEXT:  (try $try
  ;; DISCARD-NEXT:   (do
  ;; DISCARD-NEXT:    (call $unreachable)
  ;; DISCARD-NEXT:   )
  ;; DISCARD-NEXT:   (catch_all
  ;; DISCARD-NEXT:    (nop)
  ;; DISCARD-NEXT:   )
  ;; DISCARD-NEXT:  )
  ;; DISCARD-NEXT: )
  (func $call-unreachable-and-catch
    (try
      (do
        ;; This call has a non-throw effect. We can optimize away the try-catch
        ;; (since no exception can be thrown anyhow), but we must leave the
        ;; call.
        (call $unreachable)
      )
      (catch_all)
    )
  )

  ;; WITHOUT:      (func $call-throw-or-unreachable-and-catch (type $i32_=>_none) (param $x i32)
  ;; WITHOUT-NEXT:  (try $try
  ;; WITHOUT-NEXT:   (do
  ;; WITHOUT-NEXT:    (if
  ;; WITHOUT-NEXT:     (local.get $x)
  ;; WITHOUT-NEXT:     (call $throw)
  ;; WITHOUT-NEXT:     (call $unreachable)
  ;; WITHOUT-NEXT:    )
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:   (catch_all
  ;; WITHOUT-NEXT:    (nop)
  ;; WITHOUT-NEXT:   )
  ;; WITHOUT-NEXT:  )
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $call-throw-or-unreachable-and-catch (type $i32_=>_none) (param $x i32)
  ;; INCLUDE-NEXT:  (try $try
  ;; INCLUDE-NEXT:   (do
  ;; INCLUDE-NEXT:    (if
  ;; INCLUDE-NEXT:     (local.get $x)
  ;; INCLUDE-NEXT:     (call $throw)
  ;; INCLUDE-NEXT:     (call $unreachable)
  ;; INCLUDE-NEXT:    )
  ;; INCLUDE-NEXT:   )
  ;; INCLUDE-NEXT:   (catch_all
  ;; INCLUDE-NEXT:    (nop)
  ;; INCLUDE-NEXT:   )
  ;; INCLUDE-NEXT:  )
  ;; INCLUDE-NEXT: )
  ;; DISCARD:      (func $call-throw-or-unreachable-and-catch (type $i32_=>_none) (param $x i32)
  ;; DISCARD-NEXT:  (try $try
  ;; DISCARD-NEXT:   (do
  ;; DISCARD-NEXT:    (if
  ;; DISCARD-NEXT:     (local.get $x)
  ;; DISCARD-NEXT:     (call $throw)
  ;; DISCARD-NEXT:     (call $unreachable)
  ;; DISCARD-NEXT:    )
  ;; DISCARD-NEXT:   )
  ;; DISCARD-NEXT:   (catch_all
  ;; DISCARD-NEXT:    (nop)
  ;; DISCARD-NEXT:   )
  ;; DISCARD-NEXT:  )
  ;; DISCARD-NEXT: )
  (func $call-throw-or-unreachable-and-catch (param $x i32)
    ;; This try-catch-all's body will either call a throw or an unreachable.
    ;; Since we have both possible effects, we cannot optimize anything here.
    (try
      (do
        (if
          (local.get $x)
          (call $throw)
          (call $unreachable)
        )
      )
      (catch_all)
    )
  )

  ;; WITHOUT:      (func $throw (type $none_=>_none)
  ;; WITHOUT-NEXT:  (throw $tag)
  ;; WITHOUT-NEXT: )
  ;; INCLUDE:      (func $throw (type $none_=>_none)
  ;; INCLUDE-NEXT:  (throw $tag)
  ;; INCLUDE-NEXT: )
  ;; DISCARD:      (func $throw (type $none_=>_none)
  ;; DISCARD-NEXT:  (throw $tag)
  ;; DISCARD-NEXT: )
  (func $throw
    (throw $tag)
  )
)