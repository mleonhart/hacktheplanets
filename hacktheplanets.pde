import java.io.File;
import java.io.FilenameFilter;
import java.util.Queue;
import java.util.Collections;
import java.util.Map;
import java.util.Set;
import java.util.Iterator;

/*
  Creates a digital solar system based off of publicly accessible information passed over unencrypted channels.
  
  Satellite System: a set of gravitationally bound objects in orbit around a planetary mass object or minor planet.
  
  Each mac address seen will render a planet in the solar system. Satellite systems are created as all images sniffed 
  from unencrypted traffic are saved and displayed as "moons" oribiting around the corresponding planet of the mac 
  address they came from.  
  
  The number of moons per planet is limited to moonQueueSize. Every secondsToWait, the system will search for new
  textures for the moons. If the number of textures available exceeds moonQueueSize, old moons will be pushed out 
  of the queue to make room for new moons.
  
  The number of satellite systems in the solar system is limited to systemQueueSize. Every secondsToWait the system
  will search for new mac addresses. If the number of existing mac addresses exceeds systemQueueSize, the old 
  satellite systems will be pushed out of the queue to make room for new satellite systems.
  
  Shuffle macs through the solar system. 
  Is there a new mac to show?
  If it has been longer than X seconds, replace the oldest mac with the new mac address.
  3E, <- 44, F2, A8, CC, DD <-
  44, <- F2, A8, CC, DD, 3E <-
  
*/

// solar system 
HashMap<String, FixedLengthQueue> moonTexturesMap;  /* {'macAddress1': ['moonTexture1.jpg', 'moonTexture2.jpg', 'moonTexture3.jpg'],} */
HashMap<String, HashMap> satelliteSystemMap;  /* {'macAddress1': {Planet planet1: [Moon moon1, Moon moon2, Moon moon3]},} */
HashMap<String, Long> macAddressTimesMap; /* {'macAddress': '2016-01-01 00:00:00'} */
ArrayList<File> files;
File directoryOfTextures;
PImage backgroundImage;
Sun sun;

// timing - moons
long lastCheck = System.currentTimeMillis();
long currentCheck = System.currentTimeMillis();
long secondsToWait = 60000;
Long macLastSeen = System.currentTimeMillis();

// timing - satellite systems
long lastCheckSS = System.currentTimeMillis();
long currentCheckSS = System.currentTimeMillis();
long secondsToWaitSS = 120000;

// limits & counters
int moonQueueSize = 5;
int systemQueueSize = 5;
int satelliteCount = 0;
int maxFilesToProcess = 2;


void setup() {
  // my laptop
  size( 1800, 1000, P3D);
  // 4K TV
  //size(3850, 2160, P3D);
  
  backgroundImage = loadImage("textures/stars.jpg");
  noStroke();
  sphereDetail(50);

  // initialize the sun
  sun = new Sun();
   
  // initialize the satellite system
  moonTexturesMap = new HashMap<String, FixedLengthQueue>();
  satelliteSystemMap = new HashMap<String, HashMap>();
  macAddressTimesMap = new HashMap<String, Long>();

  // start doing shit
  searchDiskForTextures();
  createSatelliteSystemsFromTextures();
}

void draw() {
    background(0);
    hint(DISABLE_DEPTH_MASK);
    image(backgroundImage, 0, 0, width, height);
    hint(ENABLE_DEPTH_MASK);
    
    // show the sun
    sun.display();
                  
    for (Map.Entry satelliteSystem : satelliteSystemMap.entrySet()) {
       renderSatelliteSystem((HashMap)satelliteSystem.getValue());
    }
      
    // every X seconds, look for more textures to turn into more moons
    currentCheck = System.currentTimeMillis();
    if (currentCheck - lastCheck >= secondsToWait) {
        if (searchDiskForTextures()) createSatelliteSystemsFromTextures();
        lastCheck = currentCheck;
    }
}

