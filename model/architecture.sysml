package BikeRadarArchitecture {
    doc /* Inside the rear unit: the parts it is built from and how they are
         * wired together. */

    private import ISQ::*;
    private import SI::*;
    private import ScalarValues::*;
    private import Quantities::*;
    private import TrigFunctions::*;
    private import BikeRadarContext::*;

    // ---- Provenance --------------------------------------------------------

    metadata def Assumption {
        doc /* A value chosen for the design, not measured nor read from a
             * datasheet. */
    }
    metadata def Datasheet {
        doc /* The part's values come from its datasheet, except those marked
             * as assumptions. */
        attribute source : String;
        attribute preliminary : Boolean;
    }

    // ---- Items -------------------------------------------------------------

    item def RadarConfig {
        doc /* Chirp settings and on/off, written by the MCU over SPI. */
    }
    item def Detections {
        doc /* Range, speed and angle of each target, read by the MCU over SPI. */
    }
    item def LedControl {
        doc /* A PWM signal setting the light's brightness and flash pattern. */
    }
    item def LedCurrent {
        doc /* Constant current through the LED string. */
    }
    item def ChargeCurrent {
        doc /* Constant current, then constant voltage, into the cell. */
    }
    item def CellPower {
        doc /* 3.0 V to 4.2 V from the cell. */
    }
    item def RailPower {
        doc /* A regulated supply rail: 1.8 V for the MCU and for the radar's
             * analog and I/O, 1.2 V for the radar's core and RF. */
    }
    item def CellVoltage {
        doc /* The cell voltage, sensed by the MCU to detect an empty battery. */
    }
    item def FuelGauge {
        doc /* The cell's state of charge and health, read by the MCU over I2C. */
    }
    item def ButtonPress {
        doc /* A short or long press of the button. */
    }

    // ---- Ports -------------------------------------------------------------

    port def RadarDataPort {
        out item detections : Detections;
        in item config : RadarConfig;
    }
    port def LedControlPort {
        out item pwm : LedControl;
    }
    port def LedDrivePort {
        out item current : LedCurrent;
    }
    port def ChargePort {
        out item current : ChargeCurrent;
    }
    port def CellPort {
        out item power : CellPower;
    }
    port def RailPort {
        out item power : RailPower;
    }
    port def CellSensePort {
        out item voltage : CellVoltage;
    }
    port def FuelGaugePort {
        out item reading : FuelGauge;
    }
    port def ButtonPort {
        out item press : ButtonPress;
    }

    // ---- Parts -------------------------------------------------------------

    part def RadarModule {
        doc /* A radar chip on a small board, with patch antennas: one to
         * transmit and one per receive channel, each about 60° wide and 20°
         * high. Each frame it sends a burst of chirps, processes them, then
         * idles until the next frame, so its power is an average over a frame.
         * Gains, losses and the noise figure are linear: dB values are in the
         * comments. The chip's own values come from its datasheet; the board's
         * are design assumptions, the same for every chip. */

        // The chip, from its datasheet
        attribute frequency : FrequencyValue;
        attribute chipTxPower : PowerValue {
            doc /* The most the chip's transmitter puts out. */
        }
        attribute rxChannels : Natural;
        attribute noiseFigure : Real;
        attribute maxIfBandwidth : FrequencyValue {
            doc /* The widest beat frequency the receiver passes. A target
                 * farther away than the IF carries is not seen at all. */
        }
        attribute activePower : PowerValue;
        attribute processingPower : PowerValue;
        attribute idlePower : PowerValue;
        attribute ioVoltage : ElectricPotentialDifferenceValue;
        attribute ioPeakCurrent : ElectricCurrentValue;
        attribute coreVoltage : ElectricPotentialDifferenceValue;
        attribute corePeakCurrent : ElectricCurrentValue;

        // The band's limits in Europe, from ERC/REC 70-03
        attribute bandMaxEirp : PowerValue;
        attribute bandMaxOutputPower : PowerValue default = bandMaxEirp {
            doc /* Bands that cap only radiated power cap output power by the
                 * same, since the antenna has gain. */
        }

        // The board
        #Assumption attribute boardMass : MassValue {
            doc /* The board, chip and shield, without the antennas. */
        }
        #Assumption attribute txGain : Real default = 25.0;                 // 14 dBi
        #Assumption attribute rxGain : Real default = 25.0;                 // 14 dBi
        #Assumption attribute losses : Real default = 10.0;                 // 10 dB: radome, mismatch, processing
        #Assumption attribute minSnr : Real default = 31.6;                 // 15 dB to declare a detection
        #Assumption attribute apertureEfficiency : Real default = 0.6;
        #Assumption attribute antennaArealMass : ScalarQuantityValue default = 3 [kg/m^2] {
            doc /* Board, radome and housing face per area of antenna. */
        }
        attribute antennaArea : AreaValue default =
            (1 + rxChannels) * txGain * wavelength ^ 2 / (4 * pi * apertureEfficiency);
        attribute mass : MassValue default = boardMass + antennaArea * antennaArealMass;

        // The waveform: the same rules for every chip, each its own chirps.
        // Every chip sweeps 150 MHz for S14 and sends a burst of about 10.4 ms
        // every 100 ms; each chirp is long enough that the IF carries 200 m.
        #Assumption attribute framePeriod : DurationValue default = 0.1 [s];
        #Assumption attribute sweepBandwidth : FrequencyValue default = 150e6 [Hz];
        attribute chirpDuration : DurationValue;
        #Assumption attribute chirpIdleTime : DurationValue default = 7e-6 [s];
        attribute chirpsPerFrame : Natural;
        #Assumption attribute processingTime : DurationValue default = 0.01 [s] {
            doc /* Range and Doppler FFTs, detection and clustering of a frame. */
        }
        attribute designTargetRcs : AreaValue default = 10 [m^2] {
            doc /* The radar cross-section of a car seen from the front. */
        }
        attribute azimuthBeamwidth : PlaneAngleValue default = 60 ['°'];
        attribute elevationBeamwidth : PlaneAngleValue default = 20 ['°'];

        attribute wavelength : LengthValue default = speedOfLight / frequency;
        attribute txPower : PowerValue default = LowerOf(LowerOf(chipTxPower, bandMaxOutputPower),
            bandMaxEirp / txGain) {
            doc /* The transmitter turned down as far as the band requires. */
        }
        attribute eirp : PowerValue default = txPower * txGain;
        attribute chirpPeriod : DurationValue default = chirpDuration + chirpIdleTime;
        attribute observationTime : DurationValue default = chirpsPerFrame * chirpDuration;
        attribute activeTime : DurationValue default = chirpsPerFrame * chirpPeriod;
        attribute power : PowerValue default =
            (activePower * activeTime + processingPower * processingTime
                + idlePower * (framePeriod - activeTime - processingTime)) / framePeriod;
        attribute ifLimitedRange : LengthValue default =
            maxIfBandwidth * speedOfLight * chirpDuration / (2 * sweepBandwidth);
        attribute detectionRange : LengthValue default = DetectionRange(self, designTargetRcs);
        attribute rangeResolution : LengthValue default = speedOfLight / (2 * sweepBandwidth);
        #Assumption attribute maxClosingSpeed : SpeedValue default = wavelength / (2 * chirpPeriod) {
            doc /* One-sided Doppler: every target is taken to be closing, so
                 * the whole unambiguous Doppler span counts towards closing
                 * speed, twice what a radar that also measures receding
                 * targets gets. A vehicle pulling away from the rider, rare
                 * behind a bike, would be read as closing fast. */
        }
        attribute speedResolution : SpeedValue default = wavelength / (2 * activeTime);
        port antenna : RadarPort;
        port data : RadarDataPort;
        port ioSupply : ~RailPort;
        port coreSupply : ~RailPort;
    }
    part def Awrl6432Radar :> RadarModule {
        doc /* TI AWRL6432: a 57-64 GHz radar chip with an Arm Cortex-M4F and a
             * hardware FFT accelerator, so the radar finds the targets itself
             * and hands the MCU detections. Two transmitters, of which one is
             * used, and three receivers. Its power figures, and the 1.2 V
             * rail's peak current, are those of its industrial twin, the
             * IWRL6432. */
        @Datasheet {
            source = "TI AWRL6432 datasheet SWRS295B; power from IWRL6432 SWRS298A";
            preliminary = false;
        }
        attribute :>> frequency default = 60.5e9 [Hz];
        attribute :>> bandMaxEirp default = 0.1 [W];                // 57-64 GHz, Annex 1 n1
        attribute :>> bandMaxOutputPower default = 0.01 [W];
        attribute :>> chipTxPower default = 0.0126 [W];                // 11 dBm
        attribute :>> rxChannels default = 3;
        attribute :>> noiseFigure default = 12.6;                   // 11 dB
        attribute :>> maxIfBandwidth default = 5e6 [Hz];
        attribute :>> activePower default = 0.96 [W];               // 2 TX, 3 RX
        attribute :>> processingPower default = 0.159 [W];          // the AWRL1432's figure
        attribute :>> idlePower default = 0.011 [W];
        // Power optimized, 1.8 V I/O: two rails.
        attribute :>> ioVoltage default = 1.8 [V];
        attribute :>> ioPeakCurrent default = 0.36 [A];
        attribute :>> coreVoltage default = 1.2 [V];
        attribute :>> corePeakCurrent default = 1.1 [A];            // the IWRL6432's figure
        #Assumption attribute :>> boardMass default = 5 [g];
        attribute :>> chirpDuration default = 40e-6 [s];
        attribute :>> chirpsPerFrame default = 221;
    }
    part def Awrl1432Radar :> RadarModule {
        doc /* TI AWRL1432: the 76-81 GHz sibling of the AWRL6432, with the same
             * processor and accelerator, but a noisier receiver. */
        @Datasheet {
            source = "TI AWRL1432 datasheet SWRS296B, initial silicon";
            preliminary = true;
        }
        attribute :>> frequency default = 77e9 [Hz];
        attribute :>> bandMaxEirp default = 316 [W];                // 76-77 GHz, Annex 5 e1: 55 dBm peak
        attribute :>> chipTxPower default = 0.0126 [W];                // 11 dBm
        attribute :>> rxChannels default = 3;
        attribute :>> noiseFigure default = 25.1;                   // 14 dB
        attribute :>> maxIfBandwidth default = 5e6 [Hz];
        attribute :>> activePower default = 1.36 [W];               // 2 TX, 3 RX
        attribute :>> processingPower default = 0.159 [W];
        attribute :>> idlePower default = 0.0138 [W];
        #Assumption attribute :>> boardMass default = 5 [g];
        attribute :>> chirpDuration default = 40e-6 [s];
        attribute :>> chirpsPerFrame default = 221;
    }
    part def Bgt24Mtr12Radar :> RadarModule {
        doc /* Infineon BGT24MTR12: a 24.0-24.25 GHz transceiver with one
             * transmitter and two receivers, and analog IF outputs. It has no
             * ADC and no processor, so a DSP-class MCU (a Cortex-M7) samples
             * the IF and runs the FFTs; its mass and power are counted here,
             * and the IF bandwidth is what its ADCs are set up for. It runs
             * from a single 3.3 V rail, which was not weighed. */
        @Datasheet {
            source = "Infineon BGT24MTR12 product page and datasheet rev 3.2";
            preliminary = false;
        }
        attribute :>> frequency default = 24.125e9 [Hz];
        attribute :>> bandMaxEirp default = 0.1 [W];                // 24.05-24.25 GHz, Annex 1 m
        attribute :>> chipTxPower default = 0.0063 [W];                // 8 dBm
        attribute :>> rxChannels default = 2;
        attribute :>> noiseFigure default = 15.8;                   // 12 dB
        #Assumption attribute :>> maxIfBandwidth default = 2e6 [Hz];
        #Assumption attribute :>> activePower default = 0.99 [W] {
            doc /* 0.66 W for the transceiver, 0.33 W for the DSP MCU sampling. */
        }
        #Assumption attribute :>> processingPower default = 0.33 [W];
        #Assumption attribute :>> idlePower default = 0.003 [W] {
            doc /* The transceiver off, the DSP MCU stopped. */
        }
        #Assumption attribute :>> boardMass default = 6.5 [g] {
            doc /* 5 g as for the other chips, and 1.5 g for the DSP MCU. */
        }
        attribute :>> chirpDuration default = 100e-6 [s];
        attribute :>> chirpsPerFrame default = 97;
    }
    part def Mcu {
        doc /* Raytac AN54L15Q: a pre-certified module around Nordic's nRF54L15,
             * a Cortex-M33 with a radio for Bluetooth Low Energy and ANT. It
             * tracks vehicles from the radar's detections, alerts the head
             * unit and runs the modes. The firmware is a Rust application on
             * Zephyr, in Nordic's nRF Connect SDK: the only place ANT is
             * offered. */
        @Datasheet {
            source = "Raytac AN54L15Q announcement: 9.5 x 13.7 x 2.1 mm";
            preliminary = false;
        }
        #Assumption attribute mass : MassValue default = 1 [g];
        #Assumption attribute power : PowerValue default = 0.015 [W] {
            doc /* Tracking at 10 frames a second and a radio link to the
                 * head unit, averaged. */
        }
        #Assumption attribute peakCurrent : ElectricCurrentValue default = 0.02 [A] {
            doc /* The radio transmitting while the processor runs. */
        }
        attribute alertLatency : DurationValue default = 0.25 [s];
        attribute maxTrackedVehicles : Natural default = 8;
        port radarData : ~RadarDataPort;
        port ble : BlePort;
        port led : LedControlPort;
        port button : ~ButtonPort;
        port fuelGauge : ~FuelGaugePort;
        port supply : ~RailPort;
    }
    part def Button {
        doc /* C&K KSC: a sealed IP67 tactile switch on the back of the unit. */
        attribute mass : MassValue default = 1 [g];
        port press : ButtonPort;
    }
    part def LedDriver {
        doc /* TI TPS61160A: a constant-current boost driver for the LED
             * string, fed from the cell. The string's forward voltage must stay
             * above the full cell's 4.2 V, or the LEDs glow when the driver is
             * off; so three red LEDs, not two. */
        @Datasheet {
            source = "TI TPS61160A datasheet SLVS937";
            preliminary = false;
        }
        attribute mass : MassValue default = 1 [g];
        #Assumption attribute efficiency : Real default = 0.85 {
            doc /* TI quotes up to 90 %, for longer strings than ours. */
        }
        port control : ~LedControlPort;
        port drive : LedDrivePort;
        port supply : ~CellPort;
    }
    part def RearLeds {
        doc /* Three Lumileds LUXEON Rebel red LEDs in series behind a lens. Day
             * flash averages the bright pulses; night solid is steady at lower
             * brightness. */
        attribute mass : MassValue default = 4 [g];
        attribute dayFlashPower : PowerValue default = 0.08 [W];
        attribute nightSolidPower : PowerValue default = 0.12 [W];
        attribute daylightVisibility : LengthValue default = 1.6 [km];
        port drive : ~LedDrivePort;
        port light : LightPort;
    }
    part def BuckRegulator {
        doc /* A step-down converter making one of the radar's rails from the
             * cell. The MCU can switch it off with the radar. */
        attribute outputVoltage : ElectricPotentialDifferenceValue;
        attribute maxOutputCurrent : ElectricCurrentValue;
        #Assumption attribute efficiency : Real default = 0.9 {
            doc /* At the radar's load, averaged over a frame. */
        }
        #Assumption attribute mass : MassValue default = 0.5 [g] {
            doc /* The converter, its inductor and capacitors. */
        }
        port input : ~CellPort;
        port output : RailPort;
    }
    part def RadarCoreBuck :> BuckRegulator {
        doc /* TI TPS62088: 3 A in a 1.2 mm x 0.8 mm package, 4 uA quiescent,
             * from 2.4 V to 5.5 V in. */
        @Datasheet {
            source = "TI TPS62088 datasheet SLVSD94";
            preliminary = false;
        }
        attribute :>> outputVoltage default = 1.2 [V];
        attribute :>> maxOutputCurrent default = 3 [A];
    }
    part def RadarIoBuck :> BuckRegulator {
        doc /* TI TPS62840: 750 mA, 60 nA quiescent, from 1.8 V to 6.5 V in. */
        @Datasheet {
            source = "TI TPS62840 datasheet SLVSEC6";
            preliminary = false;
        }
        attribute :>> outputVoltage default = 1.8 [V];
        attribute :>> maxOutputCurrent default = 0.75 [A];
    }
    part def Battery {
        doc /* A single Li-ion cell. Its mass follows from its energy. It must
             * still last 16 h of day flash at -10 °C at the end of its life, so
             * only part of its rated energy counts: the share it keeps in the
             * cold, and the share it keeps when aged. */
        attribute energy : EnergyValue;
        attribute specificEnergy : SpecificEnergyValue;
        attribute mass : MassValue default = energy / specificEnergy;
        attribute coldCapacity : Real;
        attribute endOfLifeCapacity : Real default = 0.8;
        attribute usableEnergy : EnergyValue default =
            energy * coldCapacity * endOfLifeCapacity;
        attribute maxDischargePower : PowerValue default = 10 [W];
        attribute minDischargeTemperature : TemperatureValue default = -20 ['°C'];
        attribute maxDischargeTemperature : TemperatureValue default = 60 ['°C'];
        port charge : ~ChargePort;
        port supply : CellPort;
        port sense : CellSensePort;
    }
    part def CylindricalCell :> Battery {
        doc /* A 10 Wh cylindrical cell: robust and cheap, but heavy, and it keeps
             * only half its energy in the cold. */
        attribute :>> energy default = 10 [W*h];
        attribute :>> specificEnergy default = 220 [W*h/kg];
        attribute :>> coldCapacity default = 0.5;
    }
    part def PouchCell :> Battery {
        doc /* A 5 Wh pouch cell: light, but it keeps only half its energy in
             * the cold. */
        attribute :>> energy default = 5 [W*h];
        attribute :>> specificEnergy default = 250 [W*h/kg];
        attribute :>> coldCapacity default = 0.5;
    }
    part def LowTemperaturePouchCell :> Battery {
        doc /* A 7 Wh pouch cell with a low-temperature electrolyte: it keeps
             * three quarters of its energy in the cold. */
        attribute :>> energy default = 7 [W*h];
        attribute :>> specificEnergy default = 240 [W*h/kg];
        attribute :>> coldCapacity default = 0.75;
    }
    part def PowerManager {
        doc /* Nordic nPM1300: a linear Li-ion charger fed from USB-C, which
             * reads the USB-C CC pins itself; a 1.8 V buck for the MCU; and a
             * fuel gauge the MCU reads over I2C. Its two bucks give 200 mA
             * each, too little for the radar, which has bucks of its own. It
             * charges at 800 mA, so S7 was relaxed to 3.5 h. The constant-
             * voltage phase at the end of a charge stretches it by about a
             * third. A discrete 1 A charger would keep a 3 h charge. */
        @Datasheet {
            source = "Nordic nPM1300 product brief v1.2";
            preliminary = false;
        }
        #Assumption attribute mass : MassValue default = 1 [g];
        attribute chargeCurrent : ElectricCurrentValue default = 0.8 [A];
        #Assumption attribute cellNominalVoltage : ElectricPotentialDifferenceValue default = 3.7 [V];
        attribute chargePower : PowerValue default = chargeCurrent * cellNominalVoltage;
        #Assumption attribute constantVoltageStretch : Real default = 1.3;
        attribute mcuRailVoltage : ElectricPotentialDifferenceValue default = 1.8 [V];
        attribute mcuRailMaxCurrent : ElectricCurrentValue default = 0.2 [A];
        #Assumption attribute mcuRailEfficiency : Real default = 0.9;
        port input : UsbCPort;
        port charge : ChargePort;
        port cell : ~CellPort;
        port cellSense : ~CellSensePort;
        port fuelGauge : FuelGaugePort;
        port mcuRail : RailPort;
    }
    part def UsbCReceptacle {
        doc /* GCT USB4715: a 6-pin, power-only USB-C socket, IP67 with its
             * gasket. Its CC pins go to the power manager. */
        attribute mass : MassValue default = 1 [g];
        port plug : UsbCPort;
        port board : ~UsbCPort;
    }
    part def Enclosure {
        doc /* The IP67 housing and the light's lens. */
        attribute mass : MassValue default = 18 [g];
    }
    part def SeatpostClamp {
        doc /* A band clamp for round seatposts with a quarter-turn mount for
             * the unit. Seatposts lean from 68° to 78°, so the mount adjusts in
             * steps to aim the radar level, leaving at most half a step of aim
             * error. The quarter-turn lock slips far less than a strap. */
        attribute mass : MassValue default = 10 [g];
        attribute minDiameter : LengthValue default = 22 [mm];
        attribute maxDiameter : LengthValue default = 35 [mm];
        attribute adjustmentStep : PlaneAngleValue default = 2.5 ['°'];
        attribute aimError : PlaneAngleValue default = adjustmentStep / 2;
        attribute slipAngle : PlaneAngleValue default = 0.5 ['°'];
        port seatpost : SeatpostMount;
    }

    // ---- Constants ---------------------------------------------------------

    attribute speedOfLight : SpeedValue = 299792458 [m/s];
    attribute boltzmann : ScalarQuantityValue = 1.380649e-23 [J/K];
    attribute noiseTemperature : ThermodynamicTemperatureValue = 290 [K];

    // ---- Calculations ------------------------------------------------------

    calc def RadarEquationRange {
        doc /* The radar equation for an FMCW radar: the farthest range at
             * which a target of the given radar cross-section still gives the
             * minimum signal-to-noise ratio, integrating over a frame's chirps
             * and every receive channel. */
        in radar : RadarModule;
        in rcs : AreaValue;
        return : LengthValue = (
            radar.txPower * radar.txGain * radar.rxGain * radar.wavelength ^ 2 * rcs
                * radar.observationTime * radar.rxChannels
            / ((4 * pi) ^ 3 * boltzmann * noiseTemperature
                * radar.noiseFigure * radar.losses * radar.minSnr)
        ) ^ 0.25;
    }

    calc def ShorterOf {
        in a : LengthValue;
        in b : LengthValue;
        return : LengthValue = if a <= b ? a else b;
    }

    calc def LowerOf {
        in a : PowerValue;
        in b : PowerValue;
        return : PowerValue = if a <= b ? a else b;
    }

    calc def TiltedDetectionRange {
        doc /* The detection range when the beam is tilted up or down. Each way
             * the beam's gain falls off as a Gaussian of the tilt over the
             * elevation beamwidth, so the range from the radar equation falls
             * by 2^(-2 (tilt / beamwidth)^2). No tilt lets the radar see past
             * what its IF carries. */
        in radar : RadarModule;
        in rcs : AreaValue;
        in tilt : PlaneAngleValue;
        return : LengthValue = ShorterOf(
            RadarEquationRange(radar, rcs) * 2 ^ (-2 * (tilt / radar.elevationBeamwidth) ^ 2),
            radar.ifLimitedRange);
    }

    calc def DetectionRange {
        doc /* The detection range with the beam level. */
        in radar : RadarModule;
        in rcs : AreaValue;
        return : LengthValue = TiltedDetectionRange(radar, rcs, 0 ['°']);
    }

    calc def Runtime {
        doc /* How long an amount of energy lasts at a steady power. */
        in energy : EnergyValue;
        in power : PowerValue;
        return : DurationValue = energy / power;
    }

    // ---- The rear unit, opened up ------------------------------------------

    part def RearUnitDesign :> RearUnit {
        doc /* The rear unit as it is built. */

        // The radar the band trade study chose.
        part radarModule : Awrl6432Radar;
        part mcu : Mcu;
        part button : Button;
        part ledDriver : LedDriver;
        part leds : RearLeds;
        part radarCoreBuck : RadarCoreBuck;
        part radarIoBuck : RadarIoBuck;
        // The cell the battery trade study chose.
        part battery : LowTemperaturePouchCell;
        part powerManager : PowerManager;
        part usbCReceptacle : UsbCReceptacle;
        part enclosure : Enclosure;
        part clamp : SeatpostClamp;

        // The black box's ports, delegated to the part that serves each one.
        bind radar = radarModule.antenna;
        bind rearLight = leds.light;
        bind ble = mcu.ble;
        bind usbC = usbCReceptacle.plug;
        bind mount = clamp.seatpost;

        // Sensing and alerting
        flow detections of Detections from radarModule.data.detections to mcu.radarData.detections;
        flow radarConfig of RadarConfig from mcu.radarData.config to radarModule.data.config;

        // Control
        flow buttonPress of ButtonPress from button.press.press to mcu.button.press;
        flow cellVoltage of CellVoltage from battery.sense.voltage to powerManager.cellSense.voltage;
        flow fuelGauge of FuelGauge from powerManager.fuelGauge.reading to mcu.fuelGauge.reading;

        // Light
        flow ledControl of LedControl from mcu.led.pwm to ledDriver.control.pwm;
        flow ledCurrent of LedCurrent from ledDriver.drive.current to leds.drive.current;

        // Power
        flow usbPower of ChargingPower from usbCReceptacle.board.power to powerManager.input.power;
        flow chargeCurrent of ChargeCurrent from powerManager.charge.current to battery.charge.current;
        flow managerSupply of CellPower from battery.supply.power to powerManager.cell.power;
        flow coreBuckSupply of CellPower from battery.supply.power to radarCoreBuck.input.power;
        flow ioBuckSupply of CellPower from battery.supply.power to radarIoBuck.input.power;
        flow ledSupply of CellPower from battery.supply.power to ledDriver.supply.power;
        flow radarCoreRail of RailPower from radarCoreBuck.output.power to radarModule.coreSupply.power;
        flow radarIoRail of RailPower from radarIoBuck.output.power to radarModule.ioSupply.power;
        flow mcuRail of RailPower from powerManager.mcuRail.power to mcu.supply.power;

        // Budgets: the black box's attributes, from the parts' Model Values.
        attribute :>> mass = radarModule.mass + mcu.mass + button.mass + ledDriver.mass
            + leds.mass + radarCoreBuck.mass + radarIoBuck.mass + battery.mass + powerManager.mass
            + usbCReceptacle.mass + enclosure.mass + clamp.mass;
        // Judged with the mounting tilted as far as it can be.
        attribute riderSag : PlaneAngleValue default = 2 ['°'] {
            doc /* How far the bike pitches back under the rider's weight. */
        }
        attribute worstCaseTilt : PlaneAngleValue = clamp.aimError + clamp.slipAngle + riderSag;
        attribute :>> detectionRange = TiltedDetectionRange(
            radarModule, radarModule.designTargetRcs, worstCaseTilt);
        attribute :>> alertLatency = mcu.alertLatency;
        attribute :>> maxTrackedVehicles = mcu.maxTrackedVehicles;
        attribute :>> maxClosingSpeed = radarModule.maxClosingSpeed;
        attribute :>> rangeResolution = radarModule.rangeResolution;
        attribute :>> radarEirp = radarModule.eirp;
        attribute :>> radarMaxEirp = radarModule.bandMaxEirp;
        attribute :>> radarOutputPower = radarModule.txPower;
        attribute :>> radarMaxOutputPower = radarModule.bandMaxOutputPower;
        attribute :>> speedResolution = radarModule.speedResolution;
        attribute :>> daylightVisibility = leds.daylightVisibility;
        attribute :>> minSeatpostDiameter = clamp.minDiameter;
        attribute :>> maxSeatpostDiameter = clamp.maxDiameter;
        // The cell is the part with the narrowest temperature range.
        attribute :>> minOperatingTemperature = battery.minDischargeTemperature;
        attribute :>> maxOperatingTemperature = battery.maxDischargeTemperature;

        // Power drawn from the cell in each mode that is on, losses included.
        // Both radar bucks are taken as equally efficient, so how the radar
        // splits its power between the rails does not matter.
        attribute radarOnlyPower : PowerValue =
            radarModule.power / radarCoreBuck.efficiency + mcu.power / powerManager.mcuRailEfficiency;
        attribute dayFlashPower : PowerValue = radarOnlyPower + leds.dayFlashPower / ledDriver.efficiency;
        attribute nightSolidPower : PowerValue = radarOnlyPower + leds.nightSolidPower / ledDriver.efficiency;

        // Runtime in each mode on a cold, aged cell, and the time to charge it.
        attribute :>> runtimeDayFlash = Runtime(battery.usableEnergy, dayFlashPower);
        attribute :>> runtimeNightSolid = Runtime(battery.usableEnergy, nightSolidPower);
        attribute :>> chargeTime =
            Runtime(battery.energy, powerManager.chargePower) * powerManager.constantVoltageStretch;

        assert constraint railsMatchRadar {
            doc /* Each radar buck makes the voltage its rail needs. */
            radarCoreBuck.outputVoltage == radarModule.coreVoltage and
            radarIoBuck.outputVoltage == radarModule.ioVoltage
        }
        assert constraint radarBucksCoverPeak {
            doc /* Each radar buck supplies its rail's peak current in a chirp
             * burst, not just the average over a frame. */
            radarModule.corePeakCurrent <= radarCoreBuck.maxOutputCurrent and
            radarModule.ioPeakCurrent <= radarIoBuck.maxOutputCurrent
        }
        assert constraint mcuRailCoversPeak {
            doc /* The power manager's buck supplies the MCU at its peak. */
            mcu.peakCurrent <= powerManager.mcuRailMaxCurrent
        }
        assert constraint alertWithinLatency {
            doc /* A track is confirmed over two radar frames, which must fit in
             * the time the MCU has to alert the head unit. */
            2 * radarModule.framePeriod <= mcu.alertLatency
        }
        assert constraint cellWithinRating {
            doc /* The cell can supply the unit in its hungriest mode. */
            nightSolidPower <= battery.maxDischargePower
        }
    }

    part rearUnit : RearUnitDesign;
}
