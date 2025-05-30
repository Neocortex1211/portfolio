clearvars;
close all;
set(0, 'DefaultFigureVisible', 'on');
data_folder = '/MATLAB Drive/Attention_Tuning/attention_data_mat/attention_data_mat/Experiment_Data';
mat_files = dir(fullfile(data_folder, '*.mat'));
peak_folder = fullfile(data_folder, '../peak_data_collection');
corr_folder = fullfile(data_folder, '../correlogram_collection');
hit_folder = fullfile(data_folder, '../hit_rate_collection');
false_folder = fullfile(data_folder, '../false_rate_collection');
lum_folder = fullfile(data_folder, '../luminance_collection');
prime_folder = fullfile(data_folder, '../dprime_collection');
subject_folder = fullfile(data_folder, '../subject_parameters');
accuracy_folder = fullfile(data_folder, '../accuracy_collection');
% Adjust bounds

current_file = mat_files(1).name;
current_file_path = fullfile(data_folder, current_file);
load(current_file_path);
filename = current_file_path; 
file_parts = split(current_file, '_');
name = file_parts{1};
[~, file_name, ~] = fileparts(current_file);
title_correlogram = 'Correlograms for all Directions';
title_tuning = 'Tuning Curve with Sum of two Gaussian Fit';

% Preperation and Cleaning of data
trial_time = data.time(data.event == 'TRIAL_number');
trial_time = trial_time(4:end);
trial_num = data.value(data.event == 'TRIAL_number');
numeric_trial_num = cell2mat(trial_num);
trial_num = numeric_trial_num(numeric_trial_num > 0);
num_trials = 64;
sz = [num_trials 8];
varTypes = ["double", "double", "double", "double", "double", "double", "string", "double"];
varTypes = cellstr(varTypes);
varNames = ["trial_number", "hit_rate", "Z_HitRate", "false_alarm_rate", "Z_FalseAlarmRate", "d_prime", "luminance_response", "accuracy_rate"];
varNames = cellstr(varNames);
temps = table('Size', sz, 'VariableTypes', varTypes, 'VariableNames', varNames);
correct_luminance_counter = 0;
d_prime_values = zeros(1, num_trials);

% Parameters for the Correlogram
time_window = -1000000:50000:300000; 
num_bins = length(time_window) - 1;
directions = [-75 -60 -45 -30 -15 0 15 30 45 60 75 90 105 120 135 150 165 180 195 210 225 240 255 270];
num_directions = length(directions);
correlograms  = zeros(num_bins, num_directions);

% Aggregation of hit and false alarm counts
total_correct_hits = 0;
total_false_alarms = 0;
total_target_amount = 0;
total_non_signal_trials = 0;
overall_hits = 0;
total_presses = 0;
total_correct_rejections = 0;

all_directions = find(data.event == "CTRL_rdp_direction");
all_directions_values = data.value(all_directions);
designated_target = NaN; 

