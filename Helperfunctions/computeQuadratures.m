function [ X ] = computeQuadratures( data8bit, config, amperePerVolt )
%COMPUTEQUADRATURES Compute quadrature values in number of photons
%
% CALIBRATION is given in A/V

INTEGRATION_DUTY_CYCLE = 1/3;
SAMPLERATE = config.SpectrumCard.Clock.SamplingRate0x28MHz0x29_DBL * 10e6;
ELEMENTARY_CHARGE = 1.6021766208e-19;

switch config.SpectrumCard.Channel00.Range_I32
    case 0
        INT8_TO_VOLTAGE = 0.200/128;
    case 1
        INT8_TO_VOLTAGE = 0.500/128;
    case 2
        INT8_TO_VOLTAGE = 1.0/128;
    case 3
        INT8_TO_VOLTAGE = 2.5/128;
end

%% Loop over all channels and compute quadratures
[nRows, nColumns, nChannels] = size(data8bit);

for iCh = 1:nChannels
    % Identify integration centers
    [locs,~] = pointwiseVariance(data8bit(:,:,iCh));

    % Eliminate locations whose corresponding window would be outside the range
    % of DATA (allowed are even windows that go exactly to the edge boundary).
    window = round(INTEGRATION_DUTY_CYCLE * mean(diff(locs)));
    if (locs(1)<=ceil(window/2))
        locs = locs(2:end);
    end
    if ((nRows-locs(end))<ceil(window/2))
        locs = locs(1:length(locs)-1);
    end

    %% Account for small timing errors between channels
    if iCh == 1
        commonLocs = locs;
        X = zeros(length(locs), nColumns, nChannels);
    elseif length(commonLocs) > length(locs)
        if abs(commonLocs(1)-locs(1))>abs(commonLocs(end)-locs(end))
            % First entry in commonLocs needs to be deleted
            X = X(2:end,:,:);
        else
            % Last entry in commonLocs needs to be deleted
            X = X(1:end-1,:,:);
        end
        commonLocs = locs;
    elseif length(commonLocs) < length(locs)
        if abs(commonLocs(1)-locs(1))>abs(commonLocs(end)-locs(end))
            % First entry in locs needs to be deleted
            locs = locs(2:end);
        else
            % Last entry in locs needs to be deleted
            locs = locs(1:end-1);
        end
    end
    
    %% Integration loop
    start = locs-ceil(window/2);
    stop = locs+ceil(window/2);
    windowTime = (stop-start+1) * 1 / SAMPLERATE;

    nWindows = length(locs);
    for iWindow = 1 : nWindows
        % Integration and calibration step
        X(iWindow, :, iCh) = sum(data8bit(start(iWindow):stop(iWindow), ...
            :,iCh))*windowTime(iWindow);
    end % iWindow
    X(:,:,iCh) = X(:,:,iCh) * INT8_TO_VOLTAGE * ...
        amperePerVolt / ELEMENTARY_CHARGE;
end % iCh

end
