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
   or whether fixing the viewer comes first.
4. **Analysis.** Runtime per operating mode, and a battery trade study that
   resolves the mass violation.
5. **Tool Links.** A FreeCAD enclosure and a KiCad board, giving Design
   Values for mass and summed power.

## Status

- [x] Slice 1 written; awaiting review in the viewer.
