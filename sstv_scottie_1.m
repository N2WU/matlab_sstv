%SSTV Modulation by Nolan Pearce, 30 Jan 2021

clear all

%Read the image (R x G x B Array)
Image = imread('mozart.png');

%This signal is continuously appended
%Highest frequency is 2300 Hz; Nyquist determines sampling rate of 8 kHz
fs = 8e3;

%% Calibration Header
%Set up the signal (WRASSE SC2-180 Mode)

t_Leader = 0:1/fs:300e-3; %duration for first tone

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
    VIS_code(k,:) = cos(2*pi*(1300-(VIS_binary(k)*200)*t_bit)); %use 1100 for 1, 1300 for 0
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

%% Scottie-1 Encoding

%define time steps
t_separate = (0:1/fs:1.5e-3);
t_sync = (0:1/fs:9e-3);
t_porch = (0:1/fs:1.5e-3);
t_rgb = (0:1/fs:0.4576e-3);

%define reoccuring signals
Sync_pulse = cos(2*pi*1200*t_sync);
Porch = cos(2*pi*1500*t_porch);
Separator = cos(2*pi*1500*t_separate);

%First, restructure image to display correct luminance range
%Range = 2300-1500 Hz = 800 Hz
Img_luminance = double(Image) ./ 255 * 800 + 1500; 

%Now do each scan line
%length of one scan line: 
len = length(t_rgb);
%R_array = zeros(320,len);

%RGB_array = zeros(256,len*320*3);

Scottie_image = zeros(256, len*320*3 + 112);

for n=1:256
    RGB_line = zeros(3,len*320);
    for k=1:3 %in red, green, blue order.
       R_array = zeros(320,len);
       for m=1:320  
        
        R_array(m,:) = cos(2*pi*Img_luminance(n,m,k)*t_rgb); %1 color for the whole line

       end
       R_array = reshape(R_array.', 1, []);
       RGB_line(k,:) = R_array; %red, green, blue for the whole line
    end
%Build this packet
    Scottie_line = [Separator, RGB_line(2,:), Separator, RGB_line(3,:), Sync_pulse, Porch, RGB_line(1,:)];
	Scottie_image(n,:) = Scottie_line;
end

Scottie_image = reshape(Scottie_image.', 1, []);

%% Combine Header and Signal

Scottie_1 = [Calibration_Header, Scottie_image];

soundsc(Scottie_1)