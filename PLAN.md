# Plan

This Model exists to dogfood the [SysML v2 Viewer](../sysmlv2_egui): model
a realistic product the way an engineer would, and record every point where
the viewer gets in the way, is wrong, or is missing something.

## The product

A fictional rear radar light for bicycles, with real-world numbers. The
system of interest is the rear unit only; the rider, the bicycle, the
rider's head unit, the approaching vehicle and its driver, and the USB-C
charger are external actors.

## How we work

- Claude writes the SysML; the user opens each slice in the viewer, reacts
  as an engineer would, and decides what counts as friction.
- Diagrams the model keeps are `view`s in `model/views.sysml`; Tool-defined
  Diagrams are for exploring.
- `./scripts/check.sh` runs the viewer's CLI: `export --all` into
  `docs/img`, then OpenSysML's `sysml -validate`, then the viewer's
  `check`. A model one tool accepts and the other rejects is a finding.
- Claude writes SysML following the OpenSysML skills linked under
  `.claude/skills/` (from `../OpenSysML-MDK-Skills`), chiefly
  `opensysml-modeling-best-practices`.
- Findings go to the viewer repo as one file each under
  `.scratch/dogfood-bike-radar/issues/NN-<slug>.md`, `Status: needs-triage`,
  with the slice, the snippet that triggered it, and expected vs. seen.

## Slices

Each slice is reviewed in the viewer before the next starts.

1. **Requirements and system context.** Rider needs (N1–N5), system
   requirements (S1–S11) with measurable values, derivation from needs to
   requirements; the rear unit as a black box with its ports, in a ride
   context and a charge context.
2. **Architecture.** The part tree (radar module, MCU/BLE, LED driver and
   LEDs, battery and charger, USB-C, enclosure and mount), its internal
   interconnection, and the operating modes (off, radar only, day flash,
   night solid) as a `state def`.
3. **Budgets and checks.** Mass and power Model Values, Asserted
   Constraints, Satisfaction Claims. Total mass ≤ 75 g is violated on
   purpose: the battery sized for the runtime requirements is too heavy.
   `./scripts/check.sh` exits 1 from here until slice 4.

   **Stop:** review the findings and decide whether slices 4–5 are worth it,
   or whether fixing the viewer comes first. Among them: a state machine
   Diagram Kind, so `operatingModes` can be drawn (viewer issue 02,
   `ready-for-human`, needs its own spec).
4. **Analysis.** Runtime per operating mode, and a battery trade study that
   resolves the mass violation.
5. **Radar performance.** The radar's parameters as Model Values; detection
   range from the radar equation, range and speed resolution, and the
   fastest closing speed it can measure (new requirement S12, from N1).
   Analyses for a motorbike's detection range and the rider's warning time.
