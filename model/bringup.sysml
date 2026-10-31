package BikeRadarBringUp {
    doc /* The bench the firmware is brought up on before the board exists: a
         * dev kit for each production part that has one, wired as the rear
         * unit is. Each kit stands in for a production part. */

    private import ScalarValues::*;
    private import BikeRadarContext::*;
    private import BikeRadarArchitecture::*;

    // ---- Dev kits ------------------------------------------------------------

    part def DevKit {
        doc /* An evaluation board from the maker of a production part. */
        attribute maker : String;
    }
    part def RadarEvm :> DevKit {
        doc /* TI AWRL6432BOOST: the AWRL6432 with an antenna on FR4, powered
             * over USB, with a debugger on board. TI's mmWave SDK runs on the
             * chip's Cortex-M4F; the MCU configures it and reads detections. */
        attribute :>> maker default = "Texas Instruments";
        port data : RadarDataPort;
    }
    part def McuDk :> DevKit {
        doc /* Nordic nRF54L15-DK: the nRF54L15 with a J-Link debugger on board,
             * where the Rust firmware on Zephyr is brought up. Its own buttons
             * stand in for the unit's button. It carries an nPM1300 of its
             * own, but only to power itself. */
        attribute :>> maker default = "Nordic Semiconductor";
        port radarData : ~RadarDataPort;
        port ble : BlePort;
        port led : LedControlPort;
        port fuelGauge : ~FuelGaugePort;
        port supply : ~RailPort;
    }
    part def PowerManagerEk :> DevKit {
        doc /* Nordic nPM1300-EK, with a sample of the chosen cell: charging,
             * the MCU's rail and the fuel gauge, checked against the real
             * cell. The nPM PowerUP app sets it up without firmware. */
        attribute :>> maker default = "Nordic Semiconductor";
        port charge : ChargePort;
        port cellSense : ~CellSensePort;
        port fuelGauge : FuelGaugePort;
        port mcuRail : RailPort;
    }
    part def RadarCoreBuckEvm :> DevKit {
        doc /* TI TPS62088AEVM-187. It carries the TPS62088A, the same 3 A
             * converter as the TPS62088. The radar EVM powers itself, so this
             * one is tested on an electronic load stepping the radar's 1.1 A
             * peak on the 1.2 V rail. */
        attribute :>> maker default = "Texas Instruments";
        port output : RailPort;
    }
    part def RadarIoBuckEvm :> DevKit {
        doc /* TI TPS62840-1DLCEVM55, tested like the core buck's EVM, at the
             * 1.8 V rail's 360 mA peak. */
        attribute :>> maker default = "Texas Instruments";
        port output : RailPort;
    }
    part def LedDriverEvm :> DevKit {
        doc /* TI TPS61160EVM-243. It carries the TPS61160, the sibling of the
             * TPS61160A; its white LEDs are swapped for the three red ones. */
        attribute :>> maker default = "Texas Instruments";
        port control : ~LedControlPort;
        port drive : LedDrivePort;
    }

    // ---- The bench -------------------------------------------------------------

    part def BenchRig {
        doc /* The dev kits wired as the rear unit is, with the production cell
             * and LEDs, which need no kit. The button and the USB-C socket are
             * not on the bench: the dev kit's buttons and USB stand in. */

        part radarEvm : RadarEvm;
        part mcuDk : McuDk;
        part powerManagerEk : PowerManagerEk;
        part radarCoreBuckEvm : RadarCoreBuckEvm;
        part radarIoBuckEvm : RadarIoBuckEvm;
        part ledDriverEvm : LedDriverEvm;
        part battery : LowTemperaturePouchCell;
        part leds : RearLeds;

        // Sensing and alerting
        flow detections of Detections from radarEvm.data.detections to mcuDk.radarData.detections;
        flow radarConfig of RadarConfig from mcuDk.radarData.config to radarEvm.data.config;

        // Light
        flow ledControl of LedControl from mcuDk.led.pwm to ledDriverEvm.control.pwm;
        flow ledCurrent of LedCurrent from ledDriverEvm.drive.current to leds.drive.current;

        // Power
        flow chargeCurrent of ChargeCurrent from powerManagerEk.charge.current to battery.charge.current;
        flow cellVoltage of CellVoltage from battery.sense.voltage to powerManagerEk.cellSense.voltage;
        flow fuelGauge of FuelGauge from powerManagerEk.fuelGauge.reading to mcuDk.fuelGauge.reading;
        flow mcuRail of RailPower from powerManagerEk.mcuRail.power to mcuDk.supply.power;
    }

    part benchRig : BenchRig;

    // ---- What each kit stands in for -------------------------------------------

    dependency radarStandIn from BenchRig::radarEvm to RearUnitDesign::radarModule;
    dependency mcuStandIn from BenchRig::mcuDk to RearUnitDesign::mcu;
    dependency buttonStandIn from BenchRig::mcuDk to RearUnitDesign::button;
    dependency powerManagerStandIn from BenchRig::powerManagerEk to RearUnitDesign::powerManager;
    dependency radarCoreBuckStandIn from BenchRig::radarCoreBuckEvm to RearUnitDesign::radarCoreBuck;
    dependency radarIoBuckStandIn from BenchRig::radarIoBuckEvm to RearUnitDesign::radarIoBuck;
    dependency ledDriverStandIn from BenchRig::ledDriverEvm to RearUnitDesign::ledDriver;
}