boolean searchDiskForTextures() {
    // get all texture files with the right file format
    directoryOfTextures = new File(dataPath(""));
    File[] filenameFilter = directoryOfTextures.listFiles(new FilenameFilter() {
       public boolean accept(File directoryOfTextures, String name) {
           return (name.toLowerCase().contains("-") && 
                 (name.toLowerCase().endsWith(".jpg") ||
                 name.toLowerCase().endsWith(".png")));
           }
       });

    files = new ArrayList<File>(moonQueueSize);
    Collections.addAll(files, filenameFilter);
    println("\n\nsearchDiskForTextures: Found " + str(files.size()) + " images. Processing " + str(maxFilesToProcess) + "\n");

    // unecessary safety check to keep us from processing too many files at once
    int filesProcessed = 0;
    for (File file : files) { 
        if (filesProcessed >= maxFilesToProcess) {
            println("searchDiskForTextures: Exiting after processing " + str(filesProcessed) + " images");
            break;
        }
    
        // move the texture file to the processed directory
        file.renameTo(new File(dataPath("processed/" + file.getName())));
        
        // grab a copy of the texture file we just moved
        File copiedFile = new File(dataPath("processed/" + file.getName()));
    
        // double-check: if the file doesnt have the right name format, fuck that file
        if (copiedFile.getName().contains("-")) {
            // get the macAddress from the filename so we can keep one device's files together
            String macAddress = copiedFile.getName().substring(copiedFile.getName().indexOf("_") + 1, copiedFile.getName().indexOf("."));
            
            // format it pretty
            macAddress = macAddress.replace("/", ":");
            
            println("searchDiskForTextures: Image has macAddress " + macAddress);
            
            // get or create a queue to put queue up these texture files in
            FixedLengthQueue<File> moonTextures;
            if (moonTexturesMap.get(macAddress) != null) {
                println("searchDiskForTextures: macAddress " + macAddress + " exists in galaxyTexturesMap. Getting it.");
                moonTextures = moonTexturesMap.get(macAddress);      
            } else { 
                println("searchDiskForTextures: macAddress " + macAddress + " does not exist in galaxyTexturesMap. Adding it now.");
                moonTextures = new FixedLengthQueue<File>(moonQueueSize); 
            }
      
            moonTextures.add(copiedFile);
            
            // associate the queue of textures with the corresponding mac address
            moonTexturesMap.put(macAddress, moonTextures);
          
            filesProcessed += 1;
        }
    }
    return filesProcessed > 0; 
}
  
void createSatelliteSystemsFromTextures() {
    for (Map.Entry moonTextureEntry : moonTexturesMap.entrySet()) {  /* {'macAddress1': ['moonTexture1.jpg', 'moonTexture2.jpg', 'moonTexture3.jpg'],} */
        // get mac address and textures from the map
        String macAddress = (String)moonTextureEntry.getKey();
        print("createSatelliteSystemsFromTextures: got macAddress " + macAddress + " from moonTexturesMap");
        FixedLengthQueue<File> moonTextures = (FixedLengthQueue<File>)moonTextureEntry.getValue();  /* ['moonTexture1.jpg', 'moonTexture2.jpg', 'moonTexture3.jpg'],} */
      
        // get ready for new planet and moon queue
        Planet planet = null;
        FixedLengthQueue<Moon> moons = null;
  
        // if we've seen this mac before, get it's corresponding planet and moons from the solar system 
        if (satelliteSystemMap.get(macAddress) != null) {
            println("createSatelliteSystemsFromTextures: macAddress " + moonTextureEntry.getKey() + " exists in satelliteSystemMap");
            HashMap<Planet, FixedLengthQueue> ssMap = satelliteSystemMap.get(macAddress);  /* ssMap: { Planet planet: [Moon moon1, Moon moon2, Moon moon3] } */
            Map.Entry satelliteSystem = ssMap.entrySet().iterator().next();
            planet = (Planet)satelliteSystem.getKey();
            moons = (FixedLengthQueue)satelliteSystem.getValue();

            addSatelliteToSystem(macAddress, planet, moonTextures, moons);
      
            // take note of the last time we saw this mac address
            macAddressTimesMap.put(macAddress, System.currentTimeMillis());
                
        // if the mac is new  
        } else {
            println("createSatelliteSystemsFromTextures: macAddress " + moonTextureEntry.getKey() + " does not exist in satelliteSystemMap.");
            println("createSatelliteSystemsFromTextures: satelliteSystemMap.size(): " + str(satelliteSystemMap.size()) + "\n");  // note: this counts from zero
          
            // if the solar system is full, check if we've waited long enough to kick some other mac out
            if (satelliteSystemMap.size() >= systemQueueSize) {
                // if we've waited long enough, take an existing planet from the solar system and replace it
                println("createSatelliteSystemsFromTextures: The satellite system is full!");
                currentCheckSS = System.currentTimeMillis();
                if (currentCheckSS - lastCheckSS >= secondsToWaitSS) { 
                    println("createSatelliteSystemsFromTextures: It's time to replace an old planet.");
              
                    long comparisonTime = System.currentTimeMillis();
                    String oldestMac = "";
                    // get the oldest mac by the timemap
                    for (Map.Entry macAndTime : macAddressTimesMap.entrySet()) {
                       println("Comparing: " + str((Long)macAndTime.getValue()) + " and " + str(comparisonTime) + " for mac " + (String)macAndTime.getKey() + "\n");
                        if ((Long)macAndTime.getValue() < comparisonTime) {
                            oldestMac = (String)macAndTime.getKey();
                            println("oldest mac so far: " + oldestMac + "\n");
                            comparisonTime = (Long)macAndTime.getValue();
                        }
                    }
    

                    println("createSatelliteSystemsFromTextures: removing oldest mac " + oldestMac + " from macAddressTimesMap\n");
                    // remove mac address from timemap
                    macAddressTimesMap.remove(oldestMac);
                    
                    println("createSatelliteSystemsFromTextures: removing oldest mac " + oldestMac + " from satelliteSystemMap\n");
                    // remove the oldest entry in the map
                    HashMap<Planet, FixedLengthQueue> oldSatellite = satelliteSystemMap.remove(oldestMac);  /* {'macAddress1': {Planet planet1: [Moon moon1, Moon moon2, Moon moon3]},} */

                    // put the old objects back in, but now associated to our new mac
                    println("createSatelliteSystemsFromTextures: Addding new mac " + macAddress + " to satelliteSystemMap");
                    satelliteSystemMap.put(macAddress, oldSatellite);

                    // take note of the last time we saw this mac address
                    println("createSatelliteSystemsFromTextures: Addding new mac " + macAddress + " to macAddressTimesMap");
                    macAddressTimesMap.put(macAddress, System.currentTimeMillis());
                
                    // log the check
                    lastCheckSS = currentCheckSS;
                } else {
                  println("createSatelliteSystemsFromTextures: Not yet time to boot an old planet out. Ignoring " + moonTextureEntry.getKey() + "\n");
                }
            // if the solar system is not full, make a new planet and moons for this mac
            } else {
               println("createSatelliteSystemsFromTextures: making new planet and moon queue for satelliteCount: " + str(satelliteCount));
                planet = new Planet(satelliteCount);
                moons = new FixedLengthQueue<Moon>(moonQueueSize);
                satelliteCount += 1;
                
                addSatelliteToSystem(macAddress, planet, moonTextures, moons);
                
                // take note of the last time we saw this mac address
                macAddressTimesMap.put(macAddress, System.currentTimeMillis());
            }
        } 
    }
}

