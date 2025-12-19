function [dt] = extract_datetime_of_filepath(filepath)
%EXTRACT_DATETIME_OF_FILEPATH Summary of this function goes here
    [~, fname, ~] = fileparts(filepath);
    % extract hour and date
    tokens = regexp(fname, 'phaser_rec_(\d{2}-[A-Za-z]{3}-\d{4}_\d{2}-\d{2}-\d{2})', 'tokens');
    % replace "_" to " "
    dt_str = strrep(tokens{1}{1}, '_', ' ');
    % convert to datetime
    dt = datetime(dt_str, 'InputFormat', 'dd-MMM-yyyy HH-mm-ss');
end

