% Correlogram Average
clearvars;
close all;
set(0, 'DefaultFigureVisible', 'on');
base_dir = '/MATLAB Drive/Attention_Tuning/attention_data_mat/attention_data_mat';
correlogram_dir = '/MATLAB Drive/Attention_Tuning/attention_data_mat/attention_data_mat/correlogram_collection';
correlogram_files = dir(fullfile(correlogram_dir, '*.csv'));

% Initialize cell arrays to store matrices for 'full' and 'poor' conditions
full_matrices = {};
poor_matrices = {};
time_window = -1000000:50000:300000;

% Loop through each correlogram file
for i = 1:length(correlogram_files)
    file_name = correlogram_files(i).name;
    file_path = fullfile(correlogram_dir, file_name);

    % Read the correlogram matrix
    matrix = readmatrix(file_path);
    
    % Sort the matrix into 'full' or 'poor' based on the filename
    if contains(file_name, 'full', 'IgnoreCase', true)
        full_matrices{end + 1} = matrix;
    elseif contains(file_name, 'poor', 'IgnoreCase', true)
        poor_matrices{end + 1} = matrix;
    end
end

% Function to compute average matrix
average_matrix = @(matrices) mean(cat(3, matrices{:}), 3);

% Compute the average correlogram matrices for each condition
avg_correlogram_full = average_matrix(full_matrices);
avg_correlogram_poor = average_matrix(poor_matrices);

% absolute maximum point in the full correlogram
[~, peak_time_idx] = max(max(avg_correlogram_full, [], 2));  
peak_latency_full = time_window(peak_time_idx) / 1000; % Convert to seconds

% absolute maximum point in the poor correlogram
[~, peak_time_idx] = max(max(avg_correlogram_full, [], 2));  
peak_latency_poor = time_window(peak_time_idx) / 1000; % Convert to seconds

% Plot the average correlogram matrices (adapted from your plotting script)
% Parameters
time_window = -1000000:50000:300000;
directions = [-75 -60 -45 -30 -15 0 15 30 45 60 75 90 105 120 135 150 165 180 195 210 225 240 255 270];
num_directions = length(directions);

% Low-pass filter both average matrices
filtered_avg_full = avg_correlogram_full;
filtered_avg_poor = avg_correlogram_poor;

% Plot Full Condition
figure;
hold on;
colors = lines(num_directions); 
threshold = 0.058;  % Probability threshold
highlighted_time_range = [-900000, -100000];
highlighted_time_idx = find(time_window >= highlighted_time_range(1) & time_window <= highlighted_time_range(2));
highlight_directions = [];
for dir_idx = 1:num_directions
    % Get correlogram values within the highlighted time range for this direction
    values_in_range = filtered_avg_full(highlighted_time_idx, dir_idx);
    
    % Check if any value within the highlighted time range exceeds the threshold
    if any(values_in_range > threshold)
        highlight_directions = [highlight_directions, dir_idx];  % Add direction to highlight list
    end
end
% Plot the full correlogram for the highlighted directions
for idx = 1:length(highlight_directions)
    dir_idx = highlight_directions(idx);
    
    % Plot the full correlogram for this direction
    plot(time_window(1:end-1) / 1000, filtered_avg_full(:, dir_idx), ...
        'Color', colors(idx, :), 'LineWidth', 1, 'DisplayName', [num2str(directions(dir_idx)), '°']);
end 
% Plot the remaining directions in black (without threshold consideration)
remaining_directions = setdiff(1:num_directions, highlight_directions);
for idx = remaining_directions
    plot(time_window(1:end-1) / 1000, filtered_avg_full(:, idx), 'k', 'HandleVisibility', 'off');
end

% Add a vertical line at the maximum correlogram peak (without label)
xline(peak_latency_full, '--r', 'LineWidth', 1, 'HandleVisibility', 'off');

