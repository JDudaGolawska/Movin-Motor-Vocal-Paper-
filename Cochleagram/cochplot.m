function cochplot(r, x, fs, fRange)
% Display the image (log intensity) of a cochleagram
% The first variable is required.  
% x: signal
% fRange: frequency range.
% fs: probing frequency
% Written by YP Li, and adapted by DLW in Jan'07, 
% and adapted by JDG in Oct'23

if nargin < 4
    fRange = [80, 5000]; % default frequency range in Hz
end
% if nargin < 4
%     frame_rate = 20; % default frame rate in ms
% end

[numChan, numFrame] = size(r);
time = linspace(0, (length(x)-1)/fs, length(x));
ax1 = subplot(6,1,1);
plot(time, x)

ax2 = subplot(6,1,2:6);
% convert to log or root scale for display purposes if hair cell
% transduction is not used
imagesc(flipud(log(r+1)));
% imagesc(flipud(r.^(1/2)));

% x tick
xtick =linspace(0, numFrame, 10);
x_label = linspace(0, (length(x))/fs, 10);
 

% y tick
y_ntick = 6; % the number of ticks in the frequency axis
cfs = erb2hz(linspace(hz2erb(fRange(1)), hz2erb(fRange(2)), numChan));
ytick = linspace(1, numChan, y_ntick);
y_label = round(cfs(round(ytick)));

% set proper tick labels
set(gca, 'XTick', xtick);
set(gca, 'XTickLabel', x_label);
xlabel('Time (s)');
set(gca, 'YTick', ytick);
set(gca, 'YTickLabel', fliplr(y_label));
ylabel('Center Frequency (Hz)');

% linkaxes([ax1 ax2], 'x')