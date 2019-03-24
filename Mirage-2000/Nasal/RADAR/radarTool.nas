var RadarTool = {
  isNotBehindTerrain: func(SelectedObject){
        if(SelectedObject.get_Callsign()=="GROUND_TARGET"){return 1;}
        isVisible = 0;
        
        # As the script is relatively ressource consuming, then, we do a maximum of test before doing it
        if(me.get_check())
        {
            SelectCoord = SelectedObject.get_Coord();
            
            SelectCoord.set_alt(SelectCoord.alt()+1);
            # Because there is no terrain on earth that can be between these 2
            if(me.our_alt < 8900 and SelectCoord.alt() < 8900)
            {
              if (pickingMethod == 1) {
                  var myPos = geo.aircraft_position();

                  var xyz = {"x":myPos.x(),                  "y":myPos.y(),                 "z":myPos.z()};
                  var dir = {"x":SelectCoord.x()-myPos.x(),  "y":SelectCoord.y()-myPos.y(), "z":SelectCoord.z()-myPos.z()};

                  # Check for terrain between own aircraft and other:
                  v = get_cart_ground_intersection(xyz, dir);
                  if (v == nil) {
                    return 1;
                    #printf("No terrain, planes has clear view of each other");
                  } else {
                  var terrain = geo.Coord.new();
                  terrain.set_latlon(v.lat, v.lon, v.elevation);
                  var maxDist = myPos.direct_distance_to(SelectCoord);
                  var terrainDist = myPos.direct_distance_to(terrain);
                  if (terrainDist < maxDist) {
                    #print("terrain found between the planes");
                    return 0;
                  } else {
                      #print("The planes has clear view of each other");
                      return 1;
                  }
                  }
                } else {
            
            
                  # Temporary variable
                  # A (our plane) coord in meters
                  a = me.MyCoord.x();
                  b = me.MyCoord.y();
                  c = me.MyCoord.z();
                  # B (target) coord in meters
                  d = SelectCoord.x();
                  e = SelectCoord.y();
                  f = SelectCoord.z();
                  x = 0;
                  y = 0;
                  z = 0;
                  RecalculatedL = 0;
                  difa = d - a;
                  difb = e - b;
                  difc = f - c;
                  # direct Distance in meters
                  myDistance = SelectCoord.direct_distance_to(me.MyCoord);
                  Aprime = geo.Coord.new();
                  
                  # Here is to limit FPS drop on very long distance
                  L = 500;
                  if(myDistance > 50000)
                  {
                      L = myDistance / 15;
                  }
                  step = L;
                  maxLoops = int(myDistance / L);
                  
                  isVisible = 1;
                  # This loop will make travel a point between us and the target and check if there is terrain
                  for(var i = 0 ; i < maxLoops ; i += 1)
                  {
                      L = i * step;
                      K = (L * L) / (1 + (-1 / difa) * (-1 / difa) * (difb * difb + difc * difc));
                      DELTA = (-2 * a) * (-2 * a) - 4 * (a * a - K);
                      
                      if(DELTA >= 0)
                      {
                          # So 2 solutions or 0 (1 if DELTA = 0 but that 's just 2 solution in 1)
                          x1 = (-(-2 * a) + math.sqrt(DELTA)) / 2;
                          x2 = (-(-2 * a) - math.sqrt(DELTA)) / 2;
                          # So 2 y points here
                          y1 = b + (x1 - a) * (difb) / (difa);
                          y2 = b + (x2 - a) * (difb) / (difa);
                          # So 2 z points here
                          z1 = c + (x1 - a) * (difc) / (difa);
                          z2 = c + (x2 - a) * (difc) / (difa);
                          # Creation Of 2 points
                          Aprime1  = geo.Coord.new();
                          Aprime1.set_xyz(x1, y1, z1);
                          
                          Aprime2  = geo.Coord.new();
                          Aprime2.set_xyz(x2, y2, z2);
                          
                          # Here is where we choose the good
                          if(math.round((myDistance - L), 2) == math.round(Aprime1.direct_distance_to(SelectCoord), 2))
                          {
                              Aprime.set_xyz(x1, y1, z1);
                          }
                          else
                          {
                              Aprime.set_xyz(x2, y2, z2);
                          }
                          AprimeLat = Aprime.lat();
                          Aprimelon = Aprime.lon();
                          AprimeTerrainAlt = geo.elevation(AprimeLat, Aprimelon);
                          if(AprimeTerrainAlt == nil)
                          {
                              AprimeTerrainAlt = 0;
                          }
                          
                          if(AprimeTerrainAlt > Aprime.alt())
                          {
                              isVisible = 0;
                          }
                      }
                  }
                }
            }
            else
            {
                isVisible = 1;
            }
        }
        return isVisible;
    },
    NotBeyondHorizon: func(SelectedObject){
        if(SelectedObject.get_Callsign()=="GROUND_TARGET"){return 1;}
        # if distance is beyond the earth curve
        var horizon = SelectedObject.get_horizon(me.our_alt);
        var u_rng = me.targetRange(SelectedObject);
        #print("u_rng : " ~ u_rng ~ ", Horizon : " ~ horizon);
        var InHorizon = (u_rng < horizon);
        return InHorizon;
    },

    doppler: func(SelectedObject){
      
        #if it is a radiating stuff, skip doppler
      #print("In the doppler");
      if(pylons.fcs.getSelectedWeapon() != nil){
        #print("pylons.fcs.getSelectedWeapon() != nil");
        if(pylons.fcs.getSelectedWeapon().type != "30mm Cannon"){
          #print("pylons.fcs.getSelectedWeapon().guidance:" ~pylons.fcs.getSelectedWeapon().guidance);
          if(pylons.fcs.getSelectedWeapon().guidance =="radiation"){
            #print( "Is radiating :" ~ SelectedObject.isRadiating(me.MyCoord));
            if(SelectedObject.isRadiating(me.MyCoord)){
              return 1;
            }
          }
        }
      }
      
        # Test to check if the target can hide bellow us
        # Or Hide using anti doppler movements
        
        var InDoppler = 0;
        var groundNotbehind = me.isGroundNotBehind(SelectedObject);
        if(groundNotbehind)
        {
            InDoppler = 1;
        }
        if(me.HaveDoppler and (abs(SelectedObject.get_closure_rate_from_Coord(me.MyCoord)) > me.DopplerSpeedLimit))
        {
            InDoppler = 1;
        }
        if(SelectedObject.get_Callsign() == "GROUND_TARGET" or SelectedObject.check_carrier_type())
        {
            InDoppler = 1;
        }
        return InDoppler;
    },

    isGroundNotBehind: func(SelectedObject){
        var myPitch = SelectedObject.get_Elevation_from_Coord(me.MyCoord);
        var GroundNotBehind = 1; # sky is behind the target (this don't work on a valley)
        if(myPitch < 0 and me.NotBeyondHorizon(SelectedObject))
        {
            # the aircraft is bellow us, the ground could be bellow
            # Based on earth curve. Do not work with mountains
            # The script will calculate what is the ground distance for the line (us-target) to reach the ground,
            # If the earth was flat. Then the script will compare this distance to the horizon distance
            # If our distance is greater than horizon, then sky behind
            # If not, we cannot see the target unless we have a doppler radar
            var distHorizon = me.MyCoord.alt() / math.tan(abs(myPitch * D2R)) * M2NM;
            var horizon = SelectedObject.get_horizon( me.our_alt);
            var TempBool = (distHorizon > horizon);
            GroundNotBehind = (distHorizon > horizon);
        }
        return GroundNotBehind;
    },

    inAzimuth: func(SelectedObject,ExceptGroundTarget = 1){
        if(SelectedObject.get_Callsign()=="GROUND_TARGET" and ExceptGroundTarget){return 1;}
        # Check if it's in Azimuth.
        # first we check our heading+ center az deviation + the sweep if the radar is mechanical
        tempAz = me.az_fld;
        var inMyAzimuth = 0;
        
        var myHeading = math.mod(me.fieldazCenter + me.OurHdg, 360);
        if(me.haveSweep)
        {
            myHeading = math.mod(myHeading + me.SwpMarker * (0.0844 / me.swp_diplay_width) * tempAz / 4, 360);
            mydeviation = SelectedObject.get_deviation(myHeading, me.MyCoord);
            #print("Heading:"~ myHeading ~" My deviation:"~ mydeviation);
            inMyAzimuth = (abs(mydeviation) < (tempAz / 4));
        }
        else
        {
            mydeviation = SelectedObject.get_deviation(myHeading, me.MyCoord);
            inMyAzimuth = (abs(mydeviation)<(tempAz/2));
        }
        return inMyAzimuth;
    },

    inElevation: func(SelectedObject){
        if(SelectedObject.get_Callsign()=="GROUND_TARGET"){return 1;}
        # Moving the center of this field will be ne next option
        var tempAz = me.vt_az_fld;
        var myElevation = SelectedObject.get_total_elevation_from_Coord(me.OurPitch, me.MyCoord);
        var IsInElevation = (abs(myElevation) < (tempAz / 2));
        return IsInElevation;
    },

    InRange: func(SelectedObject){
        if(SelectedObject.get_Callsign()=="GROUND_TARGET"){return 1;}
        # Check if it's in range
        IsInRange = 0;
        var myRange = me.targetRange(SelectedObject);
        if(myRange != 0)
        {
            #print(SelectedObject.get_Callsign() ~": Range (NM) : " ~myRange);
            IsInRange = ( myRange <= me.rangeTab[me.rangeIndex]);
        }
        return IsInRange;
    },

    heat_sensor: func(SelectedObject){
        myEngineTree = SelectedObject.get_engineTree();
        # If MP or AI has an engine tree, we will check for each engine n1>30 or rpm>1000
        if(myEngineTree != nil)
        {
            var engineList = myEngineTree.getChildren();
            foreach(var currentEngine ; engineList)
            {
                var HaveN1node = currentEngine.getNode("n1");
                var HaveRPMnode = currentEngine.getNode("rpm");
                if(HaveN1node != nil)
                {
                    n1value = HaveN1node.getValue();
                    if(n1value != nil and n1value > 30)
                    {
                        #print("N1 detected");
                        return 1;
                    }
                }
                if(HaveRPMnode != nil)
                {
                    RpMvalue = HaveRPMnode.getValue();
                    if(RpMvalue != nil and RpMvalue > 1000)
                    {
                        #print("RPM detected");
                        return 1;
                    }
                }
            }
        }
        # Here we could add a velocity test : if speed >mach 1, we can imagine that friction provides heat
    },
}