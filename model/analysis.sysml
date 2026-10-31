package BikeRadarAnalysis {
    doc /* How far and how fast the radar sees, how long the rear unit runs in
         * each mode, and the trade studies that chose its cell and its radar. */

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

    analysis def TiltRange {
        doc /* How far away the radar detects a car when the mounting tilts its
             * beam. S1's 140 m tolerates a tilt of up to 4.6° with today's
             * radar. */
        subject radar : RadarModule;
        in attribute tilt : PlaneAngleValue;
        return range : LengthValue = TiltedDetectionRange(radar, radar.designTargetRcs, tilt);
    }

    analysis worstCaseTiltRange : TiltRange {
        doc /* Every source of tilt at its limit, in the same direction: the
             * case S1 is judged on. */
        subject :>> radar = rearUnit.radarModule;
        in attribute :>> tilt = rearUnit.worstCaseTilt;
    }
    analysis likelyTiltRange : TiltRange {
        doc /* The sources of tilt are independent, so they add as a root sum
             * of squares. */
        subject :>> radar = rearUnit.radarModule;
        in attribute :>> tilt = (rearUnit.clamp.aimError ^ 2
            + rearUnit.clamp.slipAngle ^ 2 + rearUnit.riderSag ^ 2) ^ 0.5;
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

    // ---- Radar band trade study --------------------------------------------

    part awrl6432Radar : Awrl6432Radar;
    part awrl1432Radar : Awrl1432Radar;
    part bgt24Mtr12Radar : Bgt24Mtr12Radar;

    calc def RadarScore {
        doc /* The radar's average power in milliwatts, with its mass in grams
             * as a thousandth part to break ties: power comes first, since it
             * sets how long the unit runs and how big a cell it needs. 1000 if
             * the unit with this radar misses S1 at the worst-case tilt, S5,
             * S6, S8, S12, S14 or S15, on the cell the battery study chose. */
        in part radar : RadarModule;
        in part unit : RearUnitDesign;
        attribute dayFlashPower : PowerValue =
            unit.dayFlashPower - unit.radarModule.power + radar.power;
        attribute nightSolidPower : PowerValue =
            unit.nightSolidPower - unit.radarModule.power + radar.power;
        attribute mass : MassValue = unit.mass - unit.radarModule.mass + radar.mass;
        return : Real =
            if TiltedDetectionRange(radar, radar.designTargetRcs, unit.worstCaseTilt) >= 140 [m]
                and Runtime(unit.battery.usableEnergy, nightSolidPower) >= 8 [h]
                and Runtime(unit.battery.usableEnergy, dayFlashPower) >= 16 [h]
                and mass <= 75 [g]
                and radar.maxClosingSpeed >= 120 [km/h]
                and radar.rangeResolution <= 1 [m]
                and radar.speedResolution <= 2.5 [km/h]
            ? radar.power / 0.001 [W] + radar.mass / 1 [g] / 1000 else 1000.0;
    }

    analysis radarTradeStudy : TradeStudy {
        doc /* One radar chip per band: the one drawing the least power that
         * lets the unit meet the radar, runtime and mass requirements, with
         * mass only breaking ties. Each chip gets its own chirps by the
         * same rules: a 150 MHz sweep, a burst of about 10.4 ms every 100 ms,
         * and chirps long enough that the IF carries 200 m. Speeds are
         * measured one-sided, closing only. Both are assumptions.
         *
         * Each transmitter is turned down to what its band allows in Europe
         * (S16). 24 GHz and 57-64 GHz cap radiated power at 100 mW, so 11 dBm
         * into a 14 dBi antenna drops to 6 dBm; 57-64 GHz also caps output at
         * 10 mW. 76-77 GHz allows 55 dBm and costs nothing.
         *
         * 60 GHz wins at 124 mW: the AWRL6432's quiet receiver gives the
         * most range for the least power, though under the cap it meets S1
         * by only 3.5 m. The AWRL1432 at 77 GHz may transmit at full power,
         * yet its noisier receiver meets S1 by only 2.6 m, and at 168 mW the
         * cell runs out after 14.6 h of day flash, short of S6. The 24 GHz
         * BGT24MTR12 draws 138 mW and sees farthest, by 58 m, but its
         * antennas take five times the area and it needs a DSP MCU of its
         * own: 5 g more, and the unit breaks S8.
         *
         * Only radiated power is capped, so larger receive antennas would win
         * back range at 60 GHz, at the cost of area and mass.
         *
         * Measuring receding targets too would halve the closing speed each
         * chirp period allows, so the chirps would have to be shorter: at
         * most 29 us at 77 GHz and 37 us at 60 GHz, where a 5 MHz IF carries
         * only 111 m and 151 m. 77 GHz would fail S1 and 60 GHz would pass by
         * 11 m.
         *
         * Not weighed here:
         * - Regulation outside Europe, such as the FCC's in the US.
         * - Firmware. The TI chips run TI's SDK in C on their own Cortex-M4F,
         *   and the MCU only reads detections. At 24 GHz the DSP would be
         *   firmware of our own, in Rust.
         * - The BGT24ATR22, the pulsed Doppler chip Magene-class radars
         *   likely use: it cannot sweep 150 MHz FMCW.
         *
         * Later: a study of each band's own best chirps, instead of the
         * shared rules. RearUnitDesign takes the chosen radar by hand. */
        subject : RadarModule = (awrl6432Radar, awrl1432Radar, bgt24Mtr12Radar);
        objective : MinimizeObjective;
        calc :>> evaluationFunction {
            in part radar :>> alternative : RadarModule;
            return :>> result : Real = RadarScore(radar, rearUnit);
        }
        return part :>> selectedAlternative : RadarModule;
    }
}
