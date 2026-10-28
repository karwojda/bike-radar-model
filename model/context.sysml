package BikeRadarContext {
    doc /* The rear radar light as a black box on the bike, and everything it
         * talks to: the vehicle behind, the rider's head unit, the seatpost
         * it clamps to and the charger. */

    private import ISQ::*;
    private import SI::*;
    private import ScalarValues::*;
    private import BikeRadarModes::*;

    // ---- Items -------------------------------------------------------------

    item def RadarSignal {
        doc /* 77 GHz FMCW radar chirps out, and their reflections back. */
    }
    item def RearLight {
        doc /* Visible red light emitted rearward. */
    }
    item def ThreatAlert {
        doc /* Distance, closing speed and threat level of each tracked vehicle. */
    }
    item def ModeCommand {
        doc /* A request from the head unit to change the light mode. */
    }
    item def ChargingPower {
        doc /* 5 V DC from a USB-C supply. */
    }

    // ---- Ports -------------------------------------------------------------

    port def RadarPort {
        out item chirp : RadarSignal;
        in item echo : RadarSignal;
    }
    port def LightPort {
        out item light : RearLight;
    }
    port def BlePort {
        out item alert : ThreatAlert;
        in item command : ModeCommand;
    }
    port def UsbCPort {
        in item power : ChargingPower;
    }
    port def SeatpostMount {
        doc /* Clamp interface to a round seatpost. */
    }

    interface def BleLink {
        doc /* Bluetooth Low Energy link between the rear unit and a head unit. */
        end rearUnit : BlePort;
        end headUnit : ~BlePort;
    }

    // ---- The system of interest ----------------------------------------------

    part def RearUnit {
        doc /* The rear radar light: a radar that warns of vehicles from
             * behind, and a rear light, in one seatpost-mounted unit. */

        attribute mass : MassValue;
        attribute detectionRange : LengthValue;
        attribute alertLatency : DurationValue;
        attribute maxTrackedVehicles : Natural;
        attribute daylightVisibility : LengthValue;
        attribute runtimeNightSolid : DurationValue;
        attribute runtimeDayFlash : DurationValue;
        attribute chargeTime : DurationValue;
        attribute minSeatpostDiameter : LengthValue;
        attribute maxSeatpostDiameter : LengthValue;
        attribute minOperatingTemperature : TemperatureValue;
        attribute maxOperatingTemperature : TemperatureValue;

        port radar : RadarPort;
        port rearLight : LightPort;
        port ble : BlePort;
        port usbC : UsbCPort;
        port mount : SeatpostMount;

        exhibit state modes : OperatingModes;
    }

    // ---- External actors ---------------------------------------------------

    part def Rider {
        doc /* The person riding the bike, who mounts, charges and listens to the unit. */
    }
    part def Bicycle {
        port seatpost : ~SeatpostMount;
    }
    part def HeadUnit {
        doc /* The rider's bike computer or phone, showing radar alerts. */
        port ble : ~BlePort;
    }
    part def ApproachingVehicle {
        doc /* A car, truck or motorbike coming from behind. */
        port reflector : ~RadarPort;
    }
    part def Driver {
        doc /* The driver of the approaching vehicle, who needs to see the rider. */
        port eyes : ~LightPort;
    }
    part def UsbCharger {
        port usbC : ~UsbCPort;
    }

    // ---- Context -------------------------------------------------------------

    part def RideContext {
        doc /* A ride: the rear unit on the bike, a vehicle closing in from behind. */

        part rearUnit : RearUnit;
        ref part rider : Rider;
        part bicycle : Bicycle;
        part headUnit : HeadUnit;
        part vehicle : ApproachingVehicle;
        ref part driver : Driver;

        connect rearUnit.mount to bicycle.seatpost;
        interface bleLink : BleLink connect rearUnit.ble to headUnit.ble;

        flow chirps of RadarSignal from rearUnit.radar.chirp to vehicle.reflector.chirp;
        flow echoes of RadarSignal from vehicle.reflector.echo to rearUnit.radar.echo;
        flow alerts of ThreatAlert from rearUnit.ble.alert to headUnit.ble.alert;
        flow commands of ModeCommand from headUnit.ble.command to rearUnit.ble.command;
        flow light of RearLight from rearUnit.rearLight.light to driver.eyes.light;
    }

    part def ChargeContext {
        doc /* Off the bike, charging from a USB-C supply. */

        part rearUnit : RearUnit;
        part charger : UsbCharger;

        flow charge of ChargingPower from charger.usbC.power to rearUnit.usbC.power;
    }

    part ride : RideContext;
    part charging : ChargeContext;
}
