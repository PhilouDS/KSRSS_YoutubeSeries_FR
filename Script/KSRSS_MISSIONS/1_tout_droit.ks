clearScreen.
wait until ship:unpacked.

runOncePath("0:/KSRSS_LIB/KSRSS_Outils.ks").
runOncePath("0:/KSRSS_LIB/KSRSS_Lancement.ks").
runOncePath("0:/KSRSS_LIB/KSRSS_En-vol.ks").

logMission("EXPÉRIENCES ATMOSPHÉRIQUES ET SPATIALES").
logGeneralInfo().

clearScreen.

set maxAlt to ship:altitude.

when ship:altitude > maxAlt then {
  set maxAlt to ship:altitude.
  wait 0.1.
  preserve.
}

lock steering to heading(90,90).

prelaunch().
decollage(0).
triggerStaging(0).
wait 1.
print "Programme en cours.".
wait until ship:verticalspeed < 0.
wait 1.
endProgram(maxAlt, 0).