ylim([0, 0.15]);
y_limits = ylim;
line([0, 0], [y_limits(1), y_limits(1) + (y_limits(2) - y_limits(1))/2], ...
    'Color', 'k', 'LineWidth', 3, 'HandleVisibility', 'off');
title('Average Correlogram - Full Condition - Both motion types');
xlabel('Time (ms)');
ylabel('Normalized Probability');
legend('show', 'Location', 'Best');
grid on;
hold off;

saveas(gcf, fullfile(base_dir, 'averaged_correlogram_full.png'));  % Saves the plot as a PNG


% Plot Poor Condition
figure;
hold on;
colors = lines(num_directions); 
threshold = 0.06;  % Probability threshold
highlighted_time_range = [-900000, -100000];
highlighted_time_idx = find(time_window >= highlighted_time_range(1) & time_window <= highlighted_time_range(2));
highlight_directions = [];
for dir_idx = 1:num_directions
    % Get correlogram values within the highlighted time range for this direction
    values_in_range = filtered_avg_poor(highlighted_time_idx, dir_idx);
    
    % Check if any value within the highlighted time range exceeds the threshold
    if any(values_in_range > threshold)
        highlight_directions = [highlight_directions, dir_idx];  % Add direction to highlight list
    end
end
% Plot the poor correlogram for the highlighted directions
for idx = 1:length(highlight_directions)
    dir_idx = highlight_directions(idx);
    
    % Plot the poor correlogram for this direction
    plot(time_window(1:end-1) / 1000, filtered_avg_poor(:, dir_idx), ...
        'Color', colors(idx, :), 'LineWidth', 1, 'DisplayName', [num2str(directions(dir_idx)), '°']);
end 
% Plot the remaining directions in black (without threshold consideration)
remaining_directions = setdiff(1:num_directions, highlight_directions);
for idx = remaining_directions
    plot(time_window(1:end-1) / 1000, filtered_avg_poor(:, idx), 'k', 'HandleVisibility', 'off');
end

% Add a vertical line at the maximum correlogram peak (without label)
xline(peak_latency_poor, '--r', 'LineWidth', 1, 'HandleVisibility', 'off');

ylim([0, 0.15]);
y_limits = ylim;
line([0, 0], [y_limits(1), y_limits(1) + (y_limits(2) - y_limits(1))/2], ...
    'Color', 'k', 'LineWidth', 3, 'HandleVisibility', 'off');
title('Average Correlogram - Poor Condition - Both motion types');
xlabel('Time (ms)');
ylabel('Normalized Probability');
legend('show', 'Location', 'Best');
grid on;
hold off;

saveas(gcf, fullfile(base_dir, 'averaged_correlogram_poor.png')); 



% ExpCon vs CwCcw
% Correlogram Average

ExpCon_matrices = {};
CwCCw_matrices = {};

% Loop through each correlogram file
for i = 1:length(correlogram_files)
    file_name = correlogram_files(i).name;
    file_path = fullfile(correlogram_dir, file_name);

    % Read the correlogram matrix
    matrix = readmatrix(file_path);
    
    % Sort the matrix into 'ExpCon' or 'CwCCw' based on the filename
    if contains(file_name, 'Expansion', 'IgnoreCase', true)
        ExpCon_matrices{end + 1} = matrix;
    elseif contains(file_name, 'CCW', 'IgnoreCase', true)
        CwCCw_matrices{end + 1} = matrix;
    end
end

% Function to compute average matrix
average_matrix = @(matrices) mean(cat(3, matrices{:}), 3);

% Compute the average correlogram matrices for each condition
avg_correlogram_ExpCon = average_matrix(ExpCon_matrices);
avg_correlogram_CwCCw = average_matrix(CwCCw_matrices);

% absolute maximum point in the ExpCon correlogram
[~, peak_time_idx] = max(max(avg_correlogram_ExpCon, [], 2));  
peak_latency_ExpCon = time_window(peak_time_idx) / 1000; % Convert to seconds
% absolute maximum point in the CwCCw correlogram
[~, peak_time_idx] = max(max(avg_correlogram_CwCCw, [], 2));  
peak_latency_CwCCw = time_window(peak_time_idx) / 1000; % Convert to seconds