for i = 1:num_trials
    trial_start = trial_time(i);
    trial_end = trial_time(i + 1);
    % Extraction of current trial data
    idx = data.time >= trial_start & data.time < trial_end;
    current_trial_time = data.time(idx);
    current_trial_value = data.value(idx);
    current_trial_event = data.event(idx);
    
    TRIAL_NUM = find(current_trial_event == 'TRIAL_number');
    TRIAL_NUMBER = cell2mat(current_trial_value(TRIAL_NUM));

    if TRIAL_NUMBER == 1 || TRIAL_NUMBER == 33
        designated_indeces = find(current_trial_event == 'CTRL_rdp_target_direction');
        designated_value = current_trial_value(designated_indeces);
        designated_target = cell2mat(designated_value);  
    end

    alpha_valueee = data.value(data.event == 'CTRL_exp_alpha');
    actual_alpha = alpha_valueee{end};

    % Function to determine title label based on alpha value
    switch actual_alpha
        case 0
            sec_title_label = 'Full Attention';
        case 0.4
            sec_title_label = 'Poor Attention';
        otherwise
            sec_title_label = '';
    end
    % Function to determine title label based on designated target
    switch designated_target
        case {0, 180}
            title_label = 'Expansion vs Contraction';
        case {90, 270}
            title_label = 'CW vs CCW';
        otherwise
            title_label = '';
    end
    combined_subtitle = sprintf('%s\n%s', title_label, sec_title_label);

    % Regarding target_response
    target_hits = find(current_trial_event == 'IO_gpTriggerRight');
    target_hit = target_hits(1:2:end);
    target_hit_quantity = length(target_hit);
    target_hit_times = current_trial_time(target_hit);
    target_direction_num = find(current_trial_event == 'Target_Direction_Counter');
    target_direction_num_times = current_trial_time(target_direction_num);

    num_hits_in_trial = length(target_hit);
    overall_hits = overall_hits + num_hits_in_trial;

    correct_target_hits = 0;
    counted_hits = false(size(target_hit_times));      
    for k = 1:length(target_direction_num_times)
        start = target_direction_num_times(k) + 200000;
        limit = target_direction_num_times(k) + 800000;
        frame = data.time > start & data.time < limit;
        timeframe = data.time(frame);
        for j = 1:length(target_hit_times)
            if ~counted_hits(j) && any(timeframe == target_hit_times(j))
                correct_target_hits = correct_target_hits + 1;
                counted_hits(j) = true;  
                break;
            end
        end
    end    
    total_targets = length(target_direction_num);
    proportion_correct = correct_target_hits / total_targets;
    
    % Aggregation of hit and false alarm counts
    total_correct_hits = total_correct_hits + correct_target_hits;
    false_responses = num_hits_in_trial - correct_target_hits;
    total_false_alarms = total_false_alarms + false_responses;
    total_target_amount = total_target_amount + total_targets;
    non_target_directions = 100 - total_targets;
    total_non_signal_trials = total_non_signal_trials + non_target_directions;
    total_presses = total_presses + target_hit_quantity;

    % Accuracy measure
    correct_rejection = non_target_directions - false_responses;
    total_correct_rejections = total_correct_rejections + correct_rejection;
    accuracy_rate = ((correct_target_hits + correct_rejection) / total_targets);

    % Regarding luminance_response
    correct_trials = find(current_trial_event == 'Correct_Luminance_Counter');
    incorrect_trials = find(current_trial_event == 'Incorrect_Luminance_Counter');
    luminance_response = '';
    if ~isempty(correct_trials)
        luminance_responses = 'correct';
    elseif ~isempty(incorrect_trials)
        luminance_responses = 'incorrect';
    else
        luminance_responses = 'unknown';
    end
    if strcmp(luminance_responses, 'correct')
        correct_luminance_counter = correct_luminance_counter + 1;
    end
    
    % Regarding False Alarms
    False_Alarms = false_responses / non_target_directions;
    
    % Handling edge cases for z-scores
    if proportion_correct == 1
        proportion_correct = (total_target_amount - 0.5) / total_target_amount;
    elseif proportion_correct == 0
        proportion_correct = 0.5 / total_target_amount;
    end
    if False_Alarms == 1
        False_Alarms = (total_non_signal_trials - 0.5) / total_non_signal_trials;
    elseif False_Alarms == 0
        False_Alarms = 0.5 / total_non_signal_trials;
    end
    
    % Regarding Z Scores
    convert_Z_HitRate = norminv(proportion_correct);
    convert_Z_FalseAlarm = norminv(False_Alarms);
    d_prime_value = convert_Z_HitRate - convert_Z_FalseAlarm;
    
    % Storage of values in the table
    temps.trial_number(i) = i;
    temps.hit_rate(i) = proportion_correct;
    temps.luminance_response{i} = luminance_responses; 
    temps.false_alarm_rate(i) = False_Alarms;
    temps.Z_HitRate(i) = convert_Z_HitRate;
    temps.Z_FalseAlarmRate(i) = convert_Z_FalseAlarm;
    temps.d_prime(i) = d_prime_value;
    temps.accuracy(i) = accuracy_rate;

    % Initialization for Correlogram
    degree_indeces = find(current_trial_event == 'CTRL_rdp_direction');
    degrees = current_trial_value(degree_indeces);
    degree_times = current_trial_time(degree_indeces);
    if iscell(degrees)
    if all(cellfun(@isnumeric, degrees))
        degrees = cell2mat(degrees);  
    end
    end
    adjusted_degrees = zeros(size(degrees)); % Initialize adjusted degrees array
    for k = 1:length(degrees)
        current_direction = degrees(k);
        % Expansion vs Contraction
        if designated_target == 0
            new_direction = current_direction - 0;
        elseif designated_target == 180
            new_direction = current_direction - 180;
        end
        % CW vs CCW
        if designated_target == 90
            new_direction = current_direction - 90;
        elseif designated_target == 270
            new_direction = current_direction - 270;
        end
        % Correction
        if new_direction > 270
            new_direction = new_direction - 360; 
        elseif new_direction < -75
            new_direction = new_direction + 360; 
        end
        adjusted_degrees(k) = new_direction;
    end

    if strcmp(luminance_responses, 'correct')
    % Construction of correlogram
        for k = 1:length(target_hit_times)
            for j = 1:length(degree_times)
                relative_time = degree_times(j) - target_hit_times(k);
                if relative_time >= time_window(1) && relative_time <= time_window(end)
                    bin_idx = find(time_window <= relative_time, 1, 'last');
                    targeted_direction = adjusted_degrees(j);
                    direction_idx = find(directions == targeted_direction);
                    if ~isempty(direction_idx) && ~isempty(bin_idx)
                        correlograms(bin_idx, direction_idx) = correlograms(bin_idx, direction_idx) + 1;
                    end
                end
            end
        end
    end
