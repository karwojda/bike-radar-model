package BikeRadarViews {
    doc /* The pictures an engineer keeps of the rear radar light. */

    private import Views::*;
    private import StandardViewDefinitions::*;
    private import BikeRadarRequirements::*;
    private import BikeRadarContext::*;
    private import BikeRadarArchitecture::*;
    private import BikeRadarModes::*;
    private import BikeRadarAnalysis::*;

    view needs {
        doc /* The rider's needs. */
        expose riderNeeds::**;
        render asTreeDiagram;
    }

    view systemRequirements {
        doc /* The system requirements, grouped under the system spec. */
        expose systemSpec::**;
        render asTreeDiagram;
    }

    view rideContext {
        doc /* The rear unit on the bike, with the vehicle behind and the head unit. */
        expose ride;
        render asInterconnectionDiagram;
    }

    view chargeContext {
        doc /* The rear unit on its charger. */
        expose charging;
        render asInterconnectionDiagram;
    }

    view partTree {
        doc /* What the rear unit is built from. */
        expose rearUnit::**;
        render asTreeDiagram;
    }

    view internalStructure {
        doc /* How the parts inside the rear unit are wired together. */
        expose rearUnit;
        render asInterconnectionDiagram;
    }

    view satisfaction {
        doc /* The system requirements, and the rear unit as built claiming to satisfy them. */
        expose systemSpec::**;
        expose rearUnit;
        render asTreeDiagram;
    }

    view radarPerformance {
        doc /* How far and how fast the radar sees, and how much warning the rider gets. */
        expose motorbikeDetectionRange;
        expose fastCarWarningTime;
        expose RearUnitDesign::radarModule;
        render asTreeDiagram;
    }

    view mountingTilt {
        doc /* How the mounting's tilt shortens the radar's reach. */
        expose worstCaseTiltRange;
        expose likelyTiltRange;
        expose RearUnitDesign::radarModule;
        expose RearUnitDesign::clamp;
        render asTreeDiagram;
    }

    view runtimes {
        doc /* How long the rear unit runs in each mode. */
        expose dayFlashRuntime;
        expose nightSolidRuntime;
        expose radarOnlyRuntime;
        expose rearUnit;
        render asTreeDiagram;
    }

    view tradeStudy {
        doc /* The cells weighed against each other, and the one chosen. */
        expose batteryTradeStudy;
        expose cylindricalCell;
        expose pouchCell;
        expose lowTemperaturePouchCell;
        render asTreeDiagram;
    }

    view radarTradeStudy {
        doc /* The radar chips weighed against each other, one per band. */
        expose BikeRadarAnalysis::radarTradeStudy;
        expose awrl6432Radar;
        expose awrl1432Radar;
        expose bgt24Mtr12Radar;
        render asTreeDiagram;
    }

    view operatingModes : StateTransitionView {
        doc /* Off, and the three modes the button cycles through when on. */
        expose OperatingModes;
    }
}
