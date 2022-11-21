if {[catch {package require starkit} err]} {
    lappend auto_path [file join [file dirname [info script]] lib]
} elseif {[starkit::startup] ne "sourced"} {
    lappend auto_path [file join [file dirname [info script]] lib]
}
package require app-humanpass
AppStart
