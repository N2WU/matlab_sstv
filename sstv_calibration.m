%SSTV Modulation by Nolan Pearce, 30 Jan 2021

clear all

%Read the image (R x G x B Array)
Image = imread('mozart.png');

%This signal is a string message() continuously appended
%Highest frequency is 2300 Hz; Nyquist determines sampling rate of 8 kHz
fs = 8e3;

%% Calibration Header
%Set up the signal (WRASSE SC2-180 Mode)

t_Leader = 0:(1/fs):(300e-3); %duration for first tone

Leader_tone = cos(2*pi*1900*t_Leader);

t_break = 0:1/fs:10e-3;

break_tone = cos(2*pi*1200*t_break);

%Leader tone occurs again here

t_bit = 0:1/fs:30e-3;

VIS_start = cos(2*pi*1200*t_bit);

%Keep t since the rest of the signals are 30ms long.
%Now for VIS Code. WRASSE SC-2 is 55 (decimal).
VIS_decimal = 60;
VIS_binary = de2bi(VIS_decimal,7);
%fit it to the appropriate length

%Flip it for LSB
%VIS_binary = flip(VIS_binary); %it is already lsb

%Start the iterative process
VIS_code = zeros(7,length(t_bit));

for k=1:7
    %VIS_code(k,:) = cos(2*pi*(1300-(VIS_binary(k)*200)*t_bit)); %use 1100 for 1, 1300 for 0
    if VIS_binary == 1
       VIS_code(k,:) =  cos(2*pi*1100*t_bit);
    end
     if VIS_binary == 0
       VIS_code(k,:) =  cos(2*pi*1300*t_bit);
    end
end

VIS_code = reshape(VIS_code.',1,[]);

%Add Parity
parity_bit = cos(2*pi*1300*t_bit);
%VIS Stop bit
VIS_stop = cos(2*pi*1200*t_bit);

%for scottie only, the first bit has a starting pulse
t_start = 0:1/fs:9e-3;
starting_pulse = cos(2*pi*1200*t_start);

%Combine the signal

Calibration_Header = [Leader_tone, break_tone, Leader_tone, VIS_start, VIS_code, parity_bit, VIS_stop, starting_pulse];

%end of sequence

sound(Calibration_Header,fs)