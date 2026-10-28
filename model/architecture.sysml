package BikeRadarArchitecture {
    doc /* Inside the rear unit: the parts it is built from and how they are
         * wired together. */

    private import ISQ::*;
    private import SI::*;
    private import ScalarValues::*;
    private import BikeRadarContext::*;

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
        doc /* A regulated 3.3 V rail for the radar and the MCU. */
    }
    item def CellVoltage {
        doc /* The cell voltage, sensed by the MCU to detect an empty battery. */
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
    port def ButtonPort {
        out item press : ButtonPress;
    }

    // ---- Parts -------------------------------------------------------------

    part def RadarModule {
        doc /* A 77 GHz FMCW radar chip with its antennas in the package. It
             * chirps in short bursts, so its power is an average over a frame. */
        attribute mass : MassValue default = 6 [g];
        attribute power : PowerValue default = 0.12 [W];
        attribute detectionRange : LengthValue default = 150 [m];
        port antenna : RadarPort;
        port data : RadarDataPort;
        port supply : ~RailPort;
    }
    part def Mcu {
        doc /* A microcontroller with Bluetooth Low Energy: tracks vehicles from
             * the radar's detections, alerts the head unit and runs the modes. */
        attribute mass : MassValue default = 2 [g];
        attribute power : PowerValue default = 0.015 [W];
        attribute alertLatency : DurationValue default = 0.25 [s];
        attribute maxTrackedVehicles : Natural default = 8;
        port radarData : ~RadarDataPort;
        port ble : BlePort;
        port led : LedControlPort;
        port button : ~ButtonPort;
        port cellSense : ~CellSensePort;
        port supply : ~RailPort;
    }
    part def Button {
        doc /* A sealed push button on the back of the unit. */
        attribute mass : MassValue default = 1 [g];
        port press : ButtonPort;
    }
    part def LedDriver {
        doc /* A constant-current boost driver for the LED string, fed from the
             * cell. Its power is what it loses, about a tenth of the LEDs' power. */
        attribute mass : MassValue default = 1 [g];
        attribute dayFlashPower : PowerValue default = 0.01 [W];
        attribute nightSolidPower : PowerValue default = 0.015 [W];
        port control : ~LedControlPort;
        port drive : LedDrivePort;
        port supply : ~CellPort;
    }
    part def RearLeds {
        doc /* Red high-power LEDs behind a lens. Day flash averages the bright
             * pulses; night solid is steady at lower brightness. */
        attribute mass : MassValue default = 4 [g];
        attribute dayFlashPower : PowerValue default = 0.08 [W];
        attribute nightSolidPower : PowerValue default = 0.12 [W];
        attribute daylightVisibility : LengthValue default = 1.6 [km];
        port drive : ~LedDrivePort;
        port light : LightPort;
    }
    part def Regulator {
        doc /* A buck-boost converter making 3.3 V from the cell. Its power is
             * what it loses at the radar's and MCU's load. */
        attribute mass : MassValue default = 1 [g];
        attribute power : PowerValue default = 0.015 [W];
        attribute maxOutputPower : PowerValue default = 0.5 [W];
        port input : ~CellPort;
        port output : RailPort;
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
    part def Charger {
        doc /* A Li-ion charge controller fed from USB-C, charging at 1 A, about
             * 3.7 W into the cell. The constant-voltage phase at the end of a
             * charge stretches it by about a third. */
        attribute mass : MassValue default = 1 [g];
        attribute chargePower : PowerValue default = 3.7 [W];
        attribute constantVoltageStretch : Real default = 1.3;
        port input : UsbCPort;
        port charge : ChargePort;
    }
    part def UsbCReceptacle {
        doc /* A sealed USB-C socket, power pins only. */
        attribute mass : MassValue default = 1 [g];
        port plug : UsbCPort;
        port board : ~UsbCPort;
    }
    part def Enclosure {
        doc /* The IP67 housing and the light's lens. */
        attribute mass : MassValue default = 18 [g];
    }
    part def SeatpostClamp {
        doc /* A rubber strap mount for round seatposts. */
        attribute mass : MassValue default = 8 [g];
        attribute minDiameter : LengthValue default = 22 [mm];
        attribute maxDiameter : LengthValue default = 35 [mm];
        port seatpost : SeatpostMount;
    }

    // ---- Calculations ------------------------------------------------------

    calc def Runtime {
        doc /* How long an amount of energy lasts at a steady power. */
        in energy : EnergyValue;
        in power : PowerValue;
        return : DurationValue = energy / power;
    }

    // ---- The rear unit, opened up ------------------------------------------

    part def RearUnitDesign :> RearUnit {
        doc /* The rear unit as it is built. */

        part radarModule : RadarModule;
        part mcu : Mcu;
        part button : Button;
        part ledDriver : LedDriver;
        part leds : RearLeds;
        part regulator : Regulator;
        // The cell the battery trade study chose.
        part battery : LowTemperaturePouchCell;
        part charger : Charger;
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
        flow cellVoltage of CellVoltage from battery.sense.voltage to mcu.cellSense.voltage;

        // Light
        flow ledControl of LedControl from mcu.led.pwm to ledDriver.control.pwm;
        flow ledCurrent of LedCurrent from ledDriver.drive.current to leds.drive.current;

        // Power
        flow usbPower of ChargingPower from usbCReceptacle.board.power to charger.input.power;
        flow chargeCurrent of ChargeCurrent from charger.charge.current to battery.charge.current;
        flow regulatorSupply of CellPower from battery.supply.power to regulator.input.power;
        flow ledSupply of CellPower from battery.supply.power to ledDriver.supply.power;
        flow radarSupply of RailPower from regulator.output.power to radarModule.supply.power;
        flow mcuSupply of RailPower from regulator.output.power to mcu.supply.power;

        // Budgets: the black box's attributes, from the parts' Model Values.
        attribute :>> mass = radarModule.mass + mcu.mass + button.mass + ledDriver.mass
            + leds.mass + regulator.mass + battery.mass + charger.mass
            + usbCReceptacle.mass + enclosure.mass + clamp.mass;
        attribute :>> detectionRange = radarModule.detectionRange;
        attribute :>> alertLatency = mcu.alertLatency;
        attribute :>> maxTrackedVehicles = mcu.maxTrackedVehicles;
        attribute :>> daylightVisibility = leds.daylightVisibility;
        attribute :>> minSeatpostDiameter = clamp.minDiameter;
        attribute :>> maxSeatpostDiameter = clamp.maxDiameter;
        // The cell is the part with the narrowest temperature range.
        attribute :>> minOperatingTemperature = battery.minDischargeTemperature;
        attribute :>> maxOperatingTemperature = battery.maxDischargeTemperature;

        // Power drawn from the cell in each mode that is on.
        attribute railPower : PowerValue = radarModule.power + mcu.power;
        attribute radarOnlyPower : PowerValue = railPower + regulator.power;
        attribute dayFlashPower : PowerValue =
            radarOnlyPower + ledDriver.dayFlashPower + leds.dayFlashPower;
        attribute nightSolidPower : PowerValue =
            radarOnlyPower + ledDriver.nightSolidPower + leds.nightSolidPower;

        // Runtime in each mode on a cold, aged cell, and the time to charge it.
        attribute :>> runtimeDayFlash = Runtime(battery.usableEnergy, dayFlashPower);
        attribute :>> runtimeNightSolid = Runtime(battery.usableEnergy, nightSolidPower);
        attribute :>> chargeTime =
            Runtime(battery.energy, charger.chargePower) * charger.constantVoltageStretch;

        assert constraint regulatorWithinRating {
            doc /* The regulator can supply the radar and the MCU. */
            railPower <= regulator.maxOutputPower
        }
        assert constraint cellWithinRating {
            doc /* The cell can supply the unit in its hungriest mode. */
            nightSolidPower <= battery.maxDischargePower
        }
    }

    part rearUnit : RearUnitDesign;
}
