void replay_production_xem_shms (Int_t RunNumber = 0, Int_t MaxEvent = 0, TString ftype="") {

  // Get RunNumber and MaxEvent if not provided.
  if(RunNumber == 0) {
    cout << "Enter a Run Number (-1 to exit): ";
    cin >> RunNumber;
    if( RunNumber<=0 ) return;
  }
  if(MaxEvent == 0) {
    cout << "\nNumber of Events to analyze: ";
    cin >> MaxEvent;
    if(MaxEvent == 0) {
      cerr << "...Invalid entry\n";
      exit;
    }
  }
  
  if(ftype==""){
    cout  << "\nEnter analysis type to use (e.g., shms50k, hms50k, sample, prod, hodcalib, dccalib, calcalib): \n " << endl;
    cin >> ftype;
    if(ftype==""){
      cerr << "...Invalid file type\n";
      exit;
    }
  }
  
  // Create file name patterns.
  const char* RunFileNamePattern = "shms_all_%05d.dat";
  vector<TString> pathList;
  pathList.push_back(".");
  pathList.push_back("./raw");
  pathList.push_back("./raw/../raw.copiedtotape");
  pathList.push_back("./cache");
  pathList.push_back("./CACHE_LINKS/cache_xem");

  // Create dir. to store monitoring histos
  TString cmd = ""; // Form("mkdir -p ROOTfiles/%s", ftype.Data());

  if((ftype=="prod") && (MaxEvent==-1)){
    ftype="prod";
    cmd = Form("mkdir -p ROOTfiles/%s", ftype.Data());
  }
  else if( (ftype=="prod") && (MaxEvent!=-1) ){
    ftype="sample";
    cmd = Form("mkdir -p ROOTfiles/%s", ftype.Data());
  }
  else{
    cmd = Form("mkdir -p ROOTfiles/%s", ftype.Data());
  }


  gSystem->Exec(cmd); // create study type dir. if it doesn't exist
  
  const char* ROOTFileNamePattern = "ROOTfiles/%s/xem_shms_replay_%s_%d_%d.root";
  
  // Load global parameters
  gHcParms->Define("gen_run_number", "Run Number", RunNumber);
  gHcParms->AddString("g_ctp_database_filename", "DBASE/SHMS/standard.database");
  gHcParms->Load(gHcParms->GetString("g_ctp_database_filename"), RunNumber);
  gHcParms->Load(gHcParms->GetString("g_ctp_parm_filename"));
  gHcParms->Load(gHcParms->GetString("g_ctp_kinematics_filename"), RunNumber);
  // Load parameters for SHMS trigger configuration
  gHcParms->Load("PARAM/TRIG/archive/spring18/tshms.param");
  // Load fadc debug parameters
  gHcParms->Load("PARAM/SHMS/GEN/archive/spring18/p_fadc_debug_spring18.param");

  // Load the Hall C detector map
  gHcDetectorMap = new THcDetectorMap();
  gHcDetectorMap->Load("MAPS/SHMS/DETEC/STACK/shms_stack.map");

  // Add the dec data class for debugging
  Podd::DecData *decData = new Podd::DecData("D", "Decoder Raw Data");
  gHaApps->Add(decData);

  // Add trigger apparatus
  THaApparatus* TRG = new THcTrigApp("T", "TRG");
  gHaApps->Add(TRG);
  // Add trigger detector to trigger apparatus
  THcTrigDet* shms = new THcTrigDet("shms", "SHMS Trigger Information");
  TRG->AddDetector(shms);

  // Set up the equipment to be analyzed
  THcHallCSpectrometer* SHMS = new THcHallCSpectrometer("P", "SHMS");
  gHaApps->Add(SHMS);
  // Add Noble Gas Cherenkov to SHMS apparatus
  THcCherenkov* ngcer = new THcCherenkov("ngcer", "Noble Gas Cherenkov");
  SHMS->AddDetector(ngcer);
  // Add drift chambers to SHMS apparatus
  THcDC* dc = new THcDC("dc", "Drift Chambers");
  SHMS->AddDetector(dc);
  // Add hodoscope to SHMS apparatus
  THcHodoscope* hod = new THcHodoscope("hod", "Hodoscope");
  SHMS->AddDetector(hod);
  // Add Heavy Gas Cherenkov to SHMS apparatus
  THcCherenkov* hgcer = new THcCherenkov("hgcer", "Heavy Gas Cherenkov");
  SHMS->AddDetector(hgcer);
  // Add Aerogel Cherenkov to SHMS apparatus
  THcAerogel* aero = new THcAerogel("aero", "Aerogel");
  SHMS->AddDetector(aero);
  // Add calorimeter to SHMS apparatus
  THcShower* cal = new THcShower("cal", "Calorimeter");
  SHMS->AddDetector(cal);

  // Add rastered beam apparatus
  THaApparatus* beam = new THcRasteredBeam("P.rb", "Rastered Beamline");
  gHaApps->Add(beam);
  // Add physics modules
  // Calculate reaction point
  THcReactionPoint* prp = new THcReactionPoint("P.react", "SHMS reaction point", "P", "P.rb");
  gHaPhysics->Add(prp);
  // Calculate extended target corrections
  THcExtTarCor* pext = new THcExtTarCor("P.extcor", "HMS extended target corrections", "P", "P.react");
  gHaPhysics->Add(pext);
  // Calculate golden track quantites
  THaGoldenTrack* gtr = new THaGoldenTrack("P.gtr", "SHMS Golden Track", "P");
  gHaPhysics->Add(gtr);
  // Calculate primary (scattered beam - usually electrons) kinematics
  THcPrimaryKine* kin = new THcPrimaryKine("P.kin", "SHMS Single Arm Kinematics", "P", "P.rb");
  gHaPhysics->Add(kin);
  // Calculate the hodoscope efficiencies
  THcHodoEff* peff = new THcHodoEff("phodeff", "SHMS hodo efficiency", "P.hod");
  gHaPhysics->Add(peff);

  // Add event handler for prestart event 125.
  THcConfigEvtHandler* ev125 = new THcConfigEvtHandler("HC", "Config Event type 125");
  gHaEvtHandlers->Add(ev125);
  // Add event handler for EPICS events
  THaEpicsEvtHandler* hcepics = new THaEpicsEvtHandler("epics", "HC EPICS event type 181");
  gHaEvtHandlers->Add(hcepics);
  // Add event handler for scaler events
  THcScalerEvtHandler* pscaler = new THcScalerEvtHandler("P", "Hall C scaler event type 1");
  pscaler->AddEvtType(1);
  pscaler->AddEvtType(129);
  pscaler->SetDelayedType(129);
  pscaler->SetUseFirstEvent(kTRUE);
  gHaEvtHandlers->Add(pscaler);

  /*
  //Add event handler for helicity scalers
  THcHelicityScaler *phelscaler = new THcHelicityScaler("P", "Hall C helicity scaler");
  //phelscaler->SetDebugFile("PHelScaler.txt");
  phelscaler->SetROC(8);
  phelscaler->SetUseFirstEvent(kTRUE);
  gHaEvtHandlers->Add(phelscaler);
  */
  
  // Add event handler for DAQ configuration event
  THcConfigEvtHandler *pconfig = new THcConfigEvtHandler("pconfig", "Hall C configuration event handler");
  gHaEvtHandlers->Add(pconfig);

  // Set up the analyzer - we use the standard one,
  // but this could be an experiment-specific one as well.
  // The Analyzer controls the reading of the data, executes
  // tests/cuts, loops over Acpparatus's and PhysicsModules,
  // and executes the output routines.
  THcAnalyzer* analyzer = new THcAnalyzer;

  // A simple event class to be output to the resulting tree.
  // Creating your own descendant of THaEvent is one way of
  // defining and controlling the output.
  THaEvent* event = new THaEvent;

  // Define the run(s) that we want to analyze.
  // We just set up one, but this could be many.
  THcRun* run = new THcRun( pathList, Form(RunFileNamePattern, RunNumber) );

  // Set to read in Hall C run database parameters
  run->SetRunParamClass("THcRunParameters");
  
  // Eventually need to learn to skip over, or properly analyze the pedestal events
  run->SetEventRange(1, MaxEvent); // Physics Event number, does not include scaler or control events.
  run->SetNscan(1);
  run->SetDataRequired(0x7);
  run->Print();

  // Define the analysis parameters
  TString ROOTFileName = Form(ROOTFileNamePattern, ftype.Data(), ftype.Data(), RunNumber, MaxEvent);
  analyzer->SetCountMode(2);  // 0 = counter is # of physics triggers
                              // 1 = counter is # of all decode reads
                              // 2 = counter is event number
  analyzer->SetEvent(event);
  // Set EPICS event type
  analyzer->SetEpicsEvtType(181);
  // Define crate map
  analyzer->SetCrateMapFileName("MAPS/db_cratemap.dat");
  // Define output ROOT file
  analyzer->SetOutFile(ROOTFileName.Data());
  
  // Define DEF-file
  TString DefTreeFile=Form("DEF-files/xem_shms_%s.def",ftype.Data());
  analyzer->SetOdefFile(DefTreeFile);

  // Define cuts file
  analyzer->SetCutFile("DEF-files/CUTS/xem_cuts_shms.def");    // optional
  // File to record accounting information for cuts
  //analyzer->SetSummaryFile(Form("REPORT_OUTPUT/SHMS/PRODUCTION/summary_all_production_%d_%d.report", RunNumber, MaxEvent));  // optional
  // Start the actual analysis.
  analyzer->Process(run);
  // Create report file from template
  //analyzer->PrintReport("TEMPLATES/SHMS/PRODUCTION/pstackana_production.template",
  //			Form("REPORT_OUTPUT/SHMS/PRODUCTION/replay_shms_all_production_%d_%d.report", RunNumber, MaxEvent));  // optional

}
