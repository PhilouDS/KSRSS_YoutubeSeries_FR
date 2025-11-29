openTerminal().
copypath("0:/Avion_AP.ks", "1:/auto.ks").
switch to 1.
clearscreen.
print "En attente de 'auto.ks'...".

global function openTerminal {
  parameter theWidth is 40.
  parameter theHeight is 30.
  set terminal:width to theWidth.
  set terminal:height to theHeight.
  clearScreen.
  core:part:getModule("kosProcessor"):doEvent("open terminal").
}