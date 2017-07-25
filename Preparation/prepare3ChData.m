function [X1, X2, X3] = prepare3ChData(filenameLO, filenameSIG)
%PREPARE3CHDATA Returns quadratures of a 3-Channel-Measurement
%
% The quadrature matrices are already cut into piezo segments.
%
%   filenameLO - filename of the LO-data used for correct normalization
%   filenameSIG - filename of the raw 3-Channel-Data

CALIBRATION_CH1 = 4.596047840078126e-05; % Ampere per Volt

%Norm ist the factor in the relation between the quadratures and the ladder
%operators: q = Norm*(a^{+} + a), p = Norm*i*(a^{+} - a)
%typical values are 1/sqrt(2) or 1/2.
Norm = 1/sqrt(2);

dispstat('Load LO data','init','timestamp','keepthis',0);
[data8bitLO,configLO,~]=load8BitBinary(filenameLO,'dontsave');

dispstat('Load Signal data','timestamp','keepthis',0);
[data8bitSIG,configSIG,timestamps]=load8BitBinary(filenameSIG,'dontsave');


for iCh = 1:3
    % Compute number of LO photons
    dispstat(['Computing number of LO photons for Channel ' ...
        num2str(iCh)],'timestamp','keepthis',0);
    XLO = computeQuadratures(data8bitLO(:,:,iCh), configLO, ...
        CALIBRATION_CH1);

    % Calculate the variance piece-wise to compensate slow drifts (e.g.
    % piezos)
    NLO = mean(var(XLO));

    % Compute quadratures for target quantum state
    dispstat(['Computing quadratures for target quantum state ' ...
        'for Channel ' num2str(iCh)],'timestamp','keepthis',0);
    X = computeQuadratures(data8bitSIG(:,:,iCh), configSIG, ...
        CALIBRATION_CH1);

    % Calibration of quadratures to vacuum state
    X = Norm * X / sqrt(NLO);
    
    % Removing Offsets
    dispstat('Removing piecewise offset ...','timestamp','keepthis',0);
    X = bsxfun(@minus, X, mean(X));
    
    % Cut the raw data into segments of equal length according to piezo
    % modulation
    dispstat('Reshaping into piezo segments ...', ...
        'timestamp','keepthis',0);
    X = piezoSegments(timestamps,X,'cut');

    switch iCh
        case 1
            X1 = X;
        case 2
            X2 = X;
        case 3
            X3 = X;
    end
end

end

