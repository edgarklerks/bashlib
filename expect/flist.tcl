package provide flist 1.0
#/#
# List utilities, which can linearize recursion
#/#

# Shift, modifies the list in place and returns the first element
# @param varname the list name
# @return the first element of the list
proc lshift { varname } {
    upvar 1 $varname lst
    set res [lindex $lst 0]
    set lst [lreplace $lst 0 0]
    return $res
}
# Pop, modifies the list in place and returns the last element
# @param varname the list name
# @return the last element of the list
proc lpop { varname } {
    upvar 1 $varname lst
    set res [lindex $lst end]
    set lst [lreplace $lst end end]
    return $res
}


# A self modifying recursive map, the body of this procedure can append new elements, which will be looped over too.
# It is a general recursive operator, infinite loops are possible, so watch out.
# The nice thing about this thing, is that it makes a potentially recursive function
# non-recursive. It eliminates recursion..
# E.g. normally a function should call itself if it encounter something it wants to recurse on,
# here we only need to add it to the list and it is mapped over.
#
# @param varname name of the variable containing the element
# @param lstname name of the list containing the entries to map over
# @param body the block with varname and lstname
# @return the value from each evaluated body as list

proc rmap { varname lstname body }  {
    upvar 1 $varname var
    upvar 1 $lstname lst
    lappend res
    set n [llength $lst]
    while { $n > 0} {
	set var [lshift lst]
	lappend res [uplevel 1 $body]
	set n [ llength $lst ]
    }
    return $res
}
