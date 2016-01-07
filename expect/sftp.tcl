package provide sftp 1.0
package require Expect
package require flist
package require args
#/#
# This modules defines a couple of functions to communicate with sftp, while respecting
# the unix text interface.
# The functions are coroutines, which makes it easy to compose them in more complicated
# assembles of functionality, which still respecting the text interface (a bit like pipelines). Actually you can just view them as generators here.
#/#
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


# Log into a sftp system.
# This will intialize the sftp system itself.
# @param sftp_user the user to login with
# @param sftp_host the host to be logged on
# @param sftp_password the password associated with the user
proc sftp_login {sftp_user sftp_host sftp_password} {
    uplevel 1 spawn sftp  $sftp_user@$sftp_host
    expect "${sftp_user}@${sftp_host}'s password:" {
	send "$sftp_password\r"
    }
    expect sftp>
}

# Logout again
proc sftp_logout {} {
    send "bye \r"
}

# Put a local file to remote
# @param src the src path
# @param dst the destination path
proc sftp_put { src dst } {
    send "mput $src $dst"
    expect sftp>
}

# Get a remote file to local
# @param src the remote file
# @param dst the local path
proc sftp_get { src dst } {
    send "mget $src $dest"
    expect sftp>
}

# Recursively list all files from curdir downwards.
# @param curdir directory to list
# @target coroutine to which to yield
proc sftp_ls_r {curdir {target ""}} {
    set dirnames {}
    lappend dirnames $curdir


    rmap dir dirnames {
	set buf {}
	send "ls -l $dir \r"
	expect sftp> {
	    set buf [split $expect_out(buffer) "\n"]
	}

	foreach  lineindex [lsearch -regex -all $buf "^-"] {
	    if { $target eq "" } {
	    yield "$dir/[lindex [lrange [split [lindex $buf $lineindex ] " "] end end] 0]"
	    } else {
		yieldto $target "$dir/[lindex [lrange [split [lindex $buf $lineindex ] " "] end end] 0]"
	    }
	}

	set dirindicess [lsearch -regex -all $buf "^d"]
	foreach dirindex $dirindicess {
	    set adddir "$dir/[lindex [lrange [split [lindex $buf $dirindex ] " "] end end] 0]"
	    lappend dirnames [string replace $adddir end end]
	}

    }
    yield
}
# List all files from curdir.
# @param curdir directory to list
# @target coroutine to which to yield
proc sftp_ls {curdir {target ""}} {
   send "ls -l $curdir \r"
    expect sftp> {
	set buf [split $expect_out(buffer) "\n"]
    }

    foreach  lineindex [lsearch -regex -all $buf "^(-|d)"] {
	    if { $target eq "" } {
		yield "$curdir/[lindex [lrange [split [lindex $buf $lineindex ] " "] end end] 0]"
	    } else {
		yieldto $target "$curdir/[lindex [lrange [split [lindex $buf $lineindex ] " "] end end] 0]"
	    }

    }

    yield
}

# List all files from curdir with file details.
# @param curdir directory to list
# @target coroutine to which to yield
proc sftp_ls_l { curdir {target ""}} {
   send "ls -l $curdir \r"
    expect sftp> {
	set buf [split $expect_out(buffer) "\n"]
    }

    foreach  lineindex [lsearch -regex -all $buf "^(-|d)"] {
		set parts [split [lindex $buf $lineindex ] " "]
		set newdir [join [lreplace $parts end end "$curdir/[lindex $parts end]"] " "]
		set newdir [trim $newdir]

	    if { $target eq "" } {
		yield $newdir
	    } else {
		yieldto $target $newdir
	    }

    }

    yield
}
