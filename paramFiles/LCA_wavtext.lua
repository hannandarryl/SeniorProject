package.path = package.path .. ";" .. "../../../parameterWrapper/?.lua";
local pv = require "PVModule";
--local subnets = require "PVSubnets";

local nbatch           = 8;    --Batch size of learning
local nxSize           = 400;
local nySize           = 1;
local xPatchSize       = 8;
local yPatchSize       = 48;  -- patch size for V1 to cover all y
local stride           = 2;
local xScale           = 25;
local yScale           = 48;
local displayPeriod    = 400;   --Number of timesteps to find sparse approximation
local numEpochs        = 4;     --Number of times to run through dataset
local numImages        = 9997; --Total number of images in dataset
local stopTime         = math.ceil((numImages  * numEpochs) / nbatch) * displayPeriod;
local writeStep        = displayPeriod; 
local initialWriteTime = displayPeriod; 

local inputPath        = "../data/theVideo.txt";
local inputPathAudio   = "../data/theAudio.pvp";
local outputPath       = "../output/";
local checkpointPeriod = (displayPeriod * 10); -- How often to write checkpoints

local numBasisVectors  = 256;   --overcompleteness x (stride X) x (Stride Y) * (# color channels) * (2 if rectified) 
local basisVectorFile  = nil;   --nil for initial weights, otherwise, specifies the weights file to load. Change init parameter in MomentumConn
local plasticityFlag   = true;  --Determines if we are learning weights or holding them constant
local momentumTau      = 200;   --The momentum parameter. A single weight update will last for momentumTau timesteps.
local dWMax            = 5; --10;    --The learning rate
local VThresh          = .015;  -- .005; --The threshold, or lambda, of the network
local AMin             = 0;
local AMax             = infinity;
local AShift           = .015;  --This being equal to VThresh is a soft threshold
local VWidth           = 0; 
local timeConstantTau  = 100;   --The integration tau for sparse approximation
local weightInit       = math.sqrt((1/xPatchSize)*(1/yPatchSize)*(1/3));

-- Base table variable to store
local pvParameters = {

   --Layers------------------------------------------------------------
   --------------------------------------------------------------------   
   column = {
      groupType = "HyPerCol";
      startTime                           = 0;
      dt                                  = 1;
      stopTime                            = stopTime;
      progressInterval                    = (displayPeriod * 10);
      writeProgressToErr                  = true;
      verifyWrites                        = false;
      outputPath                          = outputPath;
      printParamsFilename                 = "Multimodal_Tutorial.params";
      randomSeed                          = 1234567890;
      nx                                  = nxSize;
      ny                                  = nySize;
      nbatch                              = nbatch;
      checkpointWrite                     = true;
      checkpointWriteDir                  = outputPath .. "/Checkpoints"; --The checkpoint output directory
      checkpointWriteTriggerMode          = "step";
      checkpointWriteStepInterval         = checkpointPeriod; --How often to checkpoint
      deleteOlderCheckpoints              = false;
      suppressNonplasticCheckpoints       = false;
      errorOnNotANumber                   = false;
   };

   AdaptiveTimeScales = {
      groupType = "AdaptiveTimeScaleProbe";
      targetName                          = "V1EnergyProbe";
      message                             = nil;
      textOutputFlag                      = true;
      probeOutputFile                     = "AdaptiveTimeScales.txt";
      triggerLayerName                    = "InputVision";
      triggerOffset                       = 0;
      baseMax                             = .1; --1.0; -- minimum value for the maximum time scale, regardless of tau_eff
      baseMin                             = 0.01; -- default time scale to use after image flips or when something is wacky
      tauFactor                           = 0.1; -- determines fraction of tau_effective to which to set the time step, can be a small percentage as tau_eff can be huge
      growthFactor                        = 0.01; -- percentage increase in the maximum allowed time scale whenever the time scale equals the current maximum
      writeTimeScales                     = true;
   };

   InputVision = {
      groupType = "ImageLayer";
      nxScale                             = 1;
      nyScale                             = yScale;
      nf                                  = 1;
      phase                               = 0;
      mirrorBCflag                        = true;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
      inputPath                           = inputPath;
      offsetAnchor                        = "tl";
      offsetX                             = 0;
      offsetY                             = 0;
      inverseFlag                         = false;
      normalizeLuminanceFlag              = true;
      normalizeStdDev                     = true;
      jitterFlag                          = 0;
      useInputBCflag                      = false;
      padValue                            = 0;
      autoResizeFlag                      = false;
      displayPeriod                       = displayPeriod;
      batchMethod                         = "byImage";
      writeFrameToTimestamp               = true;
      resetToStartOnLoop                  = false;
   };

   InputVisionError = {
      groupType = "HyPerLayer";
      nxScale                             = 1;
      nyScale                             = yScale;
      nf                                  = 1;
      phase                               = 1;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
   };

   V1 = {
      groupType = "HyPerLCALayer";
      nxScale                             = 1/2;  -- 1/2 so V1 is 128
      nyScale                             = yScale/2; -- make V1 a size of 1 in the y
      nf                                  = numBasisVectors;
      phase                               = 2;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ConstantV";
      valueV                              = VThresh;
      --InitVType                           = "InitVFromFile";
      --Vfilename                           = "V1_V.pvp";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = true;
      writeSparseValues                   = true;
      updateGpu                           = true;
      dataType                            = nil;
      VThresh                             = VThresh;
      AMin                                = AMin;
      AMax                                = AMax;
      AShift                              = AShift;
      VWidth                              = VWidth;
      timeConstantTau                     = timeConstantTau;
      selfInteract                        = true;
      adaptiveTimeScaleProbe              = "AdaptiveTimeScales";
   };
   CloneV1 = {
      groupType = "CloneVLayer";
      nxScale                             = 1/2;
      nyScale                             = yScale/2;
      nf                                  = numBasisVectors;
      phase                               = 2;
      writeStep                           = writeStep;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
      triggerLayerName                    = NULL;
      originalLayerName                   = "V1";
   };


   V1Error = {
      groupType = "HyPerLayer";
      nxScale                             = 1/2;
      nyScale                             = yScale/2;
      nf                                  = numBasisVectors;
      phase                               = 1;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
 
   };


   InputVisionRecon = {
      groupType = "HyPerLayer";
      nxScale                             = 1;
      nyScale                             = yScale;
      nf                                  = 1;
      phase                               = 3;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
   };

   V1P1Recon = {
      groupType = "HyPerLayer";
      nxScale                             = 1/2;
      nyScale                             = yScale/2;
      nf                                  = numBasisVectors;
      phase                               = 3;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
   };



   InputAudio = {
      groupType = "PvpLayer";
      nxScale                             = xScale;
      nyScale                             = 1;
      nf                                  = 1;
      phase                               = 0;
      mirrorBCflag                        = true;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
      inputPath                           = inputPathAudio;
      offsetAnchor                        = "tl";
      offsetX                             = 0;
      offsetY                             = 0;
      inverseFlag                         = false;
      normalizeLuminanceFlag              = true;
      normalizeStdDev                     = true;
      jitterFlag                          = 0;
      useInputBCflag                      = false;
      padValue                            = 0;
      autoResizeFlag                      = false;
      displayPeriod                       = displayPeriod;
      batchMethod                         = "byFile";
      writeFrameToTimestamp               = true;
      resetToStartOnLoop                  = false;
   };

   InputAudioError = {
      groupType = "HyPerLayer";
      nxScale                             = xScale;
      nyScale                             = 1;
      nf                                  = 1;
      phase                               = 1;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
   };

   A1 = {
      groupType = "HyPerLCALayer";
      nxScale                             = xScale/10;
      nyScale                             = 1;
      nf                                  = numBasisVectors;
      phase                               = 2;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ConstantV";
      valueV                              = VThresh;
      --InitVType                           = "InitVFromFile";
      --Vfilename                           = "V1_V.pvp";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = true;
      writeSparseValues                   = true;
      updateGpu                           = true;
      dataType                            = nil;
      VThresh                             = VThresh;
      AMin                                = AMin;
      AMax                                = AMax;
      AShift                              = AShift;
      VWidth                              = VWidth;
      timeConstantTau                     = timeConstantTau;
      selfInteract                        = true;
      adaptiveTimeScaleProbe              = "AdaptiveTimeScales";
   };
   CloneA1 = {
      groupType = "CloneVLayer";
      nxScale                             = xScale/10;
      nyScale                             = 1;
      nf                                  = numBasisVectors;
      phase                               = 2;
      writeStep                           = writeStep;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
      triggerLayerName                    = NULL;
      originalLayerName                   = "A1";
   };


  A1Error = {
      groupType = "HyPerLayer";
      nxScale                             = xScale/10;
      nyScale                             = 1;
      nf                                  = numBasisVectors;
      phase                               = 1;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
   };

   InputAudioRecon = {
      groupType = "HyPerLayer";
      nxScale                             = xScale;
      nyScale                             = 1;
      nf                                  = 1;
      phase                               = 3;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
   };

   A1P1Recon = {
      groupType = "HyPerLayer";
      nxScale                             = xScale/10;
      nyScale                             = 1;
      nf                                  = numBasisVectors;
      phase                               = 3;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
   };


  ------- multi modal LCA layer ------

  P1 = {
      groupType = "HyPerLCALayer";
      nxScale                             = 1/4;
      nyScale                             = 1;
      nf                                  = numBasisVectors*2;
      phase                               = 2;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ConstantV";
      valueV                              = VThresh;
      --InitVType                           = "InitVFromFile";
      --Vfilename                           = "V1_V.pvp";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = true;
      writeSparseValues                   = true;
      updateGpu                           = true;
      dataType                            = nil;
      VThresh                             = VThresh;
      AMin                                = AMin;
      AMax                                = AMax;
      AShift                              = AShift;
      VWidth                              = VWidth;
      timeConstantTau                     = timeConstantTau;
      selfInteract                        = true;
      adaptiveTimeScaleProbe              = "AdaptiveTimeScales";
   };

   V1applyThresh = {
      groupType = "ANNLayer";
      nxScale                             = 1/2;
      nyScale                             = yScale/2;
      nf                                  = numBasisVectors;
      phase                               = 3;
      valueBC                             = 0;
      InitVType                           = "ConstantV";
      valueV                              = VThresh;
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = true;
      writeSparseValues                   = true;
      VThresh                             = VThresh;
      AMin                                = AMin;
      AMax                                = AMax;
      AShift                              = AShift;
      VWidth                              = VWidth;
   };

   A1applyThresh = {
      groupType = "ANNLayer";
      nxScale                             = xScale/10;
      nyScale                             = 1;
      nf                                  = numBasisVectors;
      phase                               = 2;
      InitVType                           = "ConstantV";
      valueV                              = VThresh;
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = true;
      writeSparseValues                   = true;
      VThresh                             = VThresh;
      AMin                                = AMin;
      AMax                                = AMax;
      AShift                              = AShift;
      VWidth                              = VWidth;
   };

   P1VisionRecon = {
      groupType = "HyPerLayer";
      nxScale                             = 1;
      nyScale                             = yScale;
      nf                                  = 1;
      phase                               = 4;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
   };

   P1AudioRecon = {
      groupType = "HyPerLayer";
      nxScale                             = xScale;
      nyScale                             = 1;
      nf                                  = 1;
      phase                               = 4;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
   };




--Connections ------------------------------------------------------
--------------------------------------------------------------------

   InputToErrorVision = {
      groupType = "RescaleConn";
      preLayerName                        = "InputVision";
      postLayerName                       = "InputVisionError";
      channelCode                         = 0;
      delay                               = {0.000000};
      scale                               = weightInit;
   };

   ErrorToV1 = {
      groupType = "TransposeConn";
      preLayerName                        = "InputVisionError";
      postLayerName                       = "V1";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = true;
      updateGSynFromPostPerspective       = true;
      pvpatchAccumulateType               = "convolve";
      writeStep                           = -1;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      gpuGroupIdx                         = -1;
      originalConnName                    = "V1ToError";
   };

   V1ToError = {
      groupType = "MomentumConn";
      preLayerName                        = "V1";
      postLayerName                       = "InputVisionError";
      channelCode                         = -1;
      delay                               = {0.000000};
      numAxonalArbors                     = 1;
      plasticityFlag                      = plasticityFlag;
      convertRateToSpikeCount             = false;
      receiveGpu                          = false; -- non-sparse -> non-sparse
      sharedWeights                       = true;
      weightInitType                      = "UniformRandomWeight";
      wMinInit                            = -1;
      wMaxInit                            = 1;
      sparseFraction                      = 0.9;
      --weightInitType                      = "FileWeight";
      --initWeightsFile                     = basisVectorFile;
      useListOfArborFiles                 = false;
      combineWeightFiles                  = false;
      initializeFromCheckpointFlag        = false;
      triggerLayerName                    = "InputVision";
      triggerOffset                       = 0;
      updateGSynFromPostPerspective       = false; -- Should be false from V1 (sparse layer) to Error (not sparse). Otherwise every input from pre will be calculated (Instead of only active ones)
      pvpatchAccumulateType               = "convolve";
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      nxp                                 = 16;
      nyp                                 = 4;
      shrinkPatches                       = false;
      normalizeMethod                     = "normalizeL2";
      strength                            = 1;
      normalizeArborsIndividually         = false;
      normalizeOnInitialize               = true;
      normalizeOnWeightUpdate             = true;
      rMinX                               = 0;
      rMinY                               = 0;
      nonnegativeConstraintFlag           = false;
      normalize_cutoff                    = 0;
      normalizeFromPostPerspective        = false;
      minL2NormTolerated                  = 0;
      dWMax                               = dWMax; 
      useMask                             = false;
      momentumTau                         = momentumTau;   --The momentum parameter. A single weight update will last for momentumTau timesteps.
      momentumMethod                      = "viscosity";
      momentumDecay                       = 0;
   }; 

   V1ToRecon = {
      groupType = "CloneConn";
      preLayerName                        = "V1";
      postLayerName                       = "InputVisionRecon";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = false;
      updateGSynFromPostPerspective       = false;
      pvpatchAccumulateType               = "convolve";
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      originalConnName                    = "V1ToError";
   };

   ReconToErrorVision = {
      groupType = "IdentConn";
      preLayerName                        = "InputVisionRecon";
      postLayerName                       = "InputVisionError";
      channelCode                         = 1;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
   };
   InputToErrorAudio = {
      groupType = "RescaleConn";
      preLayerName                        = "InputAudio";
      postLayerName                       = "InputAudioError";
      channelCode                         = 0;
      delay                               = {0.000000};
      scale                               = weightInit;
   };

   ErrorToA1 = {
      groupType = "TransposeConn";
      preLayerName                        = "InputAudioError";
      postLayerName                       = "A1";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = true;
      updateGSynFromPostPerspective       = true;
      pvpatchAccumulateType               = "convolve";
      writeStep                           = -1;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      gpuGroupIdx                         = -1;
      originalConnName                    = "A1ToError";
   };

   A1ToError = {
      groupType = "MomentumConn";
      preLayerName                        = "A1";
      postLayerName                       = "InputAudioError";
      channelCode                         = -1;
      delay                               = {0.000000};
      numAxonalArbors                     = 1;
      plasticityFlag                      = plasticityFlag;
      convertRateToSpikeCount             = false;
      receiveGpu                          = false; -- non-sparse -> non-sparse
      sharedWeights                       = true;
      weightInitType                      = "UniformRandomWeight";
      wMinInit                            = -1;
      wMaxInit                            = 1;
      sparseFraction                      = 0.9;
      --weightInitType                      = "FileWeight";
      --initWeightsFile                     = basisVectorFile;
      useListOfArborFiles                 = false;
      combineWeightFiles                  = false;
      initializeFromCheckpointFlag        = false;
      triggerLayerName                    = "InputAudio";
      triggerOffset                       = 0;
      updateGSynFromPostPerspective       = false; -- Should be false from V1 (sparse layer) to Error (not sparse). Otherwise every input from pre will be calculated (Instead of only active ones)
      pvpatchAccumulateType               = "convolve";
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      nxp                                 = 1024;
      nyp                                 = 1;
      shrinkPatches                       = false;
      normalizeMethod                     = "normalizeL2";
      strength                            = 1;
      normalizeArborsIndividually         = false;
      normalizeOnInitialize               = true;
      normalizeOnWeightUpdate             = true;
      rMinX                               = 0;
      rMinY                               = 0;
      nonnegativeConstraintFlag           = false;
      normalize_cutoff                    = 0;
      normalizeFromPostPerspective        = false;
      minL2NormTolerated                  = 0;
      dWMax                               = dWMax; 
      useMask                             = false;
      momentumTau                         = momentumTau;   --The momentum parameter. A single weight update will last for momentumTau timesteps.
      momentumMethod                      = "viscosity";
      momentumDecay                       = 0;
   }; 

   A1ToRecon = {
      groupType = "CloneConn";
      preLayerName                        = "A1";
      postLayerName                       = "InputAudioRecon";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = false;
      updateGSynFromPostPerspective       = false;
      pvpatchAccumulateType               = "convolve";
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      originalConnName                    = "A1ToError";
   };

   ReconToErrorAudio = {
      groupType = "IdentConn";
      preLayerName                        = "InputAudioRecon";
      postLayerName                       = "InputAudioError";
      channelCode                         = 1;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
   };

   -------Multimdoal Connections ---------
  P1ToA1Error = {
      groupType = "MomentumConn";
      preLayerName                        = "P1";
      postLayerName                       = "A1Error";
      channelCode                         = -1;
      delay                               = {0.000000};
      numAxonalArbors                     = 1;
      plasticityFlag                      = plasticityFlag;
      convertRateToSpikeCount             = false;
      receiveGpu                          = false; -- non-sparse -> non-sparse
      sharedWeights                       = true;
      weightInitType                      = "UniformRandomWeight";
      wMinInit                            = -1;
      wMaxInit                            = 1;
      sparseFraction                      = 0.9;
      --weightInitType                      = "FileWeight";
      --initWeightsFile                     = basisVectorFile;
      useListOfArborFiles                 = false;
      combineWeightFiles                  = false;
      initializeFromCheckpointFlag        = false;
      triggerLayerName                    = "InputAudio";
      triggerOffset                       = 0;
      updateGSynFromPostPerspective       = false; -- Should be false from V1 (sparse layer) to Error (not sparse). Otherwise every input from pre will be calculated (Instead of only active ones)
      pvpatchAccumulateType               = "convolve";
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      nxp                                 = 32;
      nyp                                 = 1;
      shrinkPatches                       = false;
      normalizeMethod                     = "normalizeL2";
      strength                            = 1;
      normalizeArborsIndividually         = false;
      normalizeOnInitialize               = true;
      normalizeOnWeightUpdate             = true;
      rMinX                               = 0;
      rMinY                               = 0;
      nonnegativeConstraintFlag           = false;
      normalize_cutoff                    = 0;
      normalizeFromPostPerspective        = false;
      minL2NormTolerated                  = 0;
      dWMax                               = dWMax; 
      useMask                             = false;
      momentumTau                         = momentumTau;   --The momentum parameter. A single weight update will last for momentumTau timesteps.
      momentumMethod                      = "viscosity";
      momentumDecay                       = 0;
   }; 
   A1ErrorToP1 = {
      groupType = "TransposeConn";
      preLayerName                        = "A1Error";
      postLayerName                       = "P1";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = true;
      updateGSynFromPostPerspective       = true;
      pvpatchAccumulateType               = "convolve";
      writeStep                           = -1;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      gpuGroupIdx                         = -1;
      originalConnName                    = "P1ToA1Error";
   };

  P1ToV1Error = {
      groupType = "MomentumConn";
      preLayerName                        = "P1";
      postLayerName                       = "V1Error";
      channelCode                         = -1;
      delay                               = {0.000000};
      numAxonalArbors                     = 1;
      plasticityFlag                      = plasticityFlag;
      convertRateToSpikeCount             = false;
      receiveGpu                          = false; -- non-sparse -> non-sparse
      sharedWeights                       = true;
      weightInitType                      = "UniformRandomWeight";
      wMinInit                            = -1;
      wMaxInit                            = 1;
      sparseFraction                      = 0.9;
      --weightInitType                      = "FileWeight";
      --initWeightsFile                     = basisVectorFile;
      useListOfArborFiles                 = false;
      combineWeightFiles                  = false;
      initializeFromCheckpointFlag        = false;
      triggerLayerName                    = "InputVision";
      triggerOffset                       = 0;
      updateGSynFromPostPerspective       = false; -- Should be false from V1 (sparse layer) to Error (not sparse). Otherwise every input from pre will be calculated (Instead of only active ones)
      pvpatchAccumulateType               = "convolve";
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      nxp                                 = 8;
      nyp                                 = 32;
      shrinkPatches                       = false;
      normalizeMethod                     = "normalizeL2";
      strength                            = 1;
      normalizeArborsIndividually         = false;
      normalizeOnInitialize               = true;
      normalizeOnWeightUpdate             = true;
      rMinX                               = 0;
      rMinY                               = 0;
      nonnegativeConstraintFlag           = false;
      normalize_cutoff                    = 0;
      normalizeFromPostPerspective        = false;
      minL2NormTolerated                  = 0;
      dWMax                               = dWMax; 
      useMask                             = false;
      momentumTau                         = momentumTau;   --The momentum parameter. A single weight update will last for momentumTau timesteps.
      momentumMethod                      = "viscosity";
      momentumDecay                       = 0;
   }; 
   V1ErrorToP1 = {
      groupType = "TransposeConn";
      preLayerName                        = "V1Error";
      postLayerName                       = "P1";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = true;
      updateGSynFromPostPerspective       = true;
      pvpatchAccumulateType               = "convolve";
      writeStep                           = -1;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      gpuGroupIdx                         = -1;
      originalConnName                    = "P1ToV1Error";
   };
   V1ConeToV1Error = {
      groupType = "IdentConn";
      preLayerName                        = "CloneV1";
      postLayerName                       = "V1Error";
      channelCode                         = 0;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
   };
   A1ConeToA1Error = {
      groupType = "IdentConn";
      preLayerName                        = "CloneA1";
      postLayerName                       = "A1Error";
      channelCode                         = 0;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
   };


   V1ErrorToV1 = {
      groupType = "IdentConn";
      preLayerName                        = "V1Error";
      postLayerName                       = "V1";
      channelCode                         = 1;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
   };

   V1ReconToV1Error = {
      groupType = "IdentConn";
      preLayerName                        = "V1P1Recon";
      postLayerName                       = "V1Error";
      channelCode                         = 1;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
   };


   A1ErrorToA1 = {
      groupType = "IdentConn";
      preLayerName                        = "A1Error";
      postLayerName                       = "A1";
      channelCode                         = 1;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
   };

   A1ReconToA1Error = {
      groupType = "IdentConn";
      preLayerName                        = "A1P1Recon";
      postLayerName                       = "A1Error";
      channelCode                         = 1;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
   };

   P1ToV1Recon = {
      groupType = "CloneConn";
      preLayerName                        = "P1";
      postLayerName                       = "V1P1Recon";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = false;
      updateGSynFromPostPerspective       = false;
      pvpatchAccumulateType               = "convolve";
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      originalConnName                    = "P1ToV1Error";
   };

   P1ToA1Recon = {
      groupType = "CloneConn";
      preLayerName                        = "P1";
      postLayerName                       = "A1P1Recon";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = false;
      updateGSynFromPostPerspective       = false;
      pvpatchAccumulateType               = "convolve";
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      originalConnName                    = "P1ToA1Error";
   };
   A1P1ReconToThresh = {
      groupType = "IdentConn";
      preLayerName                        = "A1P1Recon";
      postLayerName                       = "A1applyThresh";
      channelCode                         = 0;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
   };
   V1P1ReconToThresh = {
      groupType = "IdentConn";
      preLayerName                        = "V1P1Recon";
      postLayerName                       = "V1applyThresh";
      channelCode                         = 0;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
   };

   P1VisionReconConn = {
      groupType = "CloneConn";
      preLayerName                        = "V1applyThresh";
      postLayerName                       = "P1VisionRecon";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = false;
      updateGSynFromPostPerspective       = false;
      pvpatchAccumulateType               = "convolve";
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      originalConnName                    = "V1ToError";
   };

   A1VisionReconConn = {
      groupType = "CloneConn";
      preLayerName                        = "A1applyThresh";
      postLayerName                       = "P1AudioRecon";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = false;
      updateGSynFromPostPerspective       = false;
      pvpatchAccumulateType               = "convolve";
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      originalConnName                    = "A1ToError";
   };


   --Probes------------------------------------------------------------
   --------------------------------------------------------------------

   V1EnergyProbe = {
      groupType = "ColumnEnergyProbe";
      message                             = nil;
      textOutputFlag                      = true;
      probeOutputFile                     = "V1EnergyProbe.txt";
      triggerLayerName                    = nil;
      energyProbe                         = nil;
   };
   A1EnergyProbe = {
      groupType = "ColumnEnergyProbe";
      message                             = nil;
      textOutputFlag                      = true;
      probeOutputFile                     = "A1EnergyProbe.txt";
      triggerLayerName                    = nil;
      energyProbe                         = "V1EnergyProbe";
   };
   P1EnergyProbe = {
      groupType = "ColumnEnergyProbe";
      message                             = nil;
      textOutputFlag                      = true;
      probeOutputFile                     = "P1EnergyProbe.txt";
      triggerLayerName                    = nil;
      energyProbe                         = "V1EnergyProbe";
   };


   InputVisionErrorL2NormEnergyProbe = {
      groupType = "L2NormProbe";
      targetLayer                         = "InputVisionError";
      message                             = nil;
      textOutputFlag                      = true;
      probeOutputFile                     = "InputVisionErrorL2NormEnergyProbe.txt";
      energyProbe                         = "V1EnergyProbe";
      coefficient                         = 0.5;
      maskLayerName                       = nil;
      exponent                            = 2;
   };
   InputAudioErrorL2NormEnergyProbe = {
      groupType = "L2NormProbe";
      targetLayer                         = "InputAudioError";
      message                             = nil;
      textOutputFlag                      = true;
      probeOutputFile                     = "InputAudioErrorL2NormEnergyProbe.txt";
      energyProbe                         = "A1EnergyProbe";
      coefficient                         = 0.5;
      maskLayerName                       = nil;
      exponent                            = 2;
   };
  InputV1ErrorL2NormEnergyProbe = {
      groupType = "L2NormProbe";
      targetLayer                         = "V1Error";
      message                             = nil;
      textOutputFlag                      = true;
      probeOutputFile                     = "V1ErrorL2NormEnergyProbe.txt";
      energyProbe                         = "P1EnergyProbe";
      coefficient                         = 0.5;
      maskLayerName                       = nil;
      exponent                            = 2;
   };
  InputA1ErrorL2NormEnergyProbe = {
      groupType = "L2NormProbe";
      targetLayer                         = "A1Error";
      message                             = nil;
      textOutputFlag                      = true;
      probeOutputFile                     = "A1ErrorL2NormEnergyProbe.txt";
      energyProbe                         = "P1EnergyProbe";
      coefficient                         = 0.5;
      maskLayerName                       = nil;
      exponent                            = 2;
   };


   V1L1NormEnergyProbe = {
      groupType = "L1NormProbe";
      targetLayer                         = "V1";
      message                             = nil;
      textOutputFlag                      = true;
      probeOutputFile                     = "V1L1NormEnergyProbe.txt";
      energyProbe                         = "V1EnergyProbe";
      coefficient                         = 0.025;
      maskLayerName                       = nil;
   };
   A1L1NormEnergyProbe = {
      groupType = "L1NormProbe";
      targetLayer                         = "A1";
      message                             = nil;
      textOutputFlag                      = true;
      probeOutputFile                     = "A1L1NormEnergyProbe.txt";
      energyProbe                         = "A1EnergyProbe";
      coefficient                         = 0.025;
      maskLayerName                       = nil;
   };
   P1L1NormEnergyProbe = {
      groupType = "L1NormProbe";
      targetLayer                         = "P1";
      message                             = nil;
      textOutputFlag                      = true;
      probeOutputFile                     = "P1L1NormEnergyProbe.txt";
      energyProbe                         = "P1EnergyProbe";
      coefficient                         = 0.025;
      maskLayerName                       = nil;
   };




} --End of pvParameters

-- Print out PetaVision approved parameter file to the console
pv.printConsole(pvParameters)
