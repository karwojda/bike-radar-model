package BikeRadarArchitecture {
    doc /* Inside the rear unit: the parts it is built from and how they are
         * wired together. */

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
        doc /* A 77 GHz FMCW radar chip with its antennas in the package. */
        port antenna : RadarPort;
        port data : RadarDataPort;
        port supply : ~RailPort;
    }
    part def Mcu {
        doc /* A microcontroller with Bluetooth Low Energy: tracks vehicles from
             * the radar's detections, alerts the head unit and runs the modes. */
        port radarData : ~RadarDataPort;
        port ble : BlePort;
        port led : LedControlPort;
        port button : ~ButtonPort;
        port cellSense : ~CellSensePort;
        port supply : ~RailPort;
    }
    part def Button {
        doc /* A sealed push button on the back of the unit. */
        port press : ButtonPort;
    }
    part def LedDriver {
        doc /* A constant-current boost driver for the LED string, fed from the cell. */
        port control : ~LedControlPort;
        port drive : LedDrivePort;
        port supply : ~CellPort;
    }
    part def RearLeds {
        doc /* Red high-power LEDs behind a lens. */
        port drive : ~LedDrivePort;
        port light : LightPort;
    }
    part def Regulator {
        doc /* A buck-boost converter making 3.3 V from the cell. */
        port input : ~CellPort;
        port output : RailPort;
    }
    part def Battery {
        doc /* A single Li-ion cell. */
        port charge : ~ChargePort;
        port supply : CellPort;
        port sense : CellSensePort;
    }
    part def Charger {
        doc /* A Li-ion charge controller fed from USB-C. */
        port input : UsbCPort;
        port charge : ChargePort;
    }
    part def UsbCReceptacle {
        doc /* A sealed USB-C socket, power pins only. */
        port plug : UsbCPort;
        port board : ~UsbCPort;
    }
    part def Enclosure {
        doc /* The IP67 housing and the light's lens. */
    }
    part def SeatpostClamp {
        doc /* A rubber strap mount for round seatposts. */
        port seatpost : SeatpostMount;
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
        part battery : Battery;
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
    }

    part rearUnit : RearUnitDesign;
}
