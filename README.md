# fp-multiplier

A pipelined IEEE-754 single-precision floating-point multiplier implemented in SystemVerilog.  
Includes normalization, rounding, exception handling, full testbench, and SystemVerilog Assertions (SVA) for formal verification.

---

## 🚀 Overview

This project implements a custom hardware multiplier for IEEE-754 single-precision floating-point numbers.  
The design is pipelined for performance and thoroughly verified through testbenches and assertions.

Developed as part of the **Low-Level Digital HW Systems II** course at **Aristotle University of Thessaloniki**.

---

## 🧠 Key Features

- ✅ 32-bit IEEE-754 compliant floating-point multiplication  
- ⚙️ Pipelined architecture  
- 🧮 Normalization and rounding modules  
- 🛡️ Exception handling for special cases (NaN, Inf, Zero, Denormalized)  
- 📈 Full functional verification via:
  - Randomized testbench
  - Corner-case testbench (144 combinations)
  - SystemVerilog Assertions (SVA)

---

## 🛠️ Technologies Used

- **SystemVerilog**
- **Questa – Intel FPGA Edition**
- Manual RTL simulation and waveform analysis
- IEEE 754 standard (single precision)

---

## 📂 Project Structure
```
├── multiplier/ # Main multiplier modules
│ ├── fp_mult_top.sv
│ ├── fp_mult.sv
│ ├── normalize_mult.sv
│ ├── round_mult.sv
| ├── round_pkg.sv
│ └── exception_mult.sv
│
├── testbenches/ # Functional testbenches
│ ├── testbench.sv
│ └── testbench2.sv
│
├── assertions/ # SystemVerilog Assertions
│ ├── test_status_bits.sv
│ └── test_status_z_combinations.sv
│
├── mult_pkg.sv # Reference multiplication function
└── Report.pdf # Full design and verification report
```

---

## 📊 Results

- All modules passed randomized and corner-case tests.
- Assertions confirmed correctness of status flags and outputs.
- Full waveform validation using Questa simulation tool.

---

## ✍️ Author

**Panos Koutris**  
[pkoutris@ece.auth.gr](mailto:pkoutris@ece.auth.gr)  
Student at AUTh – School of Electrical & Computer Engineering

---

## 📎 License

This project is intended for educational and portfolio use. Contact me before using it commercially or in published work.

