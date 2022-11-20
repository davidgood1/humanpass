package provide app-humanpass 1.0

package require Tk

set G(PassChars) "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
set G(SepChars) "\\/^*=+-_.,:;'~\""
set G(NumChars) 16
set G(SameSep) 0
set G(Password) ""

proc createGui {} {

    set win .
    grid columnconfigure $win 0 -weight 1

    # Create the gui from scratch, if it exists
    foreach child [winfo children $win] {
        destroy $child
    }

    # Setup main frame
    set f [ttk::frame $win.f]
    grid $f -sticky news -padx 4 -pady 4

    # TODO: save / load menu

    # Options menu

    set l [ttk::label $f.lChars -text "Characters:"]
    set sb [ttk::spinbox $f.sb -textvariable G(NumChars) -width 4 -from 4 -to 128]
    set c [ttk::checkbutton $f.cSameSep -text "Same Seperator" -variable G(SameSep)]
    set b [ttk::button $f.bGenerate -text "Generate" -command UpdatePassword]
    set e [ttk::entry $f.ePassword -textvariable G(Password) -state normal]

    grid $l $sb $c $b -sticky w -padx 4 -pady 4
    grid configure $b -sticky ew
    grid $e -columnspan 4 -sticky ew -padx 4 -pady 4
    grid columnconfigure $f 3 -weight 1

    wm geometry $win {}
    wm resizable $win 1 0
}

proc UpdatePassword {} {
    global G
    if {[catch {
        set args [list $G(PassChars) $G(SepChars) $G(NumChars)]
        if {$G(SameSep)} {
            set args [linsert $args 0 -sameseparator]
        }
        set G(Password) [humanPass {*}$args]
    } err]} {
        set G(Password) $err
    }
}


# humanPass ?-sameseparator? passChars sepChars numPassChars
proc humanPass {args} {
    set usageMsg "humanPass ?-sameseparator? passChars sepChars numPassChars"

    # Handle the option flag
    set i [lsearch $args -sameseparator]
    set sameSep [expr $i != -1]
    if {$sameSep} {
        set args [lreplace $args $i $i]
    }

    # Validate the arguments
    if {[llength $args] != 3} {
        error "wrong # args: should be \"$usageMsg\""
    }
    lassign $args passChars sepChars numPassChars
    if {! [string is integer $numPassChars]} {
        error "numPassChars should be an integer but was \"$numPassChars\""
    }

    # Generate random pass chars
    set str ""
    set sep ""
    for {set num 0} {$num < $numPassChars} {incr num} {
        # Add separator if this is the beginning of a new group (skipping the first)
        if {[expr $num % 4] == 0 && $num != 0} {
            if {$sameSep == 0 || $sep eq ""} {
                set sep [string index $sepChars [expr int(rand() * [string length $sepChars])]]
            }
            append str $sep
        }
        append str [string index $passChars [expr int(rand() * [string length $passChars])]]
    }
    return $str
}

# EOF