void addSatelliteToSystem(String macAddress, Planet planet, FixedLengthQueue<File> moonTextures, FixedLengthQueue<Moon> moons) {
  println("addSatelliteToSystem: handling macAddress: " + macAddress);
  // fill the moonlist with textured moons
    for (File moonTexture : moonTextures) {
        println("addSatelliteToSystem: creating new moon from moonTexture: " + moonTexture);
        Moon moon;
        if (moons.size() >= moonQueueSize) {
            moon = moons.peek();
            moon.setTexture(moonTexture.getPath());
        } else {
          moon = new Moon(planet, moonTexture.getPath());
        }
        moons.add(moon);
    }
    
    // put the planet and moons in the satelliteSystem
    HashMap<Planet, FixedLengthQueue> satelliteSystem = new HashMap<Planet, FixedLengthQueue>();  /* satelliteSystem: { Planet planet: [Moon moon1, Moon moon2, Moon moon3] } */
    satelliteSystem.put(planet, moons);
    
    // associate the macAddress to the satelliteSystem
    satelliteSystemMap.put(macAddress, satelliteSystem);
}

void renderSatelliteSystem(HashMap galaxyMap) {  
    // get all galaxies we know of
    Set<Map.Entry> entries = galaxyMap.entrySet();  
    // for each galaxy, display the planet and its moons
    for (Iterator<Map.Entry> galaxy = entries.iterator(); galaxy.hasNext(); ) {
        // get galaxy
        Map.Entry galaxyEntry = (Map.Entry)galaxy.next(); 
        
        // display planet
        Planet planet = (Planet)galaxyEntry.getKey();
        planet.display();
        
        // display moons
        FixedLengthQueue<Moon> moons = (FixedLengthQueue<Moon>)galaxyEntry.getValue();
        for (Moon moon : moons) {
            PVector force = planet.attract(moon);
            moon.applyForce(force);
            moon.update();
            moon.display();
        }
    }
}