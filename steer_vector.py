import numpy as np

# Define the angle range from 0 to 180 degrees with increments of 1 degree
angles_deg = np.linspace(0, 180, 181)
angles_rad = np.deg2rad(angles_deg)  # Convert degrees to radians

# Number of sensors
N = 4

# Steering vector calculation for each angle
steering_vectors = np.array([
    [np.exp(-1j * np.pi * k * np.sin(theta)) for k in range(N)] 
    for theta in angles_rad
])

# Extract real and imaginary parts
real_parts = np.real(steering_vectors)
imag_parts = np.imag(steering_vectors)

# Define scaling factor
scale_factor = 127

# Scaling and quantizing the real and imaginary parts
real_scaled = np.round((real_parts + 1) * scale_factor).astype(int)
imag_scaled = np.round((imag_parts + 1) * scale_factor).astype(int)

# Clip to ensure no overflow (0 to 254 range)
real_scaled = np.clip(real_scaled, 0, 254)
imag_scaled = np.clip(imag_scaled, 0, 254)

# Helper function to generate COE file content
def generate_coe_content(data):
    header = "memory_initialization_radix=2;\nmemory_initialization_vector=\n"
    body = ",\n".join(",".join(format(x, '08b') for x in row) for row in data) + ";"
    return header + body

# Generate COE content for both real and imaginary parts
real_coe_content = generate_coe_content(real_scaled)
imag_coe_content = generate_coe_content(imag_scaled)

#File paths for the COE files
real_coe_file_path = "Real_Steering_Vectors.coe"
imag_coe_file_path = "Imaginary_Steering_Vectors.coe"

# Write the COE content to files
with open(real_coe_file_path, "w") as file:
    file.write(real_coe_content)

with open(imag_coe_file_path, "w") as file:
    file.write(imag_coe_content)


