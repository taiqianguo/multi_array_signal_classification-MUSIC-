import numpy as np

# Parameters
num_entries = 1024
min_x = -4
max_x = 4
min_sin = -512
max_sin = 511

# Step size
step_size = (max_x - min_x) / (num_entries - 1)

# Generate values
x_values = np.linspace(min_x, max_x, num_entries)
theta_values = 0.5*np.arctan(x_values)
sin_values = np.cos(theta_values)

# Scale sin values to int32 range
scaled_sin_values = np.round(sin_values *512).astype(int)

# Generate COE file content
coe_content = "memory_initialization_radix=10;\nmemory_initialization_vector=\n"
coe_content += ",\n".join(str(value) for value in scaled_sin_values) + ";"

# Print the COE content or write to a file
with open("actan_cos.coe", "w") as file:
    file.write(coe_content)



