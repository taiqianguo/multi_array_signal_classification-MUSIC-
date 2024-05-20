# multi_array_signal_classification-MUSIC
A Verilog demo of the multi-array signal classification algorithm, detecting two sources from four receivers and determining the AoA based on spectrum estimation.

The background is that we have a 4-channel input system, each with distance  d , and we receive two narrowband signals with noise from different positions. By using MUSIC, we want to determine the two sources' AoA.

I tried to use signed integers to implement the algorithm on an FPGA, without floating point, while maintaining precision. This approach has potential for fast, parallel, low-power processing. Considering numerical stability and variable scales, different bit widths were used to represent them, along with normalization and a lookup table to approximate trigonometric functions. I obtained reasonable results, showing this approach is achievable.

The project is based on Vivado 2022.2, utilizing MAC and ROM IPs.

The MUSIC demo's algorithm is illustrated as follows:

1. First, calculate the covariance matrix of the four channels, resulting in a 4*4 matrix.
2. Then, use the Jacobi method to perform eigenvalue decomposition  𝑉Σ𝑉′
3. Compare the eigenvalues to find the two smallest ones and their corresponding eigenvectors.
4. Use the steering vector to get the L2 norm of the steering vector and noise eigenvectors.
5. Use that norm as cross-spectrum estimation to get peak detection and find the two peak angles of AoA.

A more detailed overview of the algorithm can be found in the MATLAB demo. The received MATLAB peak is as follows:

<img width="355" alt="image" src="https://github.com/taiqianguo/multi_array_signal_classification-MUSIC-/assets/58079218/a0ef6592-29ef-4f66-bc9f-f44f00391b12">

### Digital Design Blocks Methods:

1. **Covariance Matrix Calculation**:
   - Use 10 hardware MAC units to compute the 4*4symmetric covariance matrix.

2. **Eigenvalue Decomposition (EVD)**:
   - The CORDIC method is used for EVD. A special approach involves using zeta, the arctan theta, directly mapped to scaled integers: `int8.round(sin*512)` and `int8.round(cos*512)`. A Python script in this project generates the COE file for two single-port ROMs.
   - In theory, zeta ranges from −∞ to ∞, but I truncate it to [-16, 16] corresponding to  [−0.49𝜋,0.49𝜋]. This range is linearly mapped to `address_zeta[0-1024]`, with granularity close to the truncation error.
   - Another important detail is that after each rotation, the values in 𝑉Σ𝑉′ should be normalized. This means 𝑣1=cos⁡(𝜃)⋅𝑉1/512  or 𝑣1=cos(θ)⋅sin(θ)⋅V1/(512^2)..

3. **Steering Vector**:
   - The same lookup table approach is taken for the steering vector.

In the test bench, the four Rx stimuli are generated from MATLAB. Considering the serial and real-time nature of the concatenated blocks, I use non-blocking pipeline control. This means if one block is free and the data from the previous block is ready, it will execute without being blocked. In the FSM, only when the final process has ended will the next iteration of the first block execute.

<img width="531" alt="image" src="https://github.com/taiqianguo/multi_array_signal_classification-MUSIC-/assets/58079218/7cfcda9a-ff22-487f-992f-2bb627186e0b">

### Simulation Results:

There are some errors of the peak persion , but as for now, I have no idea where those harmonic-like secondary peaks come from.

<img width="443" alt="image" src="https://github.com/taiqianguo/multi_array_signal_classification-MUSIC-/assets/58079218/5130c97f-2987-4348-bab5-179044f51544">

<img width="1270" alt="image" src="https://github.com/taiqianguo/multi_array_signal_classification-MUSIC-/assets/58079218/d69ed300-37a9-491c-a3fd-61d737f578f2">

<img width="1239" alt="image" src="https://github.com/taiqianguo/multi_array_signal_classification-MUSIC-/assets/58079218/997f7dbb-bcc9-4867-98dd-6ee79e6603d4">

### Future Development:

For future development, numerical robustness, more test cases, and vector calculators should be considered. Baed on my estimation, the total delay can shrinked up to around 1us with good parallel and spectrum search strategy. And this will be attractive for some interesting applications.
