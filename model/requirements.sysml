package BikeRadarRequirements {
    doc /* What the rear radar light must do: the rider's needs, and the
         * measurable system requirements derived from them. */

    private import ISQ::*;
    private import SI::*;
    private import RequirementDerivation::*;
    public import BikeRadarContext::*;

    // ---- Stakeholder needs -------------------------------------------------

    requirement def StakeholderNeed {
        doc /* Something the rider needs, in the rider's words. */
        subject unit : RearUnit;
    }

    requirement riderNeeds : StakeholderNeed {
        doc /* What the rider needs from the rear unit. */
        subject :>> unit;
        stakeholder rider : Rider;

        requirement <'N1'> awareness : StakeholderNeed {
            doc /* I know a vehicle is coming from behind before I can hear it. */
        }
        requirement <'N2'> beSeen : StakeholderNeed {
            doc /* Drivers see me, day and night. */
        }
        requirement <'N3'> lastsTheRide : StakeholderNeed {
            doc /* It lasts a long day's ride and recharges overnight. */
        }
        requirement <'N4'> unnoticedOnBike : StakeholderNeed {
            doc /* I don't notice its weight, and it fits my bike. */
        }
        requirement <'N5'> allWeather : StakeholderNeed {
            doc /* It keeps working in rain, cold and heat. */
        }
        requirement <'N6'> legalOnTheRoad : StakeholderNeed {
            doc /* I can use it on the road anywhere in Europe. */
        }
    }

    // ---- System requirements -----------------------------------------------

    requirement def <'SYS'> SystemRequirement {
        doc /* A measurable requirement on the rear unit. */
        subject unit : RearUnit;
    }

    requirement systemSpec : SystemRequirement {
        doc /* The rear unit's system requirements. */

        // Detection
        requirement <'S1'> detectionRange : SystemRequirement {
            doc /* Detect an approaching car at 140 m or more, however the unit
                 * sits on any seatpost it fits. Smaller vehicles, such as
                 * motorbikes, are detected later and have no range requirement
                 * yet. */
            require constraint { unit.detectionRange >= 140 [m] }
        }
        requirement <'S2'> alertLatency : SystemRequirement {
            doc /* Alert the head unit within 0.5 s of first detection. */
            require constraint { unit.alertLatency <= 0.5 [s] }
        }
        requirement <'S3'> trackedVehicles : SystemRequirement {
            doc /* Track at least 8 vehicles at once. */
            require constraint { unit.maxTrackedVehicles >= 8 }
        }
        requirement <'S14'> rangeResolution : SystemRequirement {
            doc /* Tell apart two vehicles 1 m apart in range: a car tailgating
                 * another. */
            require constraint { unit.rangeResolution <= 1 [m] }
        }
        requirement <'S15'> speedResolution : SystemRequirement {
            doc /* Tell apart two vehicles whose closing speeds differ by 2.5 km/h. */
            require constraint { unit.speedResolution <= 2.5 [km/h] }
        }
        requirement <'S12'> closingSpeed : SystemRequirement {
            doc /* Measure closing speeds up to 120 km/h: a car at 120 km/h
                 * behind a rider who has stopped. */
            require constraint { unit.maxClosingSpeed >= 120 [km/h] }
        }

        requirement <'S13'> headUnitProtocols : SystemRequirement {
            doc /* Send alerts to the head unit over the ANT+ Bike Radar profile
                 * and over Bluetooth Low Energy, so that common bike computers
                 * show them. */
        }

        // Visibility
        requirement <'S4'> daylightVisibility : SystemRequirement {
            doc /* The light is visible from 1.5 km in daylight. */
            require constraint { unit.daylightVisibility >= 1.5 [km] }
        }

        // Power
        requirement <'S5'> runtimeNightSolid : SystemRequirement {
            doc /* Run at least 8 h with radar on and the light solid. */
            require constraint { unit.runtimeNightSolid >= 8 [h] }
        }
        requirement <'S6'> runtimeDayFlash : SystemRequirement {
            doc /* Run at least 16 h with radar on and the light flashing. */
            require constraint { unit.runtimeDayFlash >= 16 [h] }
        }
        requirement <'S7'> chargeTime : SystemRequirement {
            doc /* Charge from empty to full in 3.5 h or less over USB-C. Relaxed
                 * from 3 h for a power management chip that charges at 800 mA,
                 * which still recharges overnight. */
            require constraint { unit.chargeTime <= 3.5 [h] }
        }

        // Physical
        requirement <'S8'> totalMass : SystemRequirement {
            doc /* Weigh 75 g or less, mount included. */
            require constraint { unit.mass <= 75 [g] }
        }
        requirement <'S9'> seatpostFit : SystemRequirement {
            doc /* Mount on round seatposts from 25 mm to 35 mm in diameter. */
            require constraint {
                unit.minSeatpostDiameter <= 25 [mm] and
                unit.maxSeatpostDiameter >= 35 [mm]
            }
        }

        // Regulation
        requirement <'S16'> radioEmissions : SystemRequirement {
            doc /* Keep the radar within the European limits for short-range
                 * devices in its band, from ERC/REC 70-03: radiated power, and
                 * transmitter output where the band caps it too. */
            require constraint {
                unit.radarEirp <= unit.radarMaxEirp and
                unit.radarOutputPower <= unit.radarMaxOutputPower
            }
        }

        // Environment
        requirement <'S10'> ingressProtection : SystemRequirement {
            doc /* Rated IP67: dust-tight, and survives immersion to 1 m for 30 min. */
        }
        requirement <'S11'> operatingTemperature : SystemRequirement {
            doc /* Work from -10 °C to 40 °C. */
            require constraint {
                unit.minOperatingTemperature <= -10 ['°C'] and
                unit.maxOperatingTemperature >= 40 ['°C']
            }
        }
    }

    // ---- Derivation --------------------------------------------------------

    #derivation connection {
        end #original ::> riderNeeds.awareness;
        end #derive ::> systemSpec.detectionRange;
        end #derive ::> systemSpec.alertLatency;
        end #derive ::> systemSpec.trackedVehicles;
        end #derive ::> systemSpec.closingSpeed;
        end #derive ::> systemSpec.headUnitProtocols;
        end #derive ::> systemSpec.rangeResolution;
        end #derive ::> systemSpec.speedResolution;
    }
    #derivation connection {
        end #original ::> riderNeeds.beSeen;
        end #derive ::> systemSpec.daylightVisibility;
    }
    #derivation connection {
        end #original ::> riderNeeds.lastsTheRide;
        end #derive ::> systemSpec.runtimeNightSolid;
        end #derive ::> systemSpec.runtimeDayFlash;
        end #derive ::> systemSpec.chargeTime;
    }
    #derivation connection {
        end #original ::> riderNeeds.unnoticedOnBike;
        end #derive ::> systemSpec.totalMass;
        end #derive ::> systemSpec.seatpostFit;
    }
    #derivation connection {
        end #original ::> riderNeeds.allWeather;
        end #derive ::> systemSpec.ingressProtection;
        end #derive ::> systemSpec.operatingTemperature;
    }
    #derivation connection {
        end #original ::> riderNeeds.legalOnTheRoad;
        end #derive ::> systemSpec.radioEmissions;
    }
}
