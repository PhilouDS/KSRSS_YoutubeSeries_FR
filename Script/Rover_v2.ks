parameter wheelSpeed is 5.
parameter wheelPIDcap is 0.05.




clearScreen.
wait 1.
lights on.
brakes on.

set start_row to 0.

set wpoint to select_wp().

if wpoint = "" {}
else {
    for wp in allWaypoints() {
        if wp:name = wpoint {
            set destination to wp.
        }
    }
    set target_lat to destination:geoposition:lat.
    set target_lng to destination:geoposition:lng.
    local mainTarget is LatLng(target_lat, target_lng).
    print "Cible acquise : " + destination:name at (0,start_row).
    print " Latitude : " + round(target_lat, 3) + "°" at (0,start_row+1).
    print "Longitude : " + round(target_lng, 3) + "°" at (0,start_row+2).

    brakes off.
    // initialisation Vitesse
    set wheelThrottlePID to 0.
    set speedPID to PIDLoop(0.3, 0.1, 0.1, -1, 1).
    set speedPID:setPoint to wheelSpeed.

    lock wheelThrottle to wheelThrottlePID.

    // initialisation Direction
    set wheelDirection to 0.
    set turnPID TO PIDLOOP(0.01, 0.001, 0.01, -1*wheelPIDcap, wheelPIDcap).
    set turnPID:setPoint to 0.

    print "Démarrage !" at (0,start_row+4).

    until ship:velocity:surface:mag > min(wheelSpeed-2, 7) {
        // MaJ vitesse :
        set myVelocity to ship:velocity:surface:mag.
        set wheelThrottlePID to speedPID:UPDATE(time:seconds, myVelocity).
        // MaJ direction :
        set myHeading to mainTarget:bearing.
        set wheelDirection to turnPID:UPDATE(TIME:SECONDS,myHeading).
        set ship:control:wheelsteer to wheelDirection.
        print "Distance à la cible : " + round(mainTarget:distance, 1) + (" m   ") at (0,start_row+6).
        print "   Angle à la cible : " + round(mainTarget:bearing, 1) + ("°   ") at (0,start_row+7).
        wait 0.1.
    }

    print "En route ! " at (0,start_row+4).
    set turnPID TO PIDLOOP(0.01,0.001,0.01,-0.005,0.005).

    until mainTarget:distance < 250 {
        // MaJ vitesse :
        set myVelocity to ship:velocity:surface:mag.
        set wheelThrottlePID to speedPID:UPDATE(time:seconds, myVelocity).
        // MaJ direction :
        set myHeading to mainTarget:bearing.
        set wheelDirection to turnPID:UPDATE(TIME:SECONDS,myHeading).
        set ship:control:wheelsteer to wheelDirection.
        print "Distance à la cible : " + round(mainTarget:distance, 1) + (" m   ") at (0,start_row+6).
        print "   Angle à la cible : " + round(mainTarget:bearing, 1) + ("°   ") at (0,start_row+7).
        print "    Cap de la cible : " + round(mainTarget:heading, 1) + ("°   ") at (0,start_row+8).
        print "   Vitesse actuelle : " + round(ship:velocity:surface:mag, 1) + (" m/s   ") at (0,start_row+10).

        set actual_biome to addons:scanSat:getBiome(ship:body, ship:geoPosition).
        print "              Biome : " + actual_biome + "                    " at (0,start_row+12).
        wait 0.1.
    }

    print "Moins de 250 m !" at (0,start_row+4).

    set speedPID:setPoint to min(wheelSpeed, 10).

    until mainTarget:distance < 100 {
        // MaJ vitesse :
        set myVelocity to ship:velocity:surface:mag.
        set wheelThrottlePID to speedPID:UPDATE(time:seconds, myVelocity).
        // MaJ direction :
        set myHeading to mainTarget:bearing.
        set wheelDirection to turnPID:UPDATE(TIME:SECONDS,myHeading).
        set ship:control:wheelsteer to wheelDirection.
        print "Distance à la cible : " + round(mainTarget:distance, 1) + (" m   ") at (0,start_row+6).
        print "   Angle à la cible : " + round(mainTarget:bearing, 1) + ("°   ") at (0,start_row+7).
        print "    Cap de la cible : " + round(mainTarget:heading, 1) + ("°   ") at (0,start_row+8).
        print "   Vitesse actuelle : " + round(ship:velocity:surface:mag, 1) + (" m/s   ") at (0,start_row+10).

        set actual_biome to addons:scanSat:getBiome(ship:body, ship:geoPosition).
        print "              Biome : " + actual_biome + "                    " at (0,start_row+12).
        wait 0.1.
    }

    print "Moins de 100 m !" at (0,start_row+4).

    set speedPID:setPoint to min(wheelSpeed, 3).

    until mainTarget:distance < 20 {
        // MaJ vitesse :
        set myVelocity to ship:velocity:surface:mag.
        set wheelThrottlePID to speedPID:UPDATE(time:seconds, myVelocity).
        // MaJ direction :
        set myHeading to mainTarget:bearing.
        set wheelDirection to turnPID:UPDATE(TIME:SECONDS,myHeading).
        set ship:control:wheelsteer to wheelDirection.
        print "Distance à la cible : " + round(mainTarget:distance, 1) + (" m   ") at (0,start_row+6).
        print "   Angle à la cible : " + round(mainTarget:bearing, 1) + ("°   ") at (0,start_row+7).
        print "    Cap de la cible : " + round(mainTarget:heading, 1) + ("°   ") at (0,start_row+8).
        print "   Vitesse actuelle : " + round(ship:velocity:surface:mag, 1) + (" m/s   ") at (0,start_row+10).

        set actual_biome to addons:scanSat:getBiome(ship:body, ship:geoPosition).
        print "              Biome : " + actual_biome + "                    " at (0,start_row+12).
        wait 0.1.
    }

    lock wheelThrottle to 0.
    brakes on.

    until ship:velocity:surface:mag < 0.01 {
        print "Distance à la cible : " + round(mainTarget:distance, 1) + (" m   ") at (0,start_row+6).
        print "   Angle à la cible : " + round(mainTarget:bearing, 1) + ("°   ") at (0,start_row+7).
        print "    Cap de la cible : " + round(mainTarget:heading, 1) + ("°   ") at (0,start_row+8).
        print "   Vitesse actuelle : " + round(ship:velocity:surface:mag, 1) + (" m/s   ") at (0,start_row+10).

        set actual_biome to addons:scanSat:getBiome(ship:body, ship:geoPosition).
        print "              Biome : " + actual_biome + "                    " at (0,start_row+12).
    }

    print "Destination atteinte !" at (0,start_row+14).
    print "Fin du programme..." at (0,start_row+15).

    unlock wheelThrottle.
    wait 0.
    set ship:control:wheelsteer to 0.
    wait 2.
    clearScreen.

    print "En attente de nouvelles instructions." at (0,1).
    print "Utiliser le programme suivant :" at (0,2).
    print "=========================================" at (0,3).
    print "run rover(vitesse max, coef braquage max)" at (0,4).
    print "=========================================" at (0,5).
    print "      Vitesse max : 10 m/s" at (0,6).
    print "Coef braquage max : 0.5" at (0,7).
}



