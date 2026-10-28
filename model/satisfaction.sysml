package BikeRadarSatisfaction {
    doc /* Which system requirements the rear unit as built claims to satisfy.
         * Runtime and charge time wait for the runtime analysis; ingress
         * protection waits for a test. */

    private import BikeRadarRequirements::*;
    private import BikeRadarArchitecture::*;

    satisfy systemSpec.detectionRange by rearUnit;
    satisfy systemSpec.alertLatency by rearUnit;
    satisfy systemSpec.trackedVehicles by rearUnit;
    satisfy systemSpec.daylightVisibility by rearUnit;
    satisfy systemSpec.totalMass by rearUnit;
    satisfy systemSpec.seatpostFit by rearUnit;
    satisfy systemSpec.operatingTemperature by rearUnit;
}
