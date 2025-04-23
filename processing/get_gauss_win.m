function window = get_gauss_win(width, fs, margin)
    % width = 0.1; % FWHM [s]
    % fs = 500; % sampling frequnecy [Hz]
    % margin = 2; % x times FWHM from each side

    win_len = round((1 + 2*margin)*width*fs); % N samples of window
    width_factor = 1/(1 + 2*margin);
    window = gausswin(win_len,2.354/2/width_factor);
end