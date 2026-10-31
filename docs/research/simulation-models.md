# Simulation models and open-source radar simulation: research notes

Date: 2026-10-31
Scope: the components chosen for the bike rear radar light (and the rejected radar alternatives), and how the radar's analytical performance figures in `model/analysis.sysml` / `model/architecture.sysml` could be cross-checked.
Method: primary sources only (manufacturer product pages, official tool docs, source repositories). Where only a forum or distributor says something, it is marked **unconfirmed**. Two TI model files were downloaded and inspected, and one was run in ngspice (see Q1 details).

## Summary

**Q1: SPICE models.** Only the two TI buck converters have circuit simulation models. The **TPS62088** and **TPS62840** each have a *PSpice Unencrypted Transient Model* on their TI product pages. These are plain-text PSpice netlists, so they are portable. **TPS61160A** (LED boost) has no simulation model (TI provides only a dimming calculator). The **AWRL6432** and **AWRL1432** have **IBIS and BSDL models only**, which cover digital I/O and boundary scan, not RF or analog behaviour. Nordic publishes **no SPICE or IBIS models** for the **nRF54L15** or the **nPM1300**. It offers tools instead: nPM PowerUP (configuration and battery profiling on an EK) and the Online Power Profiler (current estimates). The Raytac module, the Lumileds LUXEON Rebel Color LED, the C&K KSC switch and the GCT USB4715 have CAD/footprint/3D files only. Lumileds hosts SPICE files only for its LUXEON F family. No simulation model was found for the Infineon BGT24MTR12.

**Q2: open-source radar simulation.** Yes, at every level except a free, open, validated 60 GHz car RCS:
- **Signal level:** a NumPy/SciPy FMCW simulator you write yourself (about 200 lines) is fully open and enough to check range resolution, speed resolution, IF-limited range and SNR. **RadarSimPy** is better featured (mesh targets, ray-traced RCS, CFAR), but only its Python wrapper is GPL-3.0. The C++ engine is a closed binary with a channel/complexity-limited free tier.
- **Antenna:** **openEMS** (GPL-3.0 FDTD, has a patch-antenna tutorial with S11 and far-field) can check the 14 dBi gain and elevation beamwidth.
- **Scene / RCS:** **Sionna RT** (Apache-2.0) has had an RCS/sensing module since v2.2.0, but targets are scattering-point models, not meshes.
- **TI tools (free, not open):** the **mmWave Sensing Estimator** and **mmWave Studio 3G** can cross-check the chirp and range numbers.
- **Measured data:** the **AWRL6432BOOST + DCA1000EVM** gives raw ADC data. The capture software is TI's Windows-only tool. Open-source DCA1000 readers such as OpenRadar are hard-coded for complex-IQ, 4-RX devices and would need adapting for the xWRL6432's real-only, 3-RX data.

**Recommended chain:** (1) a NumPy FMCW script for the three headline numbers, (2) the TI Sensing Estimator as an independent check of the chirp configuration, (3) openEMS for antenna gain and the tilt-loss model, (4) BOOST + DCA1000 corner-reflector and car measurements to validate.

---

## Question 1: simulation models per component

