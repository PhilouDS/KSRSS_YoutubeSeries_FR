wait until homeConnection:isconnected.
clearscreen.
set terminal:width to 45.
set terminal:height to 30.
core:part:getModule("kosProcessor"):doEvent("open terminal").

set libFolder to "0:/KSRSS_LIB/".
set ksmFolder to "0:/KSM_LIB/".
wait 0.5.
compileToKSM(libFolder, ksmFolder).
wait 0.5.
set missionFolder to "0:/KSRSS_MISSIONS/".
set mission_name to select_mission().
if mission_name = "" {}
else {
clearScreen.

wait until ship:unpacked.
wait until kuniverse:canquicksave.
kuniverse:quicksave().
wait 0.

print "Sauvegarde rapide effectuée".
wait 0.

set config:suppressAutoPilot to false.


print "Chargement...".
print "Veuillez patienter...".
print " ".

wait 0.5.

cd(missionFolder).
list files in missionList.
for f in missionList {
  if f:name = mission_name + ".ks" {
    set mission_file to f.
    break.
  }
}

set core:volume:name to "main".
list processors in proc.

for p in proc {
  if p:volume:name <> "main" {
    set p:volume:name to "lib".
  }
}

cd(ksmFolder).

list files in fileList.
for f in fileList {
  if not(f:name = "KSRSS_En-vol.ksm" OR f:name = "KSRSS_Lancement.ksm") {
    set theLib to ksmFolder + f:name.
    if (f:size < volume("lib"):freespace) {
      copypath(theLib, "lib:/" + f:name).
      print ("Bibliothèque " + f:name + " copiée sur disque 'lib'.").
    } else {
      copypath(theLib, "main:/" + f:name).
      print ("Bibliothèque " + f:name + " copiée sur disque 'main'.").
    }
    wait 0.1.
  }
}

print (" ").
runOncePath(ksmFolder + "KSRSS_Lancement.ksm").
print ("Bibliothèque KSRSS_Lancement en cours d'exécution.").
wait 0.1.
runOncePath(ksmFolder + "KSRSS_En-vol.ksm").
print ("Bibliothèque KSRSS_En-vol en cours d'exécution.").
wait 0.1.

print " ".

wait 0.5.

compile(missionFolder + mission_name + ".ks").
print "Mission compilée".
if volume("main"):freespace < mission_file:size {
  print " ".
  print "Espace insuffisant !".
  print "Fin du programme.".
  shutdown.
}.
wait 0.1.
copypath(missionFolder + mission_name + ".ksm", "main:/" + mission_name + ".ksm").
wait 0.
print "Mission chargée".
wait 0.1.

startSave().

switch to 1.

from {local monCompteur is 3.}
until monCompteur = 0
step {set monCompteur to monCompteur - 1.}
do {
  print "EXÉCUTION DU PROGRAMME " at (0,27).
  print "       DE MISSION DANS  =>  " + monCompteur at (0,28).
  wait 1.
}

runpath("main:/" + mission_name).
}


function select_mission {
  //core:part:getModule("kosProcessor"):doEvent("open terminal").
  set stopRunFromArchive to false.
  cd(missionFolder).

  list files in tempList.
  set fileListTemp to list().
  for f in tempList {fileListTemp:add(f).}.

  set fileList to list().
  for f in fileListTemp {
    fileList:insert(0,f).
  }

  set listOfFiles_wide to 300.
  set listOfFiles_height to 100.

  local listOfFiles is gui(listOfFiles_wide, listOfFiles_height).
  set listOfFiles:y to 250.

  set listOfFiles:skin:font to "Consolas".
  set listOfFiles:skin:label:fontsize to 12.
  set listOfFiles:skin:label:hstretch to true.
  set listOfFiles:skin:label:align to "center".

  local probeName is listOfFiles:addLabel().
      set probeName:text to "<b>" + ship:name + "</b>".
      set probeName:style:textcolor to RGB(254/255, 80/255, 0).
      set probeName:style:fontSize to 20.

  listOfFiles:addSpacing(15).

  local theText is listOfFiles:addLabel("Script ?").

  listOfFiles:addSpacing(15).

  local chooseFile_window is listOfFiles:addVbox().

  local popupMenuList is chooseFile_window:addpopupmenu().
  for f in fileList {popupMenuList:addoption(f:name).}

  listOfFiles:addSpacing(15).

  local buttonSpace is listOfFiles:addVlayout().

  local runButton is buttonSpace:addButton().
  set runButton:text to "VALIDER".

  buttonSpace:addSpacing(5).

  local cancelButton is buttonSpace:addButton().
  set cancelButton:text to "ANNULER".



  listOfFiles:show().

  until stopRunFromArchive = true {
    if runButton:takePress {
      set theFile to popupMenuList:value.
      listOfFiles:dispose().
      set stopRunFromArchive to true.
      return theFile:remove(theFile:length - 3, 3). // supprimer ".ks" à la fin du nom
    }

    if cancelButton:takePress {
      listOfFiles:dispose().
      set stopRunFromArchive to true.
      core:part:getModule("kosProcessor"):doEvent("open terminal").
      return "".
    }
  }
}







function compileToKSM {
  parameter fromFolder.
  parameter toFolder.
  cd(fromFolder).
  list files in allFiles.

  local start_row is 0.

  local nbFiles is allFiles:length.
  local perc is 100 / nbFiles.
  print nbFiles + " files extracted..." at (0,start_row).
  wait 0.5.


  for f in allFiles {
    local fName is f:name:remove(f:name:length - 3, 3).
    print "compiling file " + fName + "                       " at (0, start_row+2).
    local progress is (allFiles:indexOf(f) + 1)*perc.
    print round(progress, 2) + "% / 100%     " at (0, start_row+3).
    compile f to toFolder + fName + ".ksm".
    wait 0.1.
  }

  print "Compilation done" at (0, start_row+6).
}