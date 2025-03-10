----Project Description----



Project objective in brief – Non-contact measurement of heartbeat and respiratory 
activity at close distance using stationary FMCW radar. 

Motivation and importance of the project – Contactless health monitoring is 
convenient and can be used in particularly sensitive cases, especially in people with 
burns, in newborns, or psychiatric patients. When the impact of radio waves on the 
human body is thoroughly studied, health-monitoring radar can be one of the important 
paths for the development of disease-preventive systems and medical care systems.    



Objectives: 

1. Registration of respiratory activity and heart rate by directing a radar beam at the 
human body and visualizing radar signatures of vital signs. 
Proposed solution: In order to record the signal, the radar beam will be directed at the 
chest of a person located several dozen centimeters away from the antenna. For vital 
signs visualization, various processing methods will be used, in particular time
frequency analysis and phase demodulation. MTI or CLEAN processing will be used to 
remove clutter if necessary. Processing algorithms and visualization of results will be 
implemented in MATLAB. 

2. Implementation of algorithms enabling detection of individual respiratory and heart 
cycles and estimation of their frequency of occurrence. 
Proposed solution: Respiration rate can be determined quite easily, because the chest 
displacement signal is sinusoidal. A simple FFT should work for this purpose. Heart rate 
estimation is more difficult because the signal consists of high-frequency oscillations. 
Detection of oscillations related to the heart can be achieved in different ways. One of 
them is to use time-frequency methods to represent the heart oscillations in a 
spectrogram, which has properties that smooth high-frequency oscillations and allows 
them to simulate a sinusoid. Another approach could be Doppler frequency envelope 
analysis or convolution with matched filter model of the heart cycle. The algorithms will 
be developed and tested in MATLAB. The best one will be selected for use in objective 4. 

3. Conducting experiments including: 
− Testing the measurement at different chest-to-antenna distances. This will allow 
to check the distance capabilities of the device. 
− Measurement of vital signs from different sides of the body, in particular from the 
front, from the back side and measurement of the heartbeat when the beam is 
directed at the carotid artery. The experiment will indicate the best measurement 
perspective for specific applications and the possibility of using alternative 
perspectives. 
− Simultaneous measurement of vital signs for several people located in slightly 
different positions relative to the radar. In particular, at different distances from 
the antenna and at similar azimuth, and at different azimuths and the same 
distance from the antenna. The aim of the experiment is to test the distance 
resolution due to the FMCW signal capabilities and the angular resolution due to 
beam steering. 
− Measurement of vital signs in a person wearing clothes of different thickness and 
without clothes. The experiment will allow to assess the influence of such 
obstacles on the measurement, in order to indicate limitations for some 
applications. 
− Measurement during various states of body activity, especially after exercise, in a 
relaxed state and during sleep. Additionally, heart activity will be measured during 
held breathing to obtain a reference signal. The experiment will show how the 
intensity of vital signs affects the signal-to-noise ratio and the ability to detect 
heart and respiratory cycles. 
− Attempt to measure a human running in place/on a treadmill or performing other 
activities such as typing on a laptop or talking. The experiment will show the 
limitations associated with random body movements introducing noise in vital 
signs signatures. 

4. Implementation and testing of a radar system for real-time monitoring of vital signs. 
Proposed Solution: The best algorithm from objective 2 will be selected for continuous 
data processing. Processing will be implemented directly on the Raspberry Pi. If the 
computing power is insufficient, the pre-processed data will be sent to another 
computing platform. The results will be saved to a memory card or displayed in real time. 
To test the system, long-term measurements of breathing rate and heart rate will be 
made and compared with the results of conventional sensors such as a smartwatch or 
pulse oximeter.