end
% Normalization
row_sums = sum(correlograms, 2); % Sum across directions for each time bin
correlograms = correlograms ./ row_sums; % Normalize each row independently
normalized_correlograms = correlograms / total_presses;
  
Fs = 25; % Sampling frequency
filtered_correlograms = lowpass(normalized_correlograms, 4, Fs); % low-pass filter
actually_filtered_corr = filtered_correlograms ./ sum(filtered_correlograms, 2);
valid_corr = zeros(size(actually_filtered_corr));
valid_corr(5:20, :) = actually_filtered_corr(5:20, :); 
% absolute maximum point in the correlogram
[~, peak_time_idx] = max(max(valid_corr, [], 2));  
peak_latency = time_window(peak_time_idx) / 1000; % Convert to seconds

% Plot
figure;
hold on;
colors = lines(num_directions); 
threshold = 0.08;  % Probability threshold
highlighted_time_range = [-900000, -100000];
highlighted_time_idx = find(time_window >= highlighted_time_range(1) & time_window <= highlighted_time_range(2));
highlight_directions = [];

for dir_idx = 1:num_directions
    values_in_range = actually_filtered_corr(highlighted_time_idx, dir_idx);
    if any(values_in_range > threshold)
        highlight_directions = [highlight_directions, dir_idx];  
    end
end

% Plot the full correlogram for the highlighted directions
for idx = 1:length(highlight_directions)
    dir_idx = highlight_directions(idx);
    plot(time_window(1:end-1) / 1000, actually_filtered_corr(:, dir_idx), ...
        'Color', colors(idx, :), 'DisplayName', [num2str(directions(dir_idx)), '°']);
end 

% Plot remaining directions in black
remaining_directions = setdiff(1:num_directions, highlight_directions);
for idx = remaining_directions
    plot(time_window(1:end-1) / 1000, actually_filtered_corr(:, idx), 'k', 'HandleVisibility', 'off');
end

% Add a vertical line at the maximum correlogram peak (without label)
xline(peak_latency, '--r', 'LineWidth', 2, 'HandleVisibility', 'off');

