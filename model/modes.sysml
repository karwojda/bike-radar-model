package BikeRadarModes {
    doc /* The operating modes of the rear unit, and the events that move it
         * between them. */

    // ---- Events ------------------------------------------------------------

    attribute def PowerToggle {
        doc /* A long press on the button. */
    }
    attribute def NextMode {
        doc /* A short press on the button, or a mode change requested from the head unit. */
    }
    attribute def BatteryEmpty {
        doc /* The cell has reached its cut-off voltage. */
    }

    // ---- Modes -------------------------------------------------------------

    state def OperatingModes {
        doc /* Off, or on in one of three modes. The radar runs in every mode
             * that is on; only the light changes. */

        entry; then off;

        state off {
            doc /* Everything is off except the button and the charger. */
        }

        state on {
            doc /* The radar tracks vehicles and alerts the head unit. Turning on
                 * starts in day flash. */

            entry; then dayFlash;

            state dayFlash {
                doc /* The light flashes for daytime visibility. */
            }
            state nightSolid {
                doc /* The light is on steadily, at lower power. */
            }
            state radarOnly {
                doc /* The light is off, for group rides and lit roads. */
            }

            transition dayFlashToNightSolid first dayFlash accept NextMode then nightSolid;
            transition nightSolidToRadarOnly first nightSolid accept NextMode then radarOnly;
            transition radarOnlyToDayFlash first radarOnly accept NextMode then dayFlash;
        }

        transition turnOn first off accept PowerToggle then on;
        transition turnOff first on accept PowerToggle then off;
        transition shutDown first on accept BatteryEmpty then off;
    }
}
