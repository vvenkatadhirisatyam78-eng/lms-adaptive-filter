# LMS Adaptive Filter — RTL-to-GDSII Implementation & Datapath Optimization

Design and simulation of a Least Mean Squares (LMS) adaptive filter using Verilog HDL, featuring datapath-width optimization (35-bit to 32-bit), cross-platform functional verification (MATLAB & Xilinx Vivado), and full RTL-to-GDSII physical implementation using Synopsys EDA tools.

---

##  Table of Contents
- [Project Overview](#project-overview)
- [Objectives](#objectives)
- [Design Approach](#design-approach)
- [Mathematical Formulation](#mathematical-formulation)
- [Datapath Optimization](#datapath-optimization)
- [Verification Methodology](#verification-methodology)
- [Synopsys RTL-to-GDSII Flow](#synopsys-rtl-to-gdsii-flow)
- [Repository Structure](#repository-structure)
- [Project Status](#project-status)
- [Tools & Technologies](#tools--technologies)
- [Expected Outcome & Scope](#expected-outcome--scope)
- [Author](#author)

---

##  Project Overview

This repository presents the **RTL-to-GDSII implementation and datapath optimization** of an LMS adaptive filter developed as part of **Minor Project 2**. The primary goal is to investigate the hardware impact of reducing datapath bit-width while maintaining equivalent functional and convergence behavior.

Two primary hardware architectures are evaluated:
* **35-bit Datapath:** Conventional reference implementation.
* **32-bit Datapath:** Optimized implementation candidate.

Prior to physical design, the filter was iteratively evaluated across **35-bit, 34-bit, 33-bit, and 32-bit** configurations using **MATLAB** and **Xilinx Vivado**. Because the 32-bit architecture demonstrated equivalent functional behavior to the 35-bit baseline, it was selected for full ASIC synthesis, Place & Route (P&R), and PPA (Power, Performance, and Area) comparison via the **Synopsys RTL-to-GDSII flow**.

---

##  Objectives

* Implement a parameterizable LMS adaptive filter at the Register Transfer Level (RTL) using **Verilog HDL**.
* Establish a baseline reference architecture using a **35-bit datapath**.
* Iteratively evaluate datapath-width reduction across **35-bit, 34-bit, 33-bit, and 32-bit** configurations.
* Verify functional equivalence between high-level algorithmic models (MATLAB) and cycle-accurate RTL simulations (Xilinx Vivado).
* Synthesize and physically implement both the conventional (35-bit) and optimized (32-bit) designs using **Synopsys EDA tools**.
* Quantitatively compare both architectures across **Power, Performance, and Area (PPA)** metrics post-layout.

---

##  Design Approach

The project follows a structured top-down VLSI design and verification methodology:

```text
       LMS Algorithm
             │
             ▼
     MATLAB Reference
             │
             ▼
     Datapath Analysis
      ┌──────┼──────┐
      ▼      ▼      ▼
   35-bit 34-bit 33-bit
      │
      ▼
   32-bit (Selected)
      │
      ▼
  Functional Verification
    (MATLAB + Vivado)
      │
      ▼
    RTL Implementation
    ┌────────┴────────┐
    ▼                 ▼
35-bit              32-bit
Conventional        Optimized
    │                 │
    └────────┬────────┘
             ▼
       Synopsys Flow
             │
             ▼
      Synthesis / P&R
             │
             ▼
           GDSII
             │
             ▼
      PPA Comparison
```

---

##  Mathematical Formulation

The Least Mean Squares (LMS) algorithm iteratively updates filter tap weights to minimize the mean square error between a desired reference signal and the actual filter output.

1. **Filter Output:**
   $$y(n) = \sum_{i=0}^{N-1} w_i(n)x(n-i)$$

2. **Error Estimation:**
   $$e(n) = d(n) - y(n)$$

3. **Coefficient (Weight) Update:**
   $$w_i(n+1) = w_i(n) + \mu e(n)x(n-i)$$

### Parameter Definitions

| Symbol | Description |
| :--- | :--- |
| $x(n)$ | Input signal sample at time $n$ |
| $d(n)$ | Desired reference signal |
| $y(n)$ | Computed filter output |
| $e(n)$ | Estimation error signal |
| $w_i(n)$ | $i^{\text{th}}$ filter tap coefficient |
| $\mu$ | Step-size (learning rate) parameter |
| $N$ | Filter order / tap length |

---

##  Datapath Optimization

To minimize hardware overhead without degrading signal integrity or convergence stability, the internal fixed-point datapath was systematically scaled down:

| Datapath Width | Architectural Role | Functional Observation |
| :--- | :--- | :--- |
| **35-bit** | Conventional Reference | Baseline precision and convergence |
| **34-bit** | Intermediate Evaluation | Negligible deviation from baseline |
| **33-bit** | Intermediate Evaluation | Negligible deviation from baseline |
| **32-bit** | **Optimized Candidate** | **Comparable behavior to 35-bit; selected for ASIC flow** |

> **Note:** Final claims regarding silicon area savings, critical path timing improvements, and power reduction will be published strictly after completing the post-layout Synopsys RTL-to-GDSII sign-off.

---

##  Verification Methodology

### 1. MATLAB (Golden Reference Model)
* Models the fixed-point LMS algorithm behavior.
* Generates stimulus input vectors $x(n)$ and desired signals $d(n)$.
* Computes golden reference outputs $y(n)$ and error convergence curves $e(n)$.
* Exports stimulus vectors as `.mem` / `.txt` initialization files for RTL simulation.

### 2. Xilinx Vivado (RTL Simulation)
* Loads MATLAB-generated memory initialization files directly into the Verilog testbench (`$readmemb` / `$readmemh`).
* Performs cycle-accurate functional simulation across all candidate bit-widths.
* Validates that truncating the datapath from 35 bits to 32 bits introduces no overflow or functional divergence.

---

##  Synopsys RTL-to-GDSII Flow

Both the 35-bit and 32-bit architectures are processed through a complete ASIC backend flow using Synopsys EDA tools:

```text
          RTL (Verilog)
                │
                ▼
         RTL Simulation
                │
                ▼
         Logic Synthesis
                │
                ▼
        Gate-Level Netlist
                │
                ▼
     Design Constraints (SDC)
                │
                ▼
          Floorplanning
                │
                ▼
          Power Planning
                │
                ▼
            Placement
                │
                ▼
     Clock Tree Synthesis (CTS)
                │
                ▼
             Routing
                │
                ▼
      Physical Verification
                │
                ▼
              GDSII
```

### Evaluation Metrics
Post-layout comparisons between the 35-bit and 32-bit designs evaluate:
* **Area:** Total cell area, core utilization, and gate count.
* **Timing:** Critical path delay, setup/hold slack, and maximum operating frequency ($f_{\max}$).
* **Power:** Dynamic (switching/internal) power and static leakage power.

---

##  Repository Structure

```text
lms-adaptive-filter-rtl-to-gdsii/
├── rtl/
│   ├── conventional_35bit/    # Baseline 35-bit Verilog RTL source files
│   └── optimized_32bit/       # Optimized 32-bit Verilog RTL source files
├── testbench/                 # Self-checking Verilog testbenches
├── matlab/                    # Algorithm scripts, error analysis & vector generation
├── mem/                 # Memory initialization files (.mem) for simulation
├── xilinix2/                    # Xilinx Vivado simulation scripts and waveform configs
├── synopsys/
│   ├── synthesis/             # Logic synthesis scripts and constraints
│   ├── floorplan/             # Floorplanning & power grid scripts
│   ├── placement/             # Standard cell placement files
│   ├── cts/                   # Clock Tree Synthesis scripts
│   ├── routing/               # Detailed routing scripts
│   └── reports/               # Timing, area, and power reports
├── results/                   # Comparative PPA tables and post-layout plots
├── docs/                      # Project reports, block diagrams, and documentation
├── .gitignore
└── README.md
```

---

##  Project Status

| Stage | Task | Status |
| :--- | :--- | :--- |
| **Algorithm** | LMS algorithm development & MATLAB verification |  Completed |
| **Test Vectors** | Memory initialization file generation |  Completed |
| **RTL Design** | 35-bit, 34-bit, 33-bit & 32-bit RTL modeling |  Completed |
| **Verification** | Xilinx Vivado functional verification |  Completed |
| **Synthesis & P&R** | 35-bit Synopsys RTL-to-GDSII implementation |   Completed |
| **Synthesis & P&R** | 32-bit Synopsys RTL-to-GDSII implementation |  Completed |
| **Sign-Off** | PPA comparison & final GDSII generation |   Completed |

---

##  Tools & Technologies

* **HDL & Modeling:** Verilog HDL, MATLAB
* **Simulation & Verification:** Xilinx Vivado
* **ASIC Implementation:** Synopsys EDA Tools (Logic Synthesis, Physical Design, Static Timing Analysis, GDSII Generation)
* **Environment:** Linux / Bash Scripting

---

##  Expected Outcome & Scope

### Expected Outcome
This project aims to demonstrate that reducing the LMS datapath from 35 bits to 32 bits preserves algorithmic convergence while yielding measurable hardware efficiency gains. All architectural conclusions will be grounded in post-layout physical implementation data rather than behavioral simulation alone.

### Project Scope
* Fixed-point algorithm modeling and quantization analysis
* Modular Verilog RTL design and testbench development
* Logic synthesis, timing closure, and physical layout (Floorplan to GDSII)
* Comprehensive Power, Performance, and Area (PPA) benchmarking

---

##   Author

**Penubothu Vishnusai**  
*B.Tech — Electronics and Communication Engineering (VLSI Design)*  
*Academic Term: Minor Project 2 (Individual Project)*

**Key Contributions:**
* LMS Algorithm Modeling & Quantization Analysis (MATLAB)
