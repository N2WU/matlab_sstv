%SSTV Modulation by Nolan Pearce, 30 Jan 2021

clear all

%Read the image (R x G x B Array)
Image = imread('mozart.png');

%This signal is a string message() continuously appended
%Highest frequency is 2300 Hz; Nyquist determines sampling rate of 8 kHz
fs = 8e3;

%% Calibration Header
%Set up the signal (WRASSE SC2-180 Mode)

t = 0:1/fs:300e-3; %duration for first tone

Leader_tone = cos(2*pi*1900*t);

t = 0:1/fs:10e-3;

break_tone = cos(2*pi*1200*t);

%Leader tone occurs again here

t = 0:1/fs:30e-3;

VIS_start = cos(2*pi*1200*t);

%Keep t since the rest of the signals are 30ms long.
%Now for VIS Code. WRASSE SC-2 is 55 (decimal).
VIS_decimal = 55;
VIS_binary = de2bi(VIS_decimal,7);
%fit it to the appropriate length

%Flip it for LSB
VIS_binary = flip(VIS_binary);

%Start the iterative process
VIS_code = zeros(7,length(t));

for k=1:7
    VIS_code(k,:) = cos(2*pi*(1300-(VIS_binary(k)*200)*t)); %use 1100 for 1, 1300 for 0
end

VIS_code = reshape(VIS_code.',1,[]);

%Add Parity
parity_bit = cos(2*pi*1300*t);
%VIS Stop bit
VIS_stop = cos(2*pi*1200*t);

%Combine the signal

Calibration_Header = [Leader_tone, break_tone, Leader_tone, VIS_start, VIS_code, parity_bit, VIS_stop];

%end of sequence

%% WRASSE Encoding
%Follows a simple sync, porch, red, green, blue scan

%define time steps
t_sync = (0:1/fs:5.5225e-3);
t_porch = (0:1/fs:0.5e-3);
t_rgb = (0:1/fs:0.7344e-3);

%define reoccuring signals
Sync_pulse = cos(2*pi*1200*t_sync);
Porch = cos(2*pi*1500*t_porch);

%First, restructure image to display correct luminance range
%Range = 2300-1500 Hz = 800 Hz
Img_luminance = double(Image) ./ 255 * 800 + 1500; 

%Now do each scan line
%length of one scan line: 
len = length(t_rgb);
%R_array = zeros(320,len);

RGB_array = zeros(256,len*320*3);

for n=1:256
    RGB_line = zeros(3,len*320);
    for k=1:3
        R_array = zeros(320,len);
        for m=1:320  
        
         R_array(m,:) = cos(2*pi*Img_luminance(n,m,k)*t_rgb); %1 color for the whole line

        end
     R_array = reshape(R_array.', 1, []);
     RGB_line(k,1:len*320) = R_array; %red, green, blue for the whole line
    end
    RGB_line = reshape(RGB_line.',1,[]); 
    RGB_array(n,1:len*320*3) = RGB_line;
end

%Build scan line

Scan_line_ex = [Sync_pulse, Porch, RGB_array(1,:)]; %get the length of a typical scan line)
Image_scan = zeros(256,length(Scan_line_ex));

for n=1:256
    Scan_line = [Sync_pulse, Porch, RGB_array(n,:)];
    Image_scan(n,:) = Scan_line;
end
Image_scan = reshape(Image_scan.',1,[]);


%% Combine Header and Signal

WRASSE = [Calibration_Header, Image_scan];

sound(WRASSE,fs)