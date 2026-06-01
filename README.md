# PER Electrical Modeling

## Directory Structure
- `battery/`: Battery sizing and performance
- `circuits/`: Models of complete circuits
- `components/`: Data-driven or physics-based models of individual components/sensors
- `datasets/`: Raw data from bench testing and datasheets in xlsx/csv format
- `figures/`: Plots and images generated from the models
- `signals/`: Filtering and signal generation simulations

## Results
We used the isoSPI model to catch a bug in our filtering circuit:
![isoSPI](figures/isoSPI_bad_RC.png)

LV battery sizing:
![per26_lv_loads](figures/per26_lv_loads.png)
Runtime: 53.70 minute
Sustained Total Power: 451.60 W
Endurance factor of safety: 1.68

SDC Latch Simulation for open circuit detection:
![SDCLatchCorrect](figures/OpenCircuitFF1.jpg)
SDC Latch when Preset RC Time constant is too small:
![SDCLatchIncorrect](figures/OpenCircuitFF3.jpg)

Thermistor modeling:
![thermistor_plot](figures/B57861S0103_thermistor.png)

Oil temp sensor analysis:
![oil temp error](figures/oil_temp_error.png)