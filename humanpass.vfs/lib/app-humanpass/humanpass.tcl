package require Tk

option add *tearOff 0;          # tearoff menus must die!

# Non-saved vars
set G(Version) 1.0
set G(Password) ""
set G(SaveFile) ""

# Keys in SaveVars will automatically be saved by save procs
# Their initial values are set in loadDefaults
set G(SaveVars) [list PassChars SepChars NumChars SameSep]

proc createGui {} {
    global G

    set win .
    wm title $win "HumanPass $G(Version)"
    grid columnconfigure $win 0 -weight 1
    wm protocol $win WM_DELETE_WINDOW AppExit

    # Create the gui from scratch, if it exists
    foreach child [winfo children $win] {
        destroy $child
    }

    # Setup main frame
    set f [ttk::frame $win.f]
    grid $f -sticky news -padx 4 -pady 4

    # Setup Menu bar
    set mb [menu $win.mb]
    $win configure -menu $mb

    $mb add cascade -menu $mb.file -label "File" -underline 0
    $mb add command -label "Options" -command [list wm deiconify .options] -underline 0

    # File menu
    set m [menu $mb.file]
    $m add command -label "Open" -underline 0 -command MenuFileOpen -accelerator {Ctrl-o}
    $m add command -label "Save" -underline 0 -command MenuFileSave -accelerator {Ctrl-s}

    bind $win <Control-o> {MenuFileOpen}
    bind $win <Control-s> {MenuFileSave}

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

    bind $win <Key-Return> UpdatePassword

    # Create the Options window
    set win .options
    catch {destroy $win}
    toplevel $win
    wm withdraw $win
    wm title $win "[wm title [winfo parent $win]] - Options"
    grid columnconfigure $win 0 -weight 1

    set f [ttk::frame $win.f]
    grid $f -sticky news -padx 4 -pady 4
    grid columnconfigure $f 1 -weight 1
    set row 0
    foreach {key text} [list PassChars "Password Characters" SepChars "Separator Characters"] {
        set l [ttk::label $f.l$key -text "$text:"]
        set e [ttk::entry $f.e$key -textvariable G($key) -width [string length $G($key)]]
        grid $l $e -row $row -sticky ew -padx 4 -pady 4
        incr row
    }
    wm resizable $win 1 0

    # Prevent the destruction of this window
    bind $win <Key-Escape> [list wm withdraw $win]
    wm protocol $win WM_DELETE_WINDOW [list wm withdraw $win]
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

proc MenuFileOpen {} {
    global G

    # Setup Save TK dialog
    set types {
        {{HumanPass Files} {.hpass}}
        {{All Files} *}
    }
    set initialDir [file dirname $G(SaveFile)]
    set filename [tk_getOpenFile -filetypes $types -title "HumanPass Open File" \
                     -initialdir $initialDir]
    if {$filename ne ""} {
        if {[catch {
            loadState $filename
            set G(SaveFile) $filename
        } err]} {
            tk_messageBox -title "HumanPass Load File Error" -type ok \
                -message "Cannot load file:\n$err"
        }
    }
}

proc MenuFileSave {} {
    global G

    # Setup Save TK dialog
    set types {
        {{HumanPass Files} {.hpass}}
        {{All Files} *}
    }
    set initialDir [file dirname $G(SaveFile)]
    set filename [tk_getSaveFile -filetypes $types -title "HumanPass Save File" \
                     -initialdir $initialDir]
    if {$filename ne ""} {
        # Automatically add file extenstion to files which did not specify one
        if {[string match *.* $filename] == 0} {
            append filename .hpass
        }
        if {[catch {
            saveState $filename
            set G(SaveFile) $filename
        } err]} {
            tk_messageBox -title "HumanPass Save File Error" -type ok \
                -message "Cannot save file:\n$err"
        }
    }
}

# Tries to save the current state and exits
proc AppExit {} {
    if {[catch {
        saveState .appdata
    } err]} {
        puts "Error saving .appdata: $err"
    }
    exit
}

# Tries to load the previous state if it exists and then starts
proc AppStart {} {
    if {[catch {
        loadState .appdata
    } err]} {
        puts "Error loading .appdata: $err"
        loadDefaults
    }
    createGui
}

# Errors are not handled in this proc
proc saveState file {
    global G
    set chan [open $file w]
    foreach var $G(SaveVars) {
        puts $chan "$var $G($var)"
    }
    chan close $chan
}

proc loadState file {
    global G

    # Read in data file
    set chan [open $file r]
    set data [read $chan]
    close $chan

    foreach line [split $data \n] {
        set line [string trim $line]
        lassign $line var val
        if {[lsearch $G(SaveVars) $var] != -1} {
            set G($var) $val
        }
    }
}

proc loadDefaults {} {
    global G
    set G(PassChars) "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    set G(SepChars) "\\/^*=+-_.,:;'~\""
    set G(NumChars) 16
    set G(SameSep) 0
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

package provide app-humanpass $G(Version)

# EOF