6. **Mounting tilt.** How the tilt of the mounting (seatpost angle, strap
   slip, the rider's weight) shortens the radar's reach, against S1.
7. **Hardware requirements and band trade study.** ANT+ and BLE to the
   head unit (S13, unclaimed until firmware), range and speed resolution
   (S14, S15), S7 relaxed to 3.5 h for an 800 mA charger, and radio
   emissions within Europe's limits for the band (S16, from a new need N6). One radar chip per
   band (24, 60, 77 GHz) with datasheet values and marked assumptions, the
   IF bandwidth limit on range, and a constraint that the regulator covers
   the radar's chirp burst. The study picks the radar.
8. **Electronics bill of materials.** nRF54L15 module (Zephyr/NCS, Rust
   application via zephyr-lang-rust; Embassy rejected for want of ANT),
   nPM1300 for charging, the MCU rail and the fuel gauge, discrete bucks for
   the radar's rails, LED driver, LEDs, button and USB-C, with real values.
   Linux rejected: nothing needs it, and it would eat the runtime.
9. **Bring-up rig.** `BikeRadarBringUp`: a bench rig of dev kits, each
   standing in for a production part.
10. **Tool Links.** A FreeCAD enclosure and a KiCad board, giving Design
   Values for mass and summed power. Deferred: not the time for the tools
   yet.

## Pending Model changes

- When viewer issue 05 lands, change `partTree` to `expose RearUnitDesign::**;`
  for a tree of boxes. `rearUnit`'s parts are Inherited Members, shown as `^`
  rows, not nodes. Until then the view keeps showing the bug.

## Follow-ups

- **Cross-check the radar numbers in NumPy.** A short open FMCW script
  (chirps, beat signal, range-Doppler FFT, SNR) to check the model's range
  resolution (1.0 m), speed resolution (0.86 km/h), IF-limited range (200 m)
  and worst-case range (about 143 m) against the AWRL6432 datasheet's
  "typically up to 25 m", which is likely for people with the EVM's antennas.
  S1 holds by only 3.5 m. See
  [docs/research/simulation-models.md](docs/research/simulation-models.md)
  for the wider tool chain: TI's mmWave Sensing Estimator, openEMS for the
  antenna, and AWRL6432BOOST + DCA1000EVM captures.

## Status

- [x] Slice 1 written; awaiting review in the viewer.
- [x] Slice 2 written; awaiting review in the viewer.
- [x] Slice 3 written; awaiting review in the viewer. **Stop** here.
- [x] Slice 4 written; awaiting review in the viewer. `./scripts/check.sh`
  exits 0 again.
- [x] Slice 5 written; awaiting review in the viewer. S1 narrowed to cars
  (about 187 m) for now; a motorbike is detected at about 125 m, with no
  requirement yet.
- [x] Slice 6 written. A strap mount could tilt the radar 10° and cut the
  car range to about 132 m, short of S1's 140 m (S1 tolerates 9.1°). Now an
  adjustable band clamp with a quarter-turn mount: at most 3.75° of tilt,
  about 178 m, and S1 is judged at that worst case. The clamp is 2 g
  heavier, so the mass margin is down to about 0.8 g.
- [x] Slice 7 written. The band trade study, scored on power first and mass
  second, picks the 60 GHz AWRL6432 at 124 mW. 77 GHz draws 168 mW and
  breaks S6 on the chosen cell (14.1 h, with the slice 8 losses); 24 GHz draws 138 mW but is 5 g heavier and
  breaks S8. The
  57-64 GHz band's 100 mW e.i.r.p. cap (S16) turns its transmitter down to
  6 dBm, so it reaches about 143 m at the worst-case tilt, 3.5 m past S1. The TI chips' 5 MHz IF caps range at
  200 m with 40 us chirps, and one-sided Doppler is assumed. The new
  `regulatorCoversBurst` is violated on purpose (a 0.96 W burst on a 0.5 W
  regulator), so `./scripts/check.sh` exits 1 until slice 8.
- [x] Slice 8 written. Raytac AN54L15Q (nRF54L15) for the MCU; nPM1300 for
  charging at 800 mA (3.1 h, within the relaxed S7), the MCU's 1.8 V rail and
  the fuel gauge; TPS62088 (1.2 V, 3 A) and TPS62840 (1.8 V, 750 mA) for the
  radar's rails, against peaks of 1.1 A and 360 mA; TPS61160A driving three
  LUXEON Rebel reds, three because two would glow from a full cell; C&K KSC
  button; GCT USB4715 socket. Losses now follow from efficiencies. The unit
  weighs about 73.1 g, 1.9 g under S8, and `./scripts/check.sh` exits 0.
- [x] Slice 9 written. `BikeRadarBringUp`: AWRL6432BOOST, nRF54L15-DK (its
  buttons stand in for the unit's), nPM1300-EK with the production cell,
  TPS62088AEVM-187 and TPS62840-1DLCEVM55 (on an electronic load, since the
  radar EVM powers itself) and TPS61160EVM-243 with the three red LEDs. A
  `dependency` ties each kit to the production part it stands in for.
