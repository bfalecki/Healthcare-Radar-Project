function [heart_rate,time] = parse_fit(path)
%PARSE_FIT parse heart_rate and time from .fit file
% Import biblioteki Pythona (fitparse musi być zainstalowany w środowisku Python)
py.importlib.import_module('fitparse');

fitfile = py.fitparse.FitFile(path);

% Pobierz wszystkie rekordy
records_list = py.list(fitfile.get_messages('record'));

time = datetime(); % empty datetime vector
time(1) = [];
heart_rate   = [];
speed = [];

for k = 1:length(records_list)
    rec = records_list{k};
    
    % rec.fields jest listą pól, każde pole ma name i value
    fields = py.list(rec.fields);
    
    % Tymczasowe zmienne
    t_time = [];
    t_hr   = [];
    t_speed= [];
    
    for f = 1:length(fields)
        field = fields{f};
        fname = char(field.name);       % nazwa pola
        
        switch fname
            case 'timestamp'
                t_time = field.value;
            case 'heart_rate'
                t_hr = field.value;
            case 'speed'
                t_speed = field.value;
        end
    end
    
    % Dodaj do tabeli
    if ~isempty(t_time)
        time(end+1)  = t_time;
        heart_rate(end+1)    = t_hr;
        % speed(end+1) = t_speed;
    end
end


end