% Existing zero-time vertical line
y_limits = ylim;
line([0, 0], [y_limits(1), y_limits(1) + (y_limits(2) - y_limits(1))/2], ...
    'Color', 'k', 'LineWidth', 2, 'HandleVisibility', 'off');

xlabel('Time (ms)');
ylabel('Normalized Probability');
title(sprintf('%s (%s)\n%s (%s)', title_correlogram, name, title_label, sec_title_label));
legend('show', 'Location', 'Best');
grid on;
hold off;


% peak data for each direction
actually_filtered_corr = filtered_correlograms ./ sum(filtered_correlograms, 2);
csv_filename = fullfile(corr_folder, ['correlogram_', name, title_label, sec_title_label, '.csv']);
writematrix(actually_filtered_corr, csv_filename);
actually_filtered_corr([1:2, 21:26], :) = 0;
% Find peak time index from the overall correlogram
[~, peak_time_idx] = max(max(actually_filtered_corr, [], 2));  
peak_time = time_window(peak_time_idx);  % Get corresponding time point
% Extract the peak values at this specific time slice across all directions
peak_values = actually_filtered_corr(peak_time_idx, :);  
% Create the table with direction, response at peak time, and peak time itself
peak_data = table(directions', peak_values', repmat(peak_time, num_directions, 1), ...
                  'VariableNames', {'Direction', 'PeakValue', 'PeakTime'});
csv_filename = fullfile(peak_folder, ['peak_data_', name, title_label, sec_title_label, '.csv']);
writetable(peak_data, csv_filename);




% Tuning Curve Construction
[~, peak_time_idx] = max(max(actually_filtered_corr, [], 2));
% Extract values at this peak time index across all direction bins
tuning_curve_values = actually_filtered_corr(peak_time_idx, :);
% Defining sum of two Gaussians function with constraints
gaussian_fit = @(params, x) ...
    params(1) * exp(-((x - params(2)).^2) / (2 * params(3)^2)) + ...
    params(4) * exp(-((x - params(5)).^2) / (2 * params(6)^2)) + params(7); 
% Adjust initial parameters for the fitting
% Adjusting centers closer to the new range peak positions
initial_params = [0.1, 0, 20, 0.05, 180, 15, -0.01]; 
% Adjust bounds
lb = [0, -30, 5, 0, 150, 1, -0.01];  % Lower bounds
ub = [0.2, 30, 20, 0.2, 210, 15, 0.1];  % Upper bounds
% Fitting sum of two Gaussians to the data
options = optimset('MaxFunEvals', 1000, 'MaxIter', 1000, 'Display', 'off');
fit_params = lsqcurvefit(gaussian_fit, initial_params, directions, tuning_curve_values, lb, ub, options);
fitted_curve = gaussian_fit(fit_params, directions);
% Extract & display of parameters
A1_gauss = fit_params(1); % Amplitude of first Gaussian
C1 = fit_params(2); % Center of first Gaussian
sigma1 = fit_params(3); % Width of first Gaussian
A2_gauss = fit_params(4); % Amplitude of second Gaussian
C2 = fit_params(5); % Center of second Gaussian
sigma2 = fit_params(6); % Width of second Gaussian
baseline = fit_params(7);  % Baseline parameter from the fit
[fitted_peak_value, peak_index] = max(fitted_curve);
A1 = fitted_peak_value;
second_peak_direction = fit_params(5); % C2, center of second Gaussian
[~, second_peak_index] = min(abs(directions - second_peak_direction)); % nearest direction index
A2 = fitted_curve(second_peak_index); % amplitude at second peak

disp('Tuning Curve Parameters:');
disp(['A1 (amplitude of first Gaussian) = ', num2str(A1)]);
disp(['C1 (center of first Gaussian) = ', num2str(C1)]);
disp(['sigma1 (width of first Gaussian) = ', num2str(sigma1)]);
disp(['A2 (amplitude of second Gaussian) = ', num2str(A2)]);
disp(['C2 (center of second Gaussian) = ', num2str(C2)]);
disp(['sigma2 (width of second Gaussian) = ', num2str(sigma2)]);
disp(['baseline (Baseline of Curve) = ', num2str(baseline)]);

