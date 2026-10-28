package BikeRadarViews {
    doc /* The pictures an engineer keeps of the rear radar light. */

    private import Views::*;
    private import BikeRadarRequirements::*;
    private import BikeRadarContext::*;

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
}