function select_wp {
    set stopWP to false.
    set liste_points to list().

    for wp in allWaypoints() {
        if wp:body = ship:body {
            liste_points:add(wp).
        }
    }.


    set listewp_largeur to 300.
    set listewp_hauteur to 100.

    local listewp is gui(listewp_largeur, listewp_hauteur).
    set listewp:y to 250.

    set listewp:skin:font to "Consolas".
    set listewp:skin:label:fontsize to 12.
    set listewp:skin:label:hstretch to true.
    set listewp:skin:label:align to "center".

    local nomRover is listewp:addLabel().
        set nomRover:text to "<b>" + ship:name + "</b>".
        set nomRover:style:textcolor to RGB(254/255, 80/255, 0).
        set nomRover:style:fontSize to 20.

    listewp:addSpacing(15).

    local theText is listewp:addLabel("Destination ?").

    listewp:addSpacing(15).

    local chooseFile_window is listewp:addVbox().

    local popupMenuList is chooseFile_window:addpopupmenu().
    for wp in liste_points {popupMenuList:addoption(wp:name).}

    listewp:addSpacing(15).

    local buttonSpace is listewp:addVlayout().

    local runButton is buttonSpace:addButton().
    set runButton:text to "VALIDER".

    buttonSpace:addSpacing(5).

    local cancelButton is buttonSpace:addButton().
    set cancelButton:text to "ANNULER".

    listewp:show().

    until stopWP = true {
        if runButton:takePress {
            set theWP to popupMenuList:value.
            listewp:dispose().
            set stopWP to true.
            return theWP.
        }

        if cancelButton:takePress {
            listewp:dispose().
            set stopWP to true.
            core:part:getModule("kosProcessor"):doEvent("open terminal").
            return "".
        }
    }
}