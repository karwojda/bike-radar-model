package BikeRadarAnalysis {
    doc /* How long the rear unit runs in each mode, and the trade study that
         * chose its cell. */

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
