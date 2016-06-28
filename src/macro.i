.macro pushm reg0 reg1
   push  \reg0
.if \reg1-\reg0
   pushm "(\reg0+1)",\reg1
.endif
.endm

.macro popm reg0 reg1
   pop   \reg1
.if \reg1-\reg0
   popm  \reg0,"(\reg1-1)"
.endif
.endm