% Compute Residuals and Total Sum of Squares
residuals = tuning_curve_values - fitted_curve; % Difference between observed and fitted values
SS_res = sum(residuals.^2); % Residual Sum of Squares
SS_tot = sum((tuning_curve_values - mean(tuning_curve_values)).^2); % Total Sum of Squares
R2 = 1 - (SS_res / SS_tot);
disp(['Fit Quality (R^2): ', num2str(R2)]);


% Plot of tuning curve
figure;
hold on;
plot(directions, tuning_curve_values, 'ko', 'MarkerFaceColor', 'k', 'DisplayName', 'Data');
plot(directions, fitted_curve, 'r-', 'LineWidth', 2, 'DisplayName', 'Fitted Curve');
xlabel('Direction (°)');
ylabel('Response');
title(sprintf('%s (%s)\n%s (%s)', title_tuning, name, title_label, sec_title_label));
legend('show', 'Location', 'Best');
grid on;
hold off;

% results for each subject
subject_parameters.A1 = A1; 
subject_parameters.sigma1 = sigma1;
subject_parameters.baseline = baseline;
subject_parameters.A2 = A2; 
subject_parameters.target_center_diff = abs(0 - C1); % Difference between target and center
subject_parameters.R2 = R2; % fit quality

% Save subject's parameters 
[~, subject_id, ~] = fileparts(filename);
param_filename = fullfile(subject_folder, ['subject_', subject_id, '_params.mat']);
save(param_filename, 'subject_parameters');

% overall hit rate and false alarm rate
hit_rate = total_correct_hits / total_target_amount;
hit_rate_folder = 'hit_rate_collection';
hit_rate_filename = fullfile(hit_folder, ['subject_', subject_id, '_hit_rate.mat']);
save(hit_rate_filename, 'hit_rate');
false_alarm_rate = total_false_alarms / total_non_signal_trials;
false_rate_folder = 'false_rate_collection';
false_rate_filename = fullfile(false_folder, ['subject_', subject_id, '_false_rate.mat']);
save(false_rate_filename, 'false_alarm_rate');
disp('                          ');
disp('Data Analysis Parameters: ');
disp(['Overall hit_rate: ', num2str(hit_rate)]);
disp(['Overall false_alarm_rate: ', num2str(false_alarm_rate)]);

% overall correct responses
luminance_folder = 'luminance_collection';
proportion_correct_luminance = correct_luminance_counter / num_trials;
proportion_correct_luminance = round(proportion_correct_luminance * 100, 1);
luminance_filename = fullfile(lum_folder, ['subject_', subject_id, '_luminance.mat']);
save(luminance_filename, 'proportion_correct_luminance');
disp(['Proportion of correct luminance responses in total: ', num2str(proportion_correct_luminance), ' %']);

% z-scores
z_hit_rate = norminv(hit_rate);
z_false_alarm_rate = norminv(false_alarm_rate);
disp(['Overall z-score of hit_rate: ', num2str(z_hit_rate)]);
disp(['Overall z-score of false_alarm_rate: ', num2str(z_false_alarm_rate)]);
% d-prime
d_prime = z_hit_rate - z_false_alarm_rate;
disp(['Overall d-prime for the entire experiment: ', num2str(d_prime)]);
dprime_folder = 'dprime_collection';
dprime_filename = fullfile(prime_folder, ['subject_', subject_id, '_dprime.mat']);
save(dprime_filename, 'd_prime');

% Accuracy total
total_accuracy = ((total_correct_hits + total_correct_rejections) / total_target_amount);
disp(['Overall Accuracy for the entire experiment: ', num2str(total_accuracy)]);
accuracy_rate_folder = 'accuracy_collection';
accuracy_filename = fullfile(accuracy_folder, ['subject_', subject_id, '_accuracy.mat']);
save(accuracy_filename, 'total_accuracy');
