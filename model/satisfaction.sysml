package BikeRadarSatisfaction {
    doc /* Which system requirements the rear unit as built claims to satisfy.
         * Ingress protection waits for a test. */

    private import BikeRadarRequirements::*;
    private import BikeRadarArchitecture::*;

    satisfy systemSpec.detectionRange by rearUnit;
    satisfy systemSpec.alertLatency by rearUnit;
    satisfy systemSpec.trackedVehicles by rearUnit;
    satisfy systemSpec.closingSpeed by rearUnit;
    satisfy systemSpec.daylightVisibility by rearUnit;
    satisfy systemSpec.totalMass by rearUnit;
    satisfy systemSpec.seatpostFit by rearUnit;
    satisfy systemSpec.runtimeNightSolid by rearUnit;
    satisfy systemSpec.runtimeDayFlash by rearUnit;
    satisfy systemSpec.chargeTime by rearUnit;
    satisfy systemSpec.operatingTemperature by rearUnit;
}
