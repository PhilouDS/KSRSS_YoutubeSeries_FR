list processors in proc.
local idx is 1.
until idx = proc:length {
  if exists("lib" + idx + ":/KSRSS_Outils") {
    runOncePath("lib" + idx + ":/KSRSS_Outils").
    break.
  } else { set idx to idx + 1.}
}
if idx = proc:length {
  runOncePath("main:/KSRSS_Outils").
}

// *** list of all this LIB's functions: *** //
// 01- listOfParts
// 03- listOfTanks
// 04- listOfSolidBoosters
// 05- listOfPartsStage
// 06- listOfEnginesStage
// 07- listOfTanksStage
// 08- listOfSolidBoostersStage
// 09- fuelMassStage
// 10- massStage (mass of one given stage without upper stage)
// 11- caracteristicsStage (for a given stage: list of Mi, Mf, thrust, isp, Ve, q, Delta-v, burning time)
// 11a- initialMass             [0]
// 11b- finalMass               [1]
// 11c- thrustStage             [2]
// 11d- ispStage                [3]
// 11e- effectiveVelocityStage  [4]
// 11f- fuelFlowStage           [5]
// 11g- dvStage                 [6]
// 11h- burningTimeStage        [7]
// 12- totalDV
// 13- calculTWR - added later from an other game


// All the parts of the craft
function listOfParts {
  list PARTS in myPartsList.
  return myPartsList.
}

// All oxidizer tanks
function listOfTanks {
  local tkList to list().
  local shipPartList to listOfParts().
  for part in shipPartList {
    for resource in part:resources {
      if (resource:name = "Oxidizer") and (resource:enabled = true) {
        tkList:add(part).  
      }
    }
  }
  return tkList.
}

// All solid boosters
function listOfSolidBoosters {
  local btList to list().
  local shipPartList to listOfParts().
  for part in shipPartList {
    for resource in part:resources {
      if (resource:name = "solidFuel") and (resource:enabled = true) {
        btList:add(part).  
      }
    }
  }
  return btList.
}

// list of parts in one stage
// stage number in parameter
// Warning: stage of engines are numeroted differently
function listOfPartsStage {
  parameter theStage.
  local stgPart is list().
  local shipPartsList is listOfParts().
  local shipEnginesList is listOfEngines().

  for shipPart in shipPartsList {
    if shipEnginesList:contains(shipPart) {
      if shipPart:stage = theStage {
        stgPart:add(shipPart).
      }
    }
    else {
      if shipPart:stage = theStage - 1 {
        stgPart:add(shipPart).
      }
    }
  }
  return stgPart.
}

// list of engines in one stage
// stage number in parameter
function listOfEnginesStage {
  parameter theStage.
  local stgEngine is list().
  local shipEnginesList is listOfEngines().

  for shipEngine in shipEnginesList {
    if shipEngine:stage = theStage {
      stgEngine:add(shipEngine). 
    }
  }
  return stgEngine.
}

// list of oxdizer tank in one stage
// stage number in parameter
function listOfTanksStage {
  parameter theStage.
  local stgTanks is list().
  local shipTanksList is listOfTanks().

  for shipTank in shipTanksList {
    if shipTank:stage = theStage {
      stgTanks:add(shipTank). 
    }
  }
  return stgTanks.
}

// list of solid Boosters in one stage
// stage number in parameter
function listOfSolidBoostersStage {
  parameter theStage.
  local stgBooster is list().
  local shipBoosterList is listOfSolidBoosters().

  for shipBooster in shipBoosterList {
    if shipBooster:stage = theStage {
      stgBooster:add(shipBooster). 
    }
  }
  return stgBooster.
}

// fuel mass in one stage
// stage number in parameter
function fuelMassStage {
  parameter theStage.
  local fuelMass is 0.
  local enList is listOfEnginesStage(theStage).
  local tkList is listOfTanksStage(theStage).
  local btList is listOfSolidBoostersStage(theStage).
  if tkList:length = 0 {
    for eng in enList {
      local engLex is eng:consumedResources.
      if engLex:hasKey("Ergol liquide") {
        set tkList to listOfTanksStage(theStage - 1).
      }
    }
  }
  for tank in tkList { // LF + OX
    for resource in tank:resources {
      set fuelMass to fuelMass + resource:density * resource:amount.
    }
  }
  
  for bst in btList { // SF
    if bst:stage = (theStage) {
      for resource in bst:resources {
        set fuelMass to fuelMass + resource:density * resource:amount.
      }
    }
  }
  return fuelMass.
}

