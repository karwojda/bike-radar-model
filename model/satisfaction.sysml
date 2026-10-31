package BikeRadarSatisfaction {
    doc /* Which system requirements the rear unit as built claims to satisfy.
         * Ingress protection waits for a test. The head unit protocols wait
         * for firmware: the chosen MCU can speak ANT+ and Bluetooth Low
         * Energy, but nothing does yet. */

    private import BikeRadarRequirements::*;
    private import BikeRadarArchitecture::*;

    satisfy systemSpec.detectionRange by rearUnit;
    satisfy systemSpec.alertLatency by rearUnit;
    satisfy systemSpec.trackedVehicles by rearUnit;
    satisfy systemSpec.closingSpeed by rearUnit;
    satisfy systemSpec.rangeResolution by rearUnit;
    satisfy systemSpec.speedResolution by rearUnit;
    satisfy systemSpec.daylightVisibility by rearUnit;
    satisfy systemSpec.totalMass by rearUnit;
    satisfy systemSpec.seatpostFit by rearUnit;
    satisfy systemSpec.runtimeNightSolid by rearUnit;
    satisfy systemSpec.runtimeDayFlash by rearUnit;
    satisfy systemSpec.chargeTime by rearUnit;
    satisfy systemSpec.operatingTemperature by rearUnit;
    satisfy systemSpec.radioEmissions by rearUnit;
}
