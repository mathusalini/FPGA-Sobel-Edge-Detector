# 🖼️ FPGA Sobel Edge Detector (Verilog | Basys 3)

## 📌 Project Overview

This project implements a **Sobel Edge Detection Algorithm** using **Verilog HDL**.  
The design is divided into two milestones:

- **Milestone 1** – Behavioral implementation and simulation of Sobel filter  
- **Milestone 2** – Hardware implementation on **Basys 3 FPGA (Artix-7)** with VGA output  

The goal is to understand real-time image processing using FPGA and implement a complete edge detection pipeline.

---

## 🎯 Objectives

- Implement Sobel edge detection in behavioral Verilog
- Verify correctness using a high-level reference model (Python/MATLAB)
- Deploy the design on Basys-3 FPGA
- Display processed image using VGA interface

---
## 🧠 Sobel Kernels

### Gx Kernel
```text
-1  0  +1
-2  0  +2
-1  0  +1

###Gy Kernel
-1  -2  -1
 0   0   0
+1  +2  +1

###Gradient Magnitude
G = |Gx| + |Gy|


If `G > Threshold` → Edge  
Else → Background  

---

## 🏗️ System Architecture


    Image Memory (ROM/BRAM)
                │
                ▼
        Sobel Processing Core
                │
                ▼
          VGA Controller
                │
                ▼
           VGA Display



---

# 🚀 Milestone 1 – Behavioral Simulation

### ✔ Description

- Pure behavioral Verilog implementation
- No hardware synthesis required
- Image input converted to memory format
- Compared against Python reference model

### ✔ Tools Used

- Xilinx Vivado Simulator
- ModelSim (optional)
- Python (NumPy, OpenCV)

### ✔ How to Run Simulation

1. Clone repository

2. Open Vivado  
3. Add files from `milestone1/`  
4. Run behavioral simulation  
5. Compare output with Python reference  

---

# 🖥️ Milestone 2 – FPGA Hardware Implementation

### ✔ Description

- Integrated Sobel core with VGA controller  
- Image stored in Block RAM  
- Output displayed in real-time via VGA  

### ✔ Hardware Used

- Basys 3 FPGA (Artix-7)
- 100 MHz onboard clock
- VGA monitor

### ✔ How to Run on FPGA

1. Create new Vivado project (Select Basys-3 board)  
2. Add files from `milestone2/`  
3. Add `basys3.xdc` constraints file  
4. Run synthesis  
5. Generate bitstream  
6. Program FPGA  
7. Connect VGA monitor  

---

## 🖼️ Sample Results
## 🖼️ Sample Results

### 📌 Input Image
![Original Input](PASTE_RAW_LINK_FOR_test_2.jpg)

### 📌 Python Reference Output (Sobel Edges)
![Python Sobel Output](PASTE_RAW_LINK_FOR_edges_output.png)

### 📌 Verilog Output (Sobel Edges)
![Verilog Sobel Output](PASTE_RAW_LINK_FOR_verilog_edges_output.png)

## 📊 Expected Output

- Clear edge detection
- Accurate gradient magnitude computation
- Stable VGA display timing
- Real-time processing behavior

---

## 📚 Key Learning Outcomes

- FPGA-based digital image processing  
- Convolution implementation in hardware  
- VGA timing and signal generation  
- Memory handling using ROM/BRAM  
- Hardware–Software co-verification  
- Threshold-based digital filtering  

---

## 🔬 Technical Highlights

- 3×3 sliding window convolution
- Absolute gradient calculation
- Threshold edge classification
- Modular Verilog architecture
- FPGA real-time deployment

---

## 🔮 Future Improvements

- Real-time camera input (OV7670)
- Pipelined Sobel architecture
- Line buffer optimization
- Canny edge detection implementation
- HDMI output support
- Parameterizable image resolution

---

