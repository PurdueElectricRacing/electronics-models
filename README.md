# electronics-models

We used the isoSPI model to catch a bug in our filtering circuit:
![isoSPI](figures/isoSPI_bad_RC.png)

SDC Latch Simulation for open circuit detection:
![SDCLatchCorrect](figures/OpenCircuitFF1.jpg)
SDC Latch when Preset RC Time constant is too small:
![SDCLatchIncorrect](figures/OpenCircuitFF3.jpg)

Thermistor modeling:
![thermistor_plot](figures/thermistor_plot.png)

LV battery sizing:
![per26_lv_loads](figures/per26_lv_loads.png)
- Runtime: 60.95 minute
- Sustained Total Current: 15.79 A
- Endurance factor of safety: 1.91