| Part | What exists | Format | Runs in open-source simulator? | Licence / terms | Source |
|---|---|---|---|---|---|
| TI AWRL6432 | IBIS model (SWRM049), BSDL model (SWRM050). No PSpice/TINA | IBIS, BSDL | IBIS: yes, for SI tools (not SPICE behaviour) | TI download terms | https://www.ti.com/product/AWRL6432 |
| TI AWRL6432BOOST | Design files: EVM database (SWRR181), schematic/BOM/assembly (SWRR180), HW/SW checklist (SPRADL1). No simulation models | Altium/PDF zips | n/a | TI download terms | https://www.ti.com/tool/AWRL6432BOOST |
| Nordic nRF54L15 (in Raytac AN54LQ-15, formerly AN54L15Q) | No SPICE/IBIS listed. Reference layouts. Online Power Profiler (BLE current estimate) | Altium zips; web tool | n/a | Nordic | https://www.nordicsemi.com/Products/nRF54L15 , https://www.nordicsemi.com/Products/nRF54L15/Reference-layout , https://devzone.nordicsemi.com/power/w/opp |
| Raytac AN54LQ-15 module | Spec plus footprint and design guide (footprint, 2D/3D drawings, reflow). No models | PDF/CAD | n/a | Raytac | https://www.raytac.com/product/ins.php?index_id=158 |
| Nordic nPM1300 | No SPICE/IBIS listed. nPM PowerUP desktop app (needs nPM1300 EK). Reference layouts | Altium zips; app | n/a | Nordic | https://www.nordicsemi.com/Products/nPM1300/Development-resources?lang=en , https://www.nordicsemi.com/Products/PMIC-software-and-tools/Tools?lang=en |
| TI TPS62088 | **PSpice Unencrypted Transient Model** (SLVMCE6, Rev D), plus variant models. WEBENCH listed | Plain-text PSpice `.LIB` + OrCAD project | **Yes, ngspice tested** (see below) | TI "as is" model disclaimer | https://www.ti.com/product/TPS62088 , https://www.ti.com/lit/zip/SLVMCE6 |
| TI TPS62840 | **PSpice Unencrypted Transient Model** (SLUM691, Rev C), plus TPS62841/2 models. No WEBENCH listing | Plain-text PSpice `.LIB` + OrCAD project | Same dialect as TPS62088; not run here | TI "as is" model disclaimer | https://www.ti.com/product/TPS62840 , https://www.ti.com/lit/zip/SLUM691 |
| TI TPS61160A | **None.** Only the SLVC366 PWM analog-dimming calculator. Same for TPS61160 | Calculator | n/a (behavioural model needed) | — | https://www.ti.com/product/TPS61160A , https://www.ti.com/product/TPS61160 |
| Lumileds LUXEON Rebel Color (LXM2-PD01) | Altium and Eagle library models, DXF footprint. Lumileds' SPICE files cover LUXEON F only | CAD | n/a (fit a diode model to datasheet I–V) | Lumileds | https://lumileds.com/support/design-resources/electrical/ , https://www.lumileds.com/products/color-leds/luxeon-rebel-color/ |
| C&K KSC sealed tact switch | 3D models per part number (some parts marked not yet modelled) | 3D CAD | n/a | C&K | https://www.ckswitches.com/products/switches/product-details/Tactile/KSC2/KSC223GLFG/ |
| GCT USB4715 | Not verified: product page returned HTTP 403 to automated fetch. Expect footprint/3D only (**unconfirmed**) | — | n/a | — | https://gct.co/connector/usb4715 |
| TI AWRL1432 (rejected) | IBIS (SWRM054), BSDL (SWRM052) | IBIS, BSDL | IBIS only | TI | https://www.ti.com/product/AWRL1432 |
| Infineon BGT24MTR12 (rejected) | No simulation model found. Datasheet only. Product page not retrievable (**unconfirmed**) | — | — | — | https://www.infineon.com/dgdl/Infineon-BGT24MTR12-DataSheet-v03_20-EN.pdf?fileId=db3a304339dcf4b10139df108e75025b |

### Details and caveats