disp('Average correlogram matrices saved.');

% Plotting parameters
time_window = -1000000:50000:300000;
directions = [-75 -60 -45 -30 -15 0 15 30 45 60 75 90 105 120 135 150 165 180 195 210 225 240 255 270];
num_directions = length(directions);
threshold = 0.058;  % Probability threshold
highlighted_time_range = [-1000000, -100000];

% Plot ExpCon Condition
figure;
hold on;
colors = lines(num_directions); 
highlighted_time_idx = find(time_window >= highlighted_time_range(1) & time_window <= highlighted_time_range(2));
highlight_directions = [];
for dir_idx = 1:num_directions
    values_in_range = avg_correlogram_ExpCon(highlighted_time_idx, dir_idx);
    if any(values_in_range > threshold)
        highlight_directions = [highlight_directions, dir_idx];
    end
end
for idx = 1:length(highlight_directions)
    dir_idx = highlight_directions(idx);
    plot(time_window(1:end-1) / 1000, avg_correlogram_ExpCon(:, dir_idx), ...
        'Color', colors(idx, :), 'LineWidth', 1, 'DisplayName', [num2str(directions(dir_idx)), '°']);
end 
remaining_directions = setdiff(1:num_directions, highlight_directions);
for idx = remaining_directions
    plot(time_window(1:end-1) / 1000, avg_correlogram_ExpCon(:, idx), 'k', 'HandleVisibility', 'off');
end

% Add a vertical line at the maximum correlogram peak (without label)
xline(peak_latency_ExpCon, '--r', 'LineWidth', 1, 'HandleVisibility', 'off');

ylim([0, 0.15]);
y_limits = ylim;
line([0, 0], [y_limits(1), y_limits(1) + (y_limits(2) - y_limits(1))/2], ...
    'Color', 'k', 'LineWidth', 3, 'HandleVisibility', 'off');
title('Average Correlogram - ExpCon Condition');
xlabel('Time (ms)');
ylabel('Normalized Probability');
legend('show', 'Location', 'Best');
grid on;
hold off;
saveas(gcf, fullfile(base_dir, 'averaged_correlogram_ExpCon.png')); 

% Plot CwCCw Condition
figure;
hold on;
highlight_directions = [];
for dir_idx = 1:num_directions
    values_in_range = avg_correlogram_CwCCw(highlighted_time_idx, dir_idx);
    if any(values_in_range > threshold)
        highlight_directions = [highlight_directions, dir_idx];
    end
end
for idx = 1:length(highlight_directions)
    dir_idx = highlight_directions(idx);
    plot(time_window(1:end-1) / 1000, avg_correlogram_CwCCw(:, dir_idx), ...
        'Color', colors(idx, :), 'LineWidth', 1, 'DisplayName', [num2str(directions(dir_idx)), '°']);
end 
remaining_directions = setdiff(1:num_directions, highlight_directions);
for idx = remaining_directions
    plot(time_window(1:end-1) / 1000, avg_correlogram_CwCCw(:, idx), 'k', 'HandleVisibility', 'off');
end
% Add a vertical line at the maximum correlogram peak (without label)
xline(peak_latency_CwCCw, '--r', 'LineWidth', 1, 'HandleVisibility', 'off');
ylim([0, 0.15]);
y_limits = ylim;
line([0, 0], [y_limits(1), y_limits(1) + (y_limits(2) - y_limits(1))/2], ...
    'Color', 'k', 'LineWidth', 3, 'HandleVisibility', 'off');
title('Average Correlogram - CwCCw Condition');
xlabel('Time (ms)');
ylabel('Normalized Probability');
legend('show', 'Location', 'Best');
grid on;
hold off;
saveas(gcf, fullfile(base_dir, 'averaged_correlogram_CwCCw.png'));