// mass of one single stage (without the upper stage)
// stage number in parameter
function massStage {
  parameter theStage.
  local stgMass is 0.
  local stgParts is choose listOfPartsStage(theStage) if stage:number <> 0 else listOfParts().
  for prt in stgParts {
    set stgMass to stgMass + prt:mass.
  }
  return stgMass.
}

// All caracteristics of one single stage
// stage number in parameter
global function caracteristicsStage {
  parameter theStage.
  local tmpList is list(
    initialMass(theStage),                    // tmpList[0] : initialMass
    finalMass(theStage),                      // tmpList[1] : finalMass
    thrustStage(theStage),                    // tmpList[2] : thrustStage
    ispStage(theStage)                        // tmpList[3] : ispStage
  ).
  tmpList:add(tmpList[3] * constant:g0).      // tmpList[4] : effective velocity -> Ve = ISP * g0
  local fuelFlow is choose 0 if tmpList[4] = 0 else tmpList[2] / tmpList[4].
  tmpList:add(fuelFlow).       // tmpList[5] : fuel Flow in t/s -> q = F / Ve
  tmpList:add(ship:stageDeltaV(theStage):current).
  //tmpList:add(tmpList[4] * LN(tmpList[0] / tmpList[1])). // tmpList[6] : delta-v = Ve * ln(Mi / Mf)
  
  local burnTime is choose 0 if tmpList[5] = 0 else (tmpList[0] - tmpList[1]) / tmpList[5].
  tmpList:add(burnTime).   // tmpList[7] : burning time = (Mi - Mf) / q
  return tmpList.
}

// Initial mass of a stage
// stage number in parameter
function initialMass{
  parameter theStage.
  local initMass is 0.

  from {local cpt is theStage.}
  until cpt = -1
  step {set cpt to cpt - 1.}
  do {
    set initMass to initMass + massStage (cpt).  
  }
  return initMass.
}

// Final mass of a stage after all the fuel has been consummed
// stage number in parameter
function finalMass{
  parameter theStage.
  return initialMass(theStage) - fuelMassStage(theStage).
}

// Total thrust of a stage counting all the engines of that stage
// stage number in parameter
function thrustStage {
  parameter theStage.
  local stgEngine is listOfEnginesStage(theStage).
  local stgThrust is 0.

  for en in stgEngine {
    set stgThrust to stgThrust + en:possibleThrustAt(ship:body:atm:altitudePressure(ship:altitude)). 
  }
  return stgThrust.
}

// Total ISP of a stage counting all the engines of that stage
// stage number in parameter
function ispStage {
  parameter theStage.
  local sumThrust is 0.
  local sumFuelCons is 0.
  local stgEngine is listOfEnginesStage(theStage).

  for eng in stgEngine {
    set sumThrust to sumThrust + eng:possibleThrustAt(ship:body:atm:altitudePressure(ship:altitude)).
    set sumFuelCons to sumFuelCons + (eng:possibleThrustAt(ship:body:atm:altitudePressure(ship:altitude)) / eng:ispAt(ship:body:atm:altitudePressure(ship:altitude))).
  }
  return choose sumThrust / sumFuelCons if sumFuelCons > 0 else 0.
}

// Effective Velocity Ve of a stage
// stage number in parameter
function effectiveVelocityStage{
  parameter theStage.
  return ispStage(theStage) * constant:g0.
}

// fuel flow of a stage
// stage number in parameter
// /!\ unit is t/s
function fuelFlowStage{
  parameter theStage.
  local fuelFlow is choose 0 if effectiveVelocityStage(theStage) = 0 else thrustStage(theStage) / effectiveVelocityStage(theStage).
  return fuelFlow.
}

// Delta-v of a stage (new version of kOS gives delta-v according to stock game value, I'm not using this)
// stage number in parameter
function dvStage{
  parameter theStage.
  return effectiveVelocityStage(theStage) * LN(initialMass(theStage) / finalMass(theStage)).
}

// burning time of one stage
// stage number in parameter
function burningTimeStage{
  parameter theStage.
  return (initialMass(theStage) - finalMass(theStage)) / fuelFlowStage(theStage).
}

// Total delta-v of a craft
function totalDV {
  local totalDeltaV is 0.
  local initialStage is stage:number.
  until initialStage < 0 {
    set totalDeltaV to totalDeltaV + dvStage(initialStage).
    set initialStage to initialStage - 1.
  }
  return totalDeltaV.
}