**TI model types.** TI lists models under *Design & development → Simulation models* on each product page.
- **AWRL6432:** the page lists only *BSDL Model – AWRL6432 FCCSP* and *IBIS Model – XWRL6432*, and no PSpice or TINA models (https://www.ti.com/product/AWRL6432). IBIS describes I/O buffer behaviour for signal-integrity work (for example, the QSPI or UART lines to the nRF54L15). It says nothing about the radar front end.
- **TPS62088 and TPS62840:** the "Unencrypted" models were downloaded and inspected. `TPS62088_TRANS.LIB` (901 lines, PSpice 16.2) and `TPS62840_TRANS.LIB` (651 lines, PSpice 17.4) are plain text with no encryption markers. They use PSpice-dialect constructs: `PARAMS:` on `.SUBCKT`, `VSWITCH`, `IF()`, `LIMIT()`, `TABLE`, `VALUE=`.
- **What the TPS62088 model covers:** its header lists startup/steady state, current limit and hiccup, pre-bias, line/load transients, enable sequencing and output discharge. Leakage and temperature effects are not modelled.
- **What the TPS62840 model covers:** peak current limit, power-save vs forced-PWM mode, 100 % duty cycle, VSET programmability and the STOP pin. Temperature effects are not modelled, and GND is tied internally to 0 V. (Source for both: the model headers in https://www.ti.com/lit/zip/SLVMCE6 and https://www.ti.com/lit/zip/SLUM691.)

**Encrypted vs portable.** TI's encrypted PSpice models run only in PSpice (for TI). TI's own E2E FAQ says a model encrypted for one simulator cannot be used in another, and that importing into another simulator needs the unencrypted model. That FAQ is on a TI-hosted forum, which blocked automated fetch, so this is **unconfirmed from page text**; the claim comes from the search snippet of https://e2e.ti.com/support/tools/simulation-hardware-system-design-tools-group/sim-hw-system-design/f/simulation-hardware-system-design-tools-forum/692613/faq-tina-spice-note-about-encrypted-models-and-importing-models-from-one-simulator-to-another. For this design it does not matter, because both buck models are the unencrypted variants. The PSpice for TI product page says the tool is free and built on Cadence's PSpice engine and OrCAD Capture. It does not state the encryption policy (https://www.ti.com/tool/PSPICE-FOR-TI).

**Open-source simulators.**
- **ngspice:** its manual §12.11.5 says `set ngbehavior=ps` (or `psa`) translates PSpice syntax, "allow[ing] reading of PSPICE (or TINA) compatible device libraries ... supplied by the semiconductor device manufacturers". The translation includes `VSWITCH`→`aswitch`, E-source `TABLE`→B-source `pwl`, and the `limit/stp/if` functions (https://ngspice.sourceforge.io/docs/ngspice-manual.pdf, version 47+).
- **Xyce:** Sandia's XDM translator (GPL-3.0) converts PSpice netlists to Xyce format (https://github.com/Xyce/XDM).
- **LTspice:** free but closed. It reads many PSpice models, but that was not verified here.

**ngspice test run (this research).** The TPS62088 unencrypted model was run in ngspice 44.2 (Debian package), in batch mode with `set ngbehavior=psa` and the XSPICE code models loaded. Test circuit: 3.7 V in, 0.24 µH, 22 µF, 100 k/100 k divider (internal 0.6 V reference inferred from the netlist), 1.2 Ω load. With the model's `SS=1` parameter (which skips the soft start) and a 0.3 ms transient, the run gave:
- **1.194 V** average output over 0.25–0.3 ms
- **7.7 mV** peak-to-peak ripple
- PG high

So the model parses and simulates correctly in ngspice. It is slow: about 5 min of CPU for 0.3 ms simulated. A full soft-start run (`SS=0`, about 1.25 ms) reached only 0.34 ms in 9 min before the timeout stopped it. One practical note: the PSpice translation turns `VSWITCH` into the XSPICE `aswitch` code model, so `analog.cm` must be loaded (via `spinit` or `.spiceinit`). Without it, ngspice fails with `unable to find definition of model ...a_pwr_g_s1`.

**TI design tools.**
- **PSpice for TI:** free (https://www.ti.com/tool/PSPICE-FOR-TI).
- **TINA-TI:** free DesignSoft simulator made for TI, still offered (release Aug 2024), "fully functional" but lacking some full-TINA features (https://www.ti.com/tool/TINA-TI).
- **WEBENCH Power Designer:** generates a design and runs electrical simulation plus Monte-Carlo/corner analysis (https://www.ti.com/design-resources/design-tools-simulation/webench-power-designer.html). Only the TPS62088 page links to it (https://www.ti.com/product/TPS62088).

**Nordic equivalents.** None is a circuit simulator.
- **nPM PowerUP** is a desktop app in nRF Connect for Desktop. It configures an nPM1300 *on a connected evaluation kit*, runs battery profiling and outputs a device-tree overlay (https://www.nordicsemi.com/Products/PMIC-software-and-tools/Tools?lang=en).
- **Online Power Profiler** estimates BLE current for nRF52/53/54L (https://devzone.nordicsemi.com/power/w/opp).
- Nordic's nPM1300 FAQ mentions only fuel-gauge battery models, not SPICE (https://devzone.nordicsemi.com/nordic/nordic-blog/b/blog/posts/frequently-asked-questions-for-the-npm1300-and-npm1304).
- For a system power simulation, model the nPM1300 bucks as behavioural or averaged blocks using datasheet efficiency curves (https://docs.nordicsemi.com/bundle/ps_npm1300/page/keyfeatures_html5.html).

**Lumileds.** The electrical design-resources library has a SPICE format filter, but the only SPICE files listed are LUXEON F (CoolWhite/Amber) models from 2015. For LUXEON Rebel it lists Altium/Eagle library models and a DXF footprint (https://lumileds.com/support/design-resources/electrical/). A 2008 trade-press item said Rebel SPICE models were once provided. That is not a primary source, and no such file is listed now (**unconfirmed**).

---

## Question 2: simulating radar performance with open-source tools

The SysML figures, re-derived from the parameters in the brief:
- **λ** = c/60.5 GHz = 4.955 mm
- **Range resolution** c/2B = 1.00 m
- **T_active** = 221 × 47 µs = 10.39 ms, so **speed resolution** λ/(2·T_active) = 0.859 km/h
- **IF-limited range** c·f_IF/(2·S) with S = 150 MHz/40 µs ≈ 200 m

The 143 m detection range depends on the radar equation and the tilt-loss model, so it is the number that most needs independent checking.

| Level / tool | What it can do for this case | What it cannot | Open source? | Licence | Source |
|---|---|---|---|---|---|
| Own NumPy/SciPy FMCW script | Chirp, real-IF beat signal, thermal noise (kTBF), range/Doppler FFT, CA-CFAR. Checks all three headline numbers and SNR vs range | No EM, multipath or RCS physics (point target with assumed σ) | Yes | your choice | — |
| RadarSimPy | FMCW/TDM-MIMO baseband simulation, phase noise, receiver noise, point and 3D-mesh targets, ray-traced RCS (`sim_rcs`), range/Doppler processing, CA/OS-CFAR. Has an FMCW link-budget-vs-theory example and a car-RCS example at 76 GHz | Engine (`radarsimcpp`) is a closed binary. Free tier has "limited radar channels" and "limited target complexity". Full features need a paid licence; source access by quote | **Partially**: Python wrapper GPL-3.0, engine closed | GPL-3.0 wrapper + commercial engine | https://github.com/radarsimx/radarsimpy , https://radarsimx.github.io/radarsimpy/user_guide/installation.html , https://radarsimx.com/product/radarsimpy/ , https://radarsimx.com/2024/10/11/fmcw-radar-link-budget-point-target/ , https://radarsimx.com/2021/05/10/car-rcs/ |
| OpenRadar (PreSenseRadar) | DSP for TI mmWave data: range, Doppler, AoA, CFAR, EKF tracking. DCA1000 UDP reader | Not a simulator. DCA1000 reader hard-codes 4 RX / 3 TX complex IQ. Last commit 2020-03-17 | Yes | Apache-2.0 | https://github.com/PreSenseRadar/OpenRadar , https://openradar.readthedocs.io/en/latest/ |
| pyRadar (gaoweifan) | DCA1000 raw ADC capture without mmWave Studio for xWR1843/AWR2243 | No xWRL6432 support | Yes | MIT | https://github.com/gaoweifan/pyRadar |
| PyRadar (PyRadar/pyradar) | SAR image processing (classification, speckle) | Not FMCW. Not relevant | Yes | LGPL-3.0 | https://github.com/PyRadar/pyradar |
| openEMS | FDTD solver with Python/Octave interfaces and near-to-far-field transform. Patch-antenna tutorial gives S11 and far-field pattern. Can verify the 14 dBi gain and elevation beamwidth (feeds the tilt-loss model) | 60 GHz arrays need fine meshes, so runs are slow on a laptop. Not a system simulator | Yes | GPL-3.0 | https://github.com/thliebig/openEMS , https://docs.openems.de/python/openEMS/Tutorials/Simple_Patch_Antenna.html |
| MEEP | General FDTD | Photonics-oriented. openEMS is the more natural choice for PCB antennas | Yes | GPL-2.0 | https://github.com/NanoComp/meep |
| scikit-rf | Touchstone S-parameter handling, de-embedding, plotting (for openEMS output or VNA data) | No field solving | Yes | BSD-3-Clause | https://github.com/scikit-rf/scikit-rf |
| Sionna RT | Differentiable ray tracer. v2.2.0 adds an RCS module ("sensing targets as sets of scattering points", 3GPP TR 38.901 target models) and an `RCSSolver` with Doppler. ITU-R P.2040 materials (metal 1–100 GHz) cover 60.5 GHz | RCS is a scattering-point model, not computed from a car mesh. Diffuse scattering is off by default. GPU-oriented | Yes | Apache-2.0 | https://github.com/NVlabs/sionna-rt , https://github.com/NVlabs/sionna/releases/tag/v2.2.0 , https://nvlabs.github.io/sionna/rt/api/radio_materials.html |
| TI mmWave Sensing Estimator | Web tool listed for AWRL6432 ("configuring TI radar sensors"). Computes chirp parameters, max range, resolutions and a radar-equation detection range ("Min RCS detectable at max range") | Closed formulas. Users on TI E2E report hand calculations not matching its range output (**forum, unconfirmed**). Gallery URL redirected to an error page during this research | No (free) | TI | https://www.ti.com/product/AWRL6432 , https://dev.ti.com/gallery/view/mmwave/mmWaveSensingEstimator/ , https://e2e.ti.com/support/sensors-group/sensors/f/sensors-forum/613078/awr1443-how-is-the-maximum-range-calculated-in-mmwave-sensing-estimator-tool |
| TI mmWave Studio 3G | Windows GUI: low-level chirp configuration, raw ADC capture via DCA1000, basic post-processing, MATLAB examples. Supports AWRL6432/IWRL6432/AWRL1432/IWRL1432 | Windows only. Closed | No ("free and does not require any royalties") | TI | https://www.ti.com/tool/MMWAVE-STUDIO |
| TI MMWAVE-L-SDK / Radar Toolbox | SDK and demos for xWRL6432 (on-chip processing, point cloud). SDK includes ADC-data parsing scripts | Firmware and demos, not a simulator | No (TI licence) | TI | https://www.ti.com/tool/MMWAVE-L-SDK , https://www.ti.com/tool/download/RADAR-TOOLBOX |
| AWRL6432BOOST + DCA1000EVM | Real measured raw ADC data. BOOST "supports direct connectivity to DCA1000EVM". DCA1000 streams over 1 Gbps Ethernet. AWRL6432 raw capture uses its RDIF interface | Configuration and capture go through mmWave Studio 3G (Windows). No open-source xWRL6432 capture path found. BOOST antenna is not the product's 14 dBi patch | Hardware + closed tools; post-processing can be open | TI | https://www.ti.com/tool/AWRL6432BOOST , https://www.ti.com/tool/DCA1000EVM , https://www.ti.com/lit/ds/symlink/awrl6432.pdf |

### Details and caveats

**RadarSimPy licence.** The GitHub repository is GPL-3.0, but building from source "requires to access the source code of `radarsimcpp`", which is available only on request by quote (https://github.com/radarsimx/radarsimpy/blob/master/build_instructions.md). Without a licence file it runs in a free tier with "Limited target complexity" and "Limited radar channels". No numeric limits are published (https://radarsimx.github.io/radarsimpy/user_guide/installation.html). Whether the free tier allows 1 TX × 3 RX and a car mesh is therefore **unconfirmed**. It is fine for point-target link-budget checks. RadarSimPy's own "FMCW Radar Link Budget (Point Target)" example compares simulated SNR with the radar equation using 11 dB NF and a 10 dBsm target, close to this design (https://radarsimx.com/2024/10/11/fmcw-radar-link-budget-point-target/).

**AWRL6432 datasheet vs the SysML numbers.** The datasheet (SWRS295B) lists the following (https://www.ti.com/lit/ds/symlink/awrl6432.pdf):
- 3 RX / 2 TX
- 11 dBm typical output power per TX
- 11 dB NF
- 5 MHz IF bandwidth with real-only RX channels and 12.5 Msps real ADC
- "Range typically up to 25m"

The 25 m "typical" figure presumably refers to TI's target applications (people and in-cabin), not a 10 m² car with 14 dBi external antennas. Even so, a 143 m claim is about 6× the headline figure, which is why measurement is worth doing. The real-only IF also matters for open-source DSP: the receiver sees one-sided Doppler/IF, consistent with the "one-sided Doppler" closing-speed limit in the model. Existing DCA1000 readers (OpenRadar, pyRadar) assume complex IQ and 4 RX (https://github.com/PreSenseRadar/OpenRadar).

**Car RCS at 60 GHz.** No open, validated 60 GHz car-RCS dataset or mesh-RCS tool that is fully open was found. Options:
- **RadarSimPy `sim_rcs`:** ray tracing + physical optics on an STL mesh. Its example is at 76 GHz (https://radarsimx.com/2021/05/10/car-rcs/), and the engine is closed.
- **Sionna RT:** scattering-point targets with user-set RCS (https://github.com/NVlabs/sionna/releases/tag/v2.2.0).

In practice, keep σ = 10 m² as a parameter and sweep it (for example 1–30 m²), rather than trying to simulate it.

---

## Recommendation

**1. Analytical cross-check in open code (about 1 day).**
- Write a self-contained NumPy/SciPy FMCW simulation with the SysML parameters: 60.5 GHz, 150 MHz over 40 µs, 7 µs idle, 221 chirps, 1 TX / 3 RX, real IF sampled at 12.5 Msps, NF 11 dB, TX 6 dBm, 14 dBi antennas, σ = 10 m².
- Inject a point target at known range and closing speed, run the range FFT, Doppler FFT and CA-CFAR, then confirm:
  - 1.0 m range-bin spacing
  - 0.86 km/h Doppler-bin spacing
  - the IF cut-off near 200 m
  - the range at which post-FFT SNR falls to 15 dB (applying the Gaussian elevation-tilt loss used in the model)
- This checks the formulas and the processing gain the radar equation assumes. It does not check the physics inputs (gain, RCS, losses).
- Optionally repeat the point-target case in RadarSimPy's free tier as a second, independently written simulator.

**2. TI tool cross-check (hours).** Enter the same chirp in the mmWave Sensing Estimator ("Advanced chirp design" for xWRL6432) and in mmWave Studio 3G. Confirm that TI accepts the chirp timing, ADC samples, IF bandwidth and frame duty cycle, and compare its max-range and resolution outputs. Treat its detection range as a second opinion only, because its formulas are not published.

**3. Antenna check in openEMS (days).** Model the 14 dBi patch array on the intended substrate. Extract gain and elevation beamwidth, and compare them with the Gaussian tilt-loss assumption that drives the 143 m worst-case-tilt figure. Use scikit-rf for S11 post-processing.

**4. Measurement (about 1–2 weeks, needs hardware).**
- Buy an AWRL6432BOOST and a DCA1000EVM.
- Capture raw ADC data with mmWave Studio 3G (Windows) and process it with your own open DSP from step 1 (adapt a DCA1000 reader for real-only, 3-RX data).
- Measure a calibrated corner reflector at several ranges to fit the system constant, then measure a real car.
- Scale the result to the product antenna gain and EIRP back-off.

This step is the only one that validates the detection range. The BOOST's antenna differs from the product's, so the comparison is "model with BOOST parameters vs BOOST measurement".

**5. Power side (optional).** Run the TPS62088 and TPS62840 unencrypted PSpice models in ngspice (`set ngbehavior=psa`, XSPICE code models loaded) for startup and load-step checks of the 1.2 V and 1.8 V radar rails. The TPS61160A and the nPM1300 need behavioural models built from their datasheets.
