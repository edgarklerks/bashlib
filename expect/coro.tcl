package provide coro 1.0

proc coro_puts { it } {
    while 1 {
	set val [ $it ]
	if { $val == "" } {
	    break
	}
	puts [string trim "$val"]
    }
}
