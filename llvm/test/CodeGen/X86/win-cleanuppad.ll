; RUN: llc -mtriple=i686-pc-windows-msvc < %s | FileCheck --check-prefix=X86 %s
; RUN: llc -mtriple=x86_64-pc-windows-msvc < %s | FileCheck --check-prefix=X64 %s

%struct.Dtor = type { i8 }

define void @simple_cleanup() #0 personality i8* bitcast (i32 (...)* @__CxxFrameHandler3 to i8*) {
entry:
  %o = alloca %struct.Dtor, align 1
  invoke void @f(i32 1)
          to label %invoke.cont unwind label %ehcleanup

invoke.cont:                                      ; preds = %entry
  call x86_thiscallcc void @"\01??1Dtor@@QAE@XZ"(%struct.Dtor* %o) #2
  ret void

ehcleanup:                                        ; preds = %entry
  %0 = cleanuppad []
  call x86_thiscallcc void @"\01??1Dtor@@QAE@XZ"(%struct.Dtor* %o) #2
  cleanupret %0 unwind to caller
}

declare void @f(i32) #0

declare i32 @__CxxFrameHandler3(...)

; Function Attrs: nounwind
declare x86_thiscallcc void @"\01??1Dtor@@QAE@XZ"(%struct.Dtor*) #1

define void @nested_cleanup() #0 personality i8* bitcast (i32 (...)* @__CxxFrameHandler3 to i8*) {
entry:
  %o1 = alloca %struct.Dtor, align 1
  %o2 = alloca %struct.Dtor, align 1
  invoke void @f(i32 1)
          to label %invoke.cont unwind label %cleanup.outer

invoke.cont:                                      ; preds = %entry
  invoke void @f(i32 2)
          to label %invoke.cont.1 unwind label %cleanup.inner

invoke.cont.1:                                    ; preds = %invoke.cont
  call x86_thiscallcc void @"\01??1Dtor@@QAE@XZ"(%struct.Dtor* %o2) #2
  invoke void @f(i32 3)
          to label %invoke.cont.2 unwind label %cleanup.outer

invoke.cont.2:                                    ; preds = %invoke.cont.1
  call x86_thiscallcc void @"\01??1Dtor@@QAE@XZ"(%struct.Dtor* %o1) #2
  ret void

cleanup.inner:                                        ; preds = %invoke.cont
  %0 = cleanuppad []
  call x86_thiscallcc void @"\01??1Dtor@@QAE@XZ"(%struct.Dtor* %o2) #2
  cleanupret %0 unwind label %cleanup.outer

cleanup.outer:                                      ; preds = %invoke.cont.1, %cleanup.inner, %entry
  %1 = cleanuppad []
  call x86_thiscallcc void @"\01??1Dtor@@QAE@XZ"(%struct.Dtor* %o1) #2
  cleanupret %1 unwind to caller
}

; X86-LABEL: _nested_cleanup:
; X86: movl    $1, (%esp)
; X86: calll   _f
; X86: movl    $2, (%esp)
; X86: calll   _f
; X86: movl    $3, (%esp)
; X86: calll   _f

; X86: LBB1_[[cleanup_inner:[0-9]+]]: # %cleanup.inner
; X86: pushl %ebp
; X86: leal    {{.*}}(%ebp), %ecx
; X86: calll   "??1Dtor@@QAE@XZ"
; X86: popl %ebp
; X86: retl

; X86: LBB1_[[cleanup_outer:[0-9]+]]: # %cleanup.outer
; X86: pushl %ebp
; X86: leal    {{.*}}(%ebp), %ecx
; X86: calll   "??1Dtor@@QAE@XZ"
; X86: popl %ebp
; X86: retl

; X86: L__ehtable$nested_cleanup:
; X86:         .long   429065506
; X86:         .long   2
; X86:         .long   ($stateUnwindMap$nested_cleanup)
; X86:         .long   0
; X86:         .long   0
; X86:         .long   0
; X86:         .long   0
; X86:         .long   0
; X86:         .long   1
; X86: $stateUnwindMap$nested_cleanup:
; X86:         .long   -1
; X86:         .long   LBB1_[[cleanup_outer]]
; X86:         .long   0
; X86:         .long   LBB1_[[cleanup_inner]]

; X64-LABEL: nested_cleanup:
; X64: .Lfunc_begin1:
; X64: .Ltmp8:
; X64: movl    $1, %ecx
; X64: callq   f
; X64: .Ltmp10:
; X64: movl    $2, %ecx
; X64: callq   f
; X64: .Ltmp11:
; X64: callq   "??1Dtor@@QAE@XZ"
; X64: .Ltmp12:
; X64: movl    $3, %ecx
; X64: callq   f
; X64: .Ltmp13:

; X64: .LBB1_[[cleanup_inner:[0-9]+]]: # %cleanup.inner
; X64: pushq %rbp
; X64: leaq    {{.*}}(%rbp), %rcx
; X64: callq   "??1Dtor@@QAE@XZ"
; X64: popq %rbp
; X64: retq

; X64: .LBB1_[[cleanup_outer:[0-9]+]]: # %cleanup.outer
; X64: pushq %rbp
; X64: leaq    {{.*}}(%rbp), %rcx
; X64: callq   "??1Dtor@@QAE@XZ"
; X64: popq %rbp
; X64: retq

; X64: .seh_handlerdata
; X64-NEXT: .long   ($cppxdata$nested_cleanup)@IMGREL
; X64-NEXT: .align  4
; X64: $cppxdata$nested_cleanup:
; X64-NEXT: .long   429065506
; X64-NEXT: .long   2
; X64-NEXT: .long   ($stateUnwindMap$nested_cleanup)@IMGREL
; X64-NEXT: .long   0
; X64-NEXT: .long   0
; X64-NEXT: .long   5
; X64-NEXT: .long   ($ip2state$nested_cleanup)@IMGREL
; X64-NEXT: .long   40
; X64-NEXT: .long   0
; X64-NEXT: .long   1

; X64: $stateUnwindMap$nested_cleanup:
; X64-NEXT: .long   -1
; X64-NEXT: .long   .LBB1_[[cleanup_outer]]@IMGREL
; X64-NEXT: .long   0
; X64-NEXT: .long   .LBB1_[[cleanup_inner]]@IMGREL

; X64: $ip2state$nested_cleanup:
; X64-NEXT: .long   .Lfunc_begin1@IMGREL
; X64-NEXT: .long   -1
; X64-NEXT: .long   .Ltmp8@IMGREL
; X64-NEXT: .long   0
; X64-NEXT: .long   .Ltmp10@IMGREL
; X64-NEXT: .long   1
; X64-NEXT: .long   .Ltmp12@IMGREL
; X64-NEXT: .long   0
; X64-NEXT: .long   .Ltmp13@IMGREL+1
; X64-NEXT: .long   -1

attributes #0 = { "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind }
