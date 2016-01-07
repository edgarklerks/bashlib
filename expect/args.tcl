package provide args 1.0
proc argv_xxx  { keyword varg }  {
    foreach arg  $varg {
	set match [regexp -inline "^-$keyword=(.*)" $arg ]
	if { [ llength $match ] > 0 } {
	    return [lindex $match 1]
	}
    }
    puts stderr "Expected -$keyword=<$keyword>"
    exit 1
}

proc argv_password { } {
    upvar 1 argv varg
    return [argv_xxx passwd $varg]
}

proc argv_user { } {
    upvar 1 argv varg
    return [argv_xxx user $varg]
}

proc argv_host { } {
    upvar 1 argv varg
    return [argv_xxx host $varg]
}

proc argv_rest { } {
    upvar 1 argv varg
    lappend accum
    foreach arg $varg {
	set match [regexp "^-{1}" $arg]
	if { ! $match } {
	    lappend accum $arg
	}
    }
    return $accum
}
