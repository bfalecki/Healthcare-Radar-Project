classdef VitalSignsSimulator < handle
    %VITALSIGNSSIMULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties


        % VITAL SIGNS PARAMETERS
        %
        % Breath modeled as a sinusoid
        f_breath % breath frequnecy [Hz]
        displ_max_breath % maximum breath-related displacements [m]
        v_max_breath % maximum breath-related velocity [m/s]
        %
        % Heartbeat modeles as a sinusoid with cyclically varying envelope
        f_heart % heart cycles frequency [Hz] 
        f_heart_osc % heartbeat-related oscillation frequency within heart cycle [Hz]
        displ_max_heart % maximum heartbeat-related displacements [m]
        v_max_heart % maximum heartbeat-related velocity [m/s]
        RelativeSystole  % Part of heart cycle from, S1-S2 interval
        S2Amplitude % S2 amplitude, Part of S1 amplitude.

        % RADAR PARAMETERS
        fc  % carrier frequency [Hz]
        PRF  % pulse repetition frequency [Hz]
        SNR  % signal-to-noise ratio [dB]
        t_max  % simulation time
        c = physconst("LightSpeed");
        lambda % wavelength [m]
        max_fd % max unambiguous Doppler frequency [Hz]
        max_vd % max unambiguous Doppler velocity [m/s]

        % output waveforms
        breath_signal_displ
        breath_signal_vel
        heartbeat_signal_displ
        heartbeat_signal_vel
        vital_signs_signal_vel
        vital_signs_signal_displ
        phase_signal
        radar_signal_raw
    end

    properties (Access = public)
        
    end
    
    methods
        function obj = VitalSignsSimulator(varargin)

            p = inputParser;
            addParameter(p, 'BreathFrequency', 0.3); % Breath modeled as a sinusoid with given frequency 'BreathFrequency' [Hz]
            addParameter(p, 'BreathMaxDisplacement', 10e-3); % Maximum displacement of the breath movement [m]
            addParameter(p, 'HeartbeatFrequency', 1.2); % Heart cycles frequency [Hz] 
            addParameter(p, 'HeartbeatOscillationFrequency', 15); % Heartbeat modeles as a sinusoid of frequency 'HeartbeatOscillationFrequency' [Hz] with cyclically varying envelope
            addParameter(p, 'HeartbeatMaxDisplacement', 0.1e-3); % Maximum displacement of the heartbeat movement [m]
            addParameter(p, 'CarrierFrequency', 10e9); % Carrier frequency of the radar [Hz]
            addParameter(p, 'PRF', 100); % Pulse Repetition Frequency of the radar [Hz]
            addParameter(p, 'SNR', 40); % Signal to noise ratio [dB]
            addParameter(p, 'SimulationTime', 10); % Length of the simulated signal [s]
            addParameter(p, 'RelativeSystole', 0.3); % Part of heart cycle from, S1-S2 interval
            addParameter(p, 'S2Amplitude', 0.5); % S2 amplitude, Part of S1 amplitude.
            parse(p, varargin{:});


            %VITALSIGNSSIMULATOR Construct an instance of this class
            %   Detailed explanation goes here
            obj.f_breath = p.Results.BreathFrequency; % breath frequnecy [Hz]
            obj.displ_max_breath = p.Results.BreathMaxDisplacement; % maximum breath-related displacements [m]
            obj.v_max_breath = obj.displ_max_breath*2*pi*obj.f_breath; % maximum breath-related velocity [m/s]
            %
            % Heartbeat modeles as a sinusoid with cyclically varying envelope
            obj.f_heart = p.Results.HeartbeatFrequency; % heart cycles frequency [Hz] 
            obj.f_heart_osc = p.Results.HeartbeatOscillationFrequency; % heartbeat-related oscillation frequency within heart cycle [Hz]
            obj.displ_max_heart = p.Results.HeartbeatMaxDisplacement; % maximum heartbeat-related displacements [m]
            obj.v_max_heart = obj.displ_max_heart * 2*pi * obj.f_heart_osc; % maximum heartbeat-related velocity [m/s]
            obj.RelativeSystole = p.Results.RelativeSystole;
            obj.S2Amplitude = p.Results.S2Amplitude;

            obj.fc = p.Results.CarrierFrequency; % carrier frequency [Hz]
            obj.lambda = obj.c/obj.fc; % wavelength [m]
            
            obj.PRF = p.Results.PRF; % pulse repetition frequency [Hz]
            obj.SNR = p.Results.SNR; % signal-to-noise ratio [dB]
            
            obj.max_fd = obj.PRF/2; % max unambiguous Doppler frequency [Hz]
            obj.max_vd = obj.max_fd/obj.fc * obj.c/2; % max unambiguous Doppler velocity [m/s]
            
            % signal simulation
            obj.t_max = p.Results.SimulationTime; % simulation time

        end
        
        function [radar_signal_raw, t] = simulate(obj)
            % simulate 
            % simulate signal reflected from the human chest
            t = 0:1/obj.PRF:obj.t_max;
            
            obj.breath_signal_displ = obj.displ_max_breath*sin(2*pi*obj.f_breath*t); % displacement signal of breath separated
            obj.breath_signal_vel = obj.v_max_breath*cos(2*pi*obj.f_breath*t); % velocity signal of breath
            
            systole = obj.RelativeSystole * 1/obj.f_heart;
            cycle_width = 0.3*systole; % can be parametrized later
            heartbeat_envelope = obj.displ_max_heart*generate_HR_envelope(obj.f_heart,cycle_width, numel(t), obj.PRF);
            % heartbeat_envelope = obj.displ_max_heart*sin(2*pi*obj.f_heart*t);
            % heartbeat_envelope = heartbeat_envelope.*(heartbeat_envelope > 0); % regarding only positive envelope values
            % displacement signal of heartbeat
            heartbeat_signal_displ_S1 = sin(2*pi*obj.f_heart_osc*t) .* heartbeat_envelope;
            % shifted to the left 
            
            heartbeat_signal_displ_S2 = obj.S2Amplitude * padarray(heartbeat_signal_displ_S1.', round(systole * obj.PRF), "pre").';
            heartbeat_signal_displ_S2 = heartbeat_signal_displ_S2(1:numel(heartbeat_signal_displ_S1));
            % obj.heartbeat_signal_displ = sin(2*pi*obj.f_heart_osc*t) .* heartbeat_envelope;
            obj.heartbeat_signal_displ = heartbeat_signal_displ_S1 + heartbeat_signal_displ_S2;

            % velocity signal of heartbeat
            obj.heartbeat_signal_vel = cos(2*pi*obj.f_heart_osc*t) .* heartbeat_envelope/obj.displ_max_heart*obj.v_max_heart;
            
            % connected signals
            obj.vital_signs_signal_vel = obj.heartbeat_signal_vel + obj.breath_signal_vel;
            obj.vital_signs_signal_displ = obj.heartbeat_signal_displ + obj.breath_signal_displ;
            
            fd_signal = -2*obj.vital_signs_signal_vel/obj.c * obj.fc; % Doppler frequency signal [Hz]
            obj.phase_signal = -4*pi*obj.vital_signs_signal_displ/obj.lambda; % phase of the signal [rad]
            % radar complex signal in baseband (single range cell)
            radar_signal_raw = awgn(exp(1j*obj.phase_signal), obj.SNR);
            obj.radar_signal_raw = radar_signal_raw;
        end
    end
end

