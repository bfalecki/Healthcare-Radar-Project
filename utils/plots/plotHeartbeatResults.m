function plotHeartbeatResults(results, handles)
    % % 1. Filtered Phase Differentiation
    % set(handles.filteredPhase, 'XData', results.filteredPhase.time, ...
    %                            'YData', results.filteredPhase.data);

    % 2. STFT
    cdata_stft = results.stft.spectrogram;
    cdata_stft = abs(cdata_stft);
    thresh = quantile(nonzeros(cdata_stft),0.2,"all");
    cdata_stft(cdata_stft < thresh) = thresh;
    cdata_stft = db(cdata_stft);
    set(handles.stft, 'XData', results.stft.t, ...
                      'YData', results.stft.f, ...
                      'CData', cdata_stft);

    set(handles.stft.Parent, 'XLim', [min(results.stft.t) max(results.stft.t)], ...
                         'YLim', [0 max(results.stft.f)]);

    % 3. Extracted signal from STFT
    set(handles.extractedSignal.pred, 'XData', results.extractedSignal.t, ...
                                      'YData', results.extractedSignal.predicted);
    set(handles.extractedSignal.avail, 'XData', results.extractedSignal.t, ...
                                       'YData', results.extractedSignal.available);

    % 4. Synchrosqueezed STFT
    cdata_sstft = results.sstft.spectrogram;
    cdata_sstft = abs(cdata_sstft);
    thresh = quantile(nonzeros(cdata_sstft),0.2,"all");
    cdata_sstft(cdata_sstft < thresh) = thresh;
    cdata_sstft = db(cdata_sstft);
    set(handles.sstft.img, 'XData', results.sstft.t, ...
                           'YData', results.sstft.f, ...
                           'CData', cdata_sstft);
    set(handles.sstft.img.Parent, 'XLim', [min(results.sstft.t) max(results.sstft.t)], ...
                              'YLim', [min(results.sstft.f) max(results.sstft.f)]);

    set(handles.sstft.ridge, 'XData', results.sstft.t, ...
                             'YData', results.sstft.ridge);
    set(handles.sstft.img.Parent.Title, 'String', join(['Synchrosqueezed STFT; Heart Rate: ' string(mean(results.sstft.ridge)) ' BPM']))
    

    drawnow limitrate;
end