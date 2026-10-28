package BikeRadarAnalysis {
    doc /* How far and how fast the radar sees, how long the rear unit runs in
         * each mode, and the trade study that chose its cell. */

    private import ISQ::*;
    private import SI::*;
    private import ScalarValues::*;
    private import TradeStudies::*;
    private import BikeRadarArchitecture::*;

    // ---- Runtime per operating mode ----------------------------------------

    analysis def ModeRuntime {
        doc /* How long the unit lasts in one mode on a cold, aged cell. The
             * black box's runtimes, which S5 and S6 judge, come from the same
             * calculation. Off is not analysed: it draws microamps, and the
             * cell's own self-discharge empties it first. */
        subject unit : RearUnitDesign;
        in attribute modePower : PowerValue;
        return runtime : DurationValue = Runtime(unit.battery.usableEnergy, modePower);
    }

    analysis dayFlashRuntime : ModeRuntime {
        subject :>> unit = rearUnit;
        in attribute :>> modePower = rearUnit.dayFlashPower;
    }
    analysis nightSolidRuntime : ModeRuntime {
        subject :>> unit = rearUnit;
        in attribute :>> modePower = rearUnit.nightSolidPower;
    }
    analysis radarOnlyRuntime : ModeRuntime {
        doc /* No requirement; riders ask how long the radar lasts alone. */
        subject :>> unit = rearUnit;
        in attribute :>> modePower = rearUnit.radarOnlyPower;
    }

    // ---- Radar performance -------------------------------------------------

    analysis def TargetDetectionRange {
        doc /* How far away the radar detects a target of a given radar
             * cross-section. */
        subject radar : RadarModule;
        in attribute rcs : AreaValue;
        return range : LengthValue = DetectionRange(radar, rcs);
    }

    analysis motorbikeDetectionRange : TargetDetectionRange {
        doc /* A motorbike seen from the front reflects about a fifth of what a
             * car does. S1 covers only cars, so this range has no requirement
             * yet. */
        subject :>> radar = rearUnit.radarModule;
        in attribute :>> rcs = 2 [m^2];
    }

    analysis def WarningTime {
        doc /* How long the rider is warned before a vehicle closing at a steady
             * speed reaches them: from first detection, less the time to alert
             * the head unit. */
        subject unit : RearUnitDesign;
        in attribute closingSpeed : SpeedValue;
        return warning : DurationValue = unit.detectionRange / closingSpeed - unit.alertLatency;
    }

    analysis fastCarWarningTime : WarningTime {
        doc /* A car at 120 km/h behind a rider who has stopped, the fastest
             * closing speed S12 asks the radar to measure. */
        subject :>> unit = rearUnit;
        in attribute :>> closingSpeed = 120 [km/h];
    }

    // ---- Mounting tilt -----------------------------------------------------

    attribute riderSag : PlaneAngleValue = 2 ['°'] {
        doc /* How far the bike pitches back under the rider's weight. */
    }

    analysis def TiltedDetectionRange {
        doc /* How far away the radar detects a car when its beam is tilted up or
             * down by the mounting. Each way the beam's gain falls off as a
             * Gaussian of the tilt over the elevation beamwidth, so the range
             * falls by 2^(-2 (tilt / beamwidth)^2). S1's 140 m tolerates a tilt
             * of up to 9.1° with today's radar. */
        subject radar : RadarModule;
        in attribute tilt : PlaneAngleValue;
        return range : LengthValue =
            DetectionRange(radar, radar.designTargetRcs)
                * 2 ^ (-2 * (tilt / radar.elevationBeamwidth) ^ 2);
    }

    analysis worstCaseTiltRange : TiltedDetectionRange {
        doc /* Every source of tilt at its limit, in the same direction. */
        subject :>> radar = rearUnit.radarModule;
        in attribute :>> tilt =
            rearUnit.clamp.seatpostAngleSpread + rearUnit.clamp.slipAngle + riderSag;
    }
    analysis likelyTiltRange : TiltedDetectionRange {
        doc /* The sources of tilt are independent, so they add as a root sum
             * of squares. */
        subject :>> radar = rearUnit.radarModule;
        in attribute :>> tilt = (rearUnit.clamp.seatpostAngleSpread ^ 2
            + rearUnit.clamp.slipAngle ^ 2 + riderSag ^ 2) ^ 0.5;
    }

    // ---- Battery trade study -----------------------------------------------

    part cylindricalCell : CylindricalCell;
    part pouchCell : PouchCell;
    part lowTemperaturePouchCell : LowTemperaturePouchCell;

    calc def ColdCellMass {
        doc /* The cell's mass in grams if its usable energy covers what is
             * required, and 1000 if not, so a cell that falls short is never
             * chosen. A trade study's evaluation must give a plain number. */
        in part cell : Battery;
        in requiredEnergy : EnergyValue;
        return : Real =
            if cell.usableEnergy >= requiredEnergy ? cell.mass / 1 [g] else 1000.0;
    }

    analysis batteryTradeStudy : TradeStudy {
        doc /* The lightest cell that lasts the 16 h of day flash S6 asks for when
             * cold and aged. The cylindrical cell first chosen made the unit too
             * heavy for S8. RearUnitDesign takes the chosen cell by hand; nothing
             * re-runs the study when the parts change. */
        subject : Battery = (cylindricalCell, pouchCell, lowTemperaturePouchCell);
        objective : MinimizeObjective;
        calc :>> evaluationFunction {
            in part cell :>> alternative : Battery;
            return :>> result : Real = ColdCellMass(cell, rearUnit.dayFlashPower * 16 [h]);
        }
        return part :>> selectedAlternative : Battery;
    }
}
