% Peak data processing with tuning curve construction
close all;
clearvars;
set(0, 'DefaultFigureVisible', 'on');
cd('/MATLAB Drive/Attention_Tuning/attention_data_mat');
base_dir = '/MATLAB Drive/Attention_Tuning/attention_data_mat/attention_data_mat';
peak_data_dir = fullfile(base_dir, 'peak_data_collection'); % Folder containing peak data CSV files

% Initialize storage for FULL and POOR peak values
full_peak_storage = [];
poor_peak_storage = [];

% List all peak data files
peak_files = dir(fullfile(peak_data_dir, '*.csv'));

% Directions
directions = [-75 -60 -45 -30 -15 0 15 30 45 60 75 90 105 120 135 150 165 180 195 210 225 240 255 270];
directions = directions';

% Initialize counts for averaging
full_count = 0; % Count of "full" files
poor_count = 0; % Count of "poor" files

% Loop through all peak data files
for i = 1:length(peak_files)
    % Load the file
    file_name = peak_files(i).name;
    file_path = fullfile(peak_files(i).folder, file_name);
    
    % Read the peak data table
    peak_data_table = readtable(file_path);
    peak_values = peak_data_table.PeakValue;
    
    % Classify based on condition
    if contains(file_name, 'full', 'IgnoreCase', true)
        if isempty(full_peak_storage)
            full_peak_storage = zeros(length(peak_values), full_count);
        end
        full_count = full_count + 1;
        full_peak_storage(:, full_count) = peak_values;
        
    elseif contains(file_name, 'poor', 'IgnoreCase', true)
        if isempty(poor_peak_storage)
            poor_peak_storage = zeros(length(peak_values), poor_count);
        end
        poor_count = poor_count + 1;
        poor_peak_storage(:, poor_count) = peak_values;
    end
end

% Compute averages for FULL and POOR conditions
if full_count > 0
    full_peak_values = mean(full_peak_storage(:, 1:full_count), 2, 'omitnan');
else
    full_peak_values = [];
end

if poor_count > 0
    poor_peak_values = mean(poor_peak_storage(:, 1:poor_count), 2, 'omitnan');
else
    poor_peak_values = [];
end

% Gaussian fitting for FULL condition
if ~isempty(full_peak_values)
    % Define sum of two Gaussians
    gaussian_fit = @(params, x) ...
        params(1) * exp(-((x - params(2)).^2) / (2 * params(3)^2)) + ...
        params(4) * exp(-((x - params(5)).^2) / (2 * params(6)^2)) + params(7);
    
    % Initial parameters for fitting
    initial_params = [0.1, 0, 15, 0.05, 180, 15, 0];
    lb = [0, -15, 1, 0, 170, 1, 0]; % Lower bounds
    ub = [Inf, 30, 15, Inf, 190, 10, 0.1]; % Upper bounds
    
    % Fit Gaussian model
    options = optimset('MaxFunEvals', 1000, 'MaxIter', 1000, 'Display', 'off');
    full_fit_params = lsqcurvefit(gaussian_fit, initial_params, directions, full_peak_values, lb, ub, options);
    full_fitted_curve = gaussian_fit(full_fit_params, directions);
else
    full_fit_params = [];
    full_fitted_curve = [];
end

% Gaussian fitting for POOR condition
if ~isempty(poor_peak_values)
    % Fit Gaussian model
    poor_fit_params = lsqcurvefit(gaussian_fit, initial_params, directions, poor_peak_values, lb, ub, options);
    poor_fitted_curve = gaussian_fit(poor_fit_params, directions);
else
    poor_fit_params = [];
    poor_fitted_curve = [];
end

num_subjects = max(full_count, poor_count)/2;

% Plot the tuning curves
figure;
hold on;
if ~isempty(full_fitted_curve)
    plot(directions, full_peak_values, 'ko', 'MarkerFaceColor', 'k', 'DisplayName', 'Full Data');
    plot(directions, full_fitted_curve, 'r-', 'LineWidth', 2, 'DisplayName', 'Full Fitted Curve');
end
if ~isempty(poor_fitted_curve)
    plot(directions, poor_peak_values, 'bo', 'MarkerFaceColor', 'b', 'DisplayName', 'Poor Data');
    plot(directions, poor_fitted_curve, 'c-', 'LineWidth', 2, 'DisplayName', 'Poor Fitted Curve');
end
xlabel('Direction (°)');
ylabel('Response Probability');
ylim([0.01, 0.18]);
title({'Averaged Tuning Curves (N = 15)', 'Full vs Poor Attention'});
legend('show', 'Location', 'Best');
grid on;
hold off;

saveas(gcf, fullfile(base_dir, 'averaged_tuning_curve.png'));  % Saves the plot as a PNG

% Create table to save the data with 3 columns: Directions, Full_Peak_Values, Poor_Peak_Values
averaged_peak_data_fullpoor = table(directions, full_peak_values, poor_peak_values, ...
    'VariableNames', {'Direction', 'Full_Peak_Values', 'Poor_Peak_Values'});

% Save the data to CSV
writetable(averaged_peak_data_fullpoor, fullfile(base_dir, 'averaged_peaks_fullpoor.csv'));


% Extract tuning parameters for FULL condition
if ~isempty(full_fitted_curve)
    A1_full = full_fit_params(1) + full_fit_params(7); % Add baseline
    C1_full = full_fit_params(2);
    sigma1_full = full_fit_params(3);
    A2_full = full_fit_params(4) + full_fit_params(7); % Add baseline
    C2_full = full_fit_params(5);
    sigma2_full = full_fit_params(6);
    baseline_full = full_fit_params(7);
    R2_full = 1 - sum((full_peak_values - full_fitted_curve).^2) / sum((full_peak_values - mean(full_peak_values)).^2);
    [fitted_peak_value, peak_index] = max(full_fitted_curve);
    A1_full = fitted_peak_value;
    second_peak_direction = full_fit_params(5); % C2, center of second Gaussian
    [~, second_peak_index] = min(abs(directions - second_peak_direction)); % Find nearest direction index
    A2_full = full_fitted_curve(second_peak_index); % Extract amplitude at second peak
end

% Extract tuning parameters for POOR condition
if ~isempty(poor_fitted_curve)
    A1_poor = poor_fit_params(1) + poor_fit_params(7); % Add baseline
    C1_poor = poor_fit_params(2);
    sigma1_poor = poor_fit_params(3);
    A2_poor = poor_fit_params(4) + poor_fit_params(7); % Add baseline
    C2_poor = poor_fit_params(5);
    sigma2_poor = poor_fit_params(6);
    baseline_poor = poor_fit_params(7);
    R2_poor = 1 - sum((poor_peak_values - poor_fitted_curve).^2) / sum((poor_peak_values - mean(poor_peak_values)).^2);
    [fitted_peak_value, peak_index] = max(poor_fitted_curve);
    A1_poor = fitted_peak_value;
    second_peak_direction = poor_fit_params(5); % C2, center of second Gaussian
    [~, second_peak_index] = min(abs(directions - second_peak_direction)); % Find nearest direction index
    A2_poor = poor_fitted_curve(second_peak_index); % Extract amplitude at second peak
end

% Create a table to store extracted tuning parameters
tuning_parameters_table = table({'FULL'; 'POOR'}, ...
    [A1_full; A1_poor], [A2_full; A2_poor], [sigma1_full; sigma1_poor], ...
    [baseline_full; baseline_poor], [R2_full; R2_poor], ...
    'VariableNames', {'Condition', 'A1', 'A2', 'Sigma1', 'Baseline', 'R2'});

% Display updated tuning parameters for Full Conditions
disp('Adjusted Tuning Parameters for FULLPOOR Conditions:');
disp(tuning_parameters_table); 
 
% Save the table to a CSV file
output_path = fullfile(base_dir, 'extracted_tuning_parameters.csv');
writetable(tuning_parameters_table, output_path);

disp('Tuning parameters saved to:');
disp(output_path);






% ExpCon vs CwCcw
% Initialize storage for ExpCon and CwCCw peak values
ExpCon_peak_storage = [];
CwCCw_peak_storage = [];

% List all peak data files
peak_files = dir(fullfile(peak_data_dir, '*.csv'));

% Directions
directions = [-75 -60 -45 -30 -15 0 15 30 45 60 75 90 105 120 135 150 165 180 195 210 225 240 255 270];
directions = directions';

% Initialize counts for averaging
ExpCon_count = 0; % Count of "ExpCon" files
CwCCw_count = 0; % Count of "CwCCw" files

% Loop through all peak data files
for i = 1:length(peak_files)
    % Load the file
    file_name = peak_files(i).name;
    file_path = fullfile(peak_files(i).folder, file_name);
    
    % Read the peak data table
    peak_data_table = readtable(file_path);
    peak_values = peak_data_table.PeakValue;
    
    % Classify based on condition
    if contains(file_name, 'Expansion', 'IgnoreCase', true)
        if isempty(ExpCon_peak_storage)
            ExpCon_peak_storage = zeros(length(peak_values), ExpCon_count);
        end
        ExpCon_count = ExpCon_count + 1;
        ExpCon_peak_storage(:, ExpCon_count) = peak_values;
    elseif contains(file_name, 'CCW', 'IgnoreCase', true)
        if isempty(CwCCw_peak_storage)
            CwCCw_peak_storage = zeros(length(peak_values), CwCCw_count);
        end
        CwCCw_count = CwCCw_count + 1;
        CwCCw_peak_storage(:, CwCCw_count) = peak_values;
    else
        warning('File condition not recognized: %s', file_name);
    end
end

% Compute averages for ExpCon and CwCCw conditions
if ExpCon_count > 0
    ExpCon_peak_values = mean(ExpCon_peak_storage(:, 1:ExpCon_count), 2, 'omitnan');
else
    ExpCon_peak_values = [];
end

if CwCCw_count > 0
    CwCCw_peak_values = mean(CwCCw_peak_storage(:, 1:CwCCw_count), 2, 'omitnan');
else
    CwCCw_peak_values = [];
end

% Gaussian fitting for ExpCon condition
if ~isempty(ExpCon_peak_values)
    % Define sum of two Gaussians
    gaussian_fit = @(params, x) ...
        params(1) * exp(-((x - params(2)).^2) / (2 * params(3)^2)) + ...
        params(4) * exp(-((x - params(5)).^2) / (2 * params(6)^2)) + params(7);
    
    % Initial parameters for fitting
    initial_params = [0.1, 0, 15, 0.05, 180, 15, 0];
    lb = [0, -15, 1, 0, 170, 1, 0]; % Lower bounds
    ub = [Inf, 15, 15, Inf, 190, 30, 0.1]; % Upper bounds
    
    % Fit Gaussian model
    options = optimset('MaxFunEvals', 1000, 'MaxIter', 1000, 'Display', 'off');
    ExpCon_fit_params = lsqcurvefit(gaussian_fit, initial_params, directions, ExpCon_peak_values, lb, ub, options);
    ExpCon_fitted_curve = gaussian_fit(ExpCon_fit_params, directions);
else
    ExpCon_fit_params = [];
    ExpCon_fitted_curve = [];
end

% Gaussian fitting for CwCCw condition
if ~isempty(CwCCw_peak_values)
    % Fit Gaussian model
    CwCCw_fit_params = lsqcurvefit(gaussian_fit, initial_params, directions, CwCCw_peak_values, lb, ub, options);
    CwCCw_fitted_curve = gaussian_fit(CwCCw_fit_params, directions);
else
    CwCCw_fit_params = [];
    CwCCw_fitted_curve = [];
end

% Plot the tuning curves
figure;
hold on;
if ~isempty(ExpCon_fitted_curve)
    plot(directions, ExpCon_peak_values, 'ko', 'MarkerFaceColor', 'k', 'DisplayName', 'ExpCon Data');
    plot(directions, ExpCon_fitted_curve, 'r-', 'LineWidth', 2, 'DisplayName', 'ExpCon Fitted Curve');
end
if ~isempty(CwCCw_fitted_curve)
    plot(directions, CwCCw_peak_values, 'bo', 'MarkerFaceColor', 'b', 'DisplayName', 'CwCCw Data');
    plot(directions, CwCCw_fitted_curve, 'c-', 'LineWidth', 2, 'DisplayName', 'CwCCw Fitted Curve');
end
xlabel('Direction (°)');
ylabel('Response Probability');
title({'Averaged Tuning Curves (N = 14)', 'Expansion vs Contraction undifferentiated'});
legend('show', 'Location', 'Best');
grid on;
hold off;

saveas(gcf, fullfile(base_dir, 'averaged_tuning_curve.png'));  % Saves the plot as a PNG

% Create table to save the data with 3 columns: Directions, ExpCon_Peak_Values, CwCCw_Peak_Values
averaged_peak_data_ExpConCwCcw = table(directions, ExpCon_peak_values, CwCCw_peak_values, ...
    'VariableNames', {'Direction', 'ExpCon_Peak_Values', 'CwCCw_Peak_Values'});

% Save the data to CSV
writetable(averaged_peak_data_ExpConCwCcw, fullfile(base_dir, 'averaged_peaks_expconcwccw.csv'));

% Extract tuning parameters for ExpCon condition
if ~isempty(ExpCon_fitted_curve)
    A1_ExpCon = ExpCon_fit_params(1) + ExpCon_fit_params(7); % Add baseline
    C1_ExpCon = ExpCon_fit_params(2);
    sigma1_ExpCon = ExpCon_fit_params(3);
    A2_ExpCon = ExpCon_fit_params(4) + ExpCon_fit_params(7); % Add baseline
    C2_ExpCon = ExpCon_fit_params(5);
    sigma2_ExpCon = ExpCon_fit_params(6);
    baseline_ExpCon = ExpCon_fit_params(7);
    R2_ExpCon = 1 - sum((ExpCon_peak_values - ExpCon_fitted_curve).^2) / sum((ExpCon_peak_values - mean(ExpCon_peak_values)).^2);
    [fitted_peak_value, peak_index] = max(ExpCon_fitted_curve);
    A1_ExpCon = fitted_peak_value;
    second_peak_direction = ExpCon_fit_params(5); % C2, center of second Gaussian
    [~, second_peak_index] = min(abs(directions - second_peak_direction)); % Find nearest direction index
    A2_ExpCon = ExpCon_fitted_curve(second_peak_index); % Extract amplitude at second peak
else
    A1_ExpCon = NaN;
    C1_ExpCon = NaN;
    sigma1_ExpCon = NaN;
    A2_ExpCon = NaN;
    C2_ExpCon = NaN;
    sigma2_ExpCon = NaN;
    baseline_ExpCon = NaN;
    R2_ExpCon = NaN;
end

% Extract tuning parameters for CwCCw condition
if ~isempty(CwCCw_fitted_curve)
    A1_CwCCw = CwCCw_fit_params(1) + CwCCw_fit_params(7); % Add baseline
    C1_CwCCw = CwCCw_fit_params(2);
    sigma1_CwCCw = CwCCw_fit_params(3);
    A2_CwCCw = CwCCw_fit_params(4) + CwCCw_fit_params(7); % Add baseline
    C2_CwCCw = CwCCw_fit_params(5);
    sigma2_CwCCw = CwCCw_fit_params(6);
    baseline_CwCCw = CwCCw_fit_params(7);
    R2_CwCCw = 1 - sum((CwCCw_peak_values - CwCCw_fitted_curve).^2) / sum((CwCCw_peak_values - mean(CwCCw_peak_values)).^2);
    [fitted_peak_value, peak_index] = max(CwCCw_fitted_curve);
    A1_CwCCw = fitted_peak_value;
    second_peak_direction = CwCCw_fit_params(5); % C2, center of second Gaussian
    [~, second_peak_index] = min(abs(directions - second_peak_direction)); % Find nearest direction index
    A2_CwCCw = CwCCw_fitted_curve(second_peak_index); % Extract amplitude at second peak
else
    A1_CwCCw = NaN;
    C1_CwCCw = NaN;
    sigma1_CwCCw = NaN;
    A2_CwCCw = NaN;
    C2_CwCCw = NaN;
    sigma2_CwCCw = NaN;
    baseline_CwCCw = NaN;
    R2_CwCCw = NaN;
end

% Create a table to store extracted tuning parameters for ExpCon and CwCCw conditions
tuning_parameters_table_ExpConCwCCw = table({'ExpCon'; 'CwCCw'}, ...
    [A1_ExpCon; A1_CwCCw], [A2_ExpCon; A2_CwCCw], [sigma1_ExpCon; sigma1_CwCCw], ...
    [baseline_ExpCon; baseline_CwCCw], [R2_ExpCon; R2_CwCCw], ...
    'VariableNames', {'Condition', 'A1', 'A2', 'Sigma1', 'Baseline', 'R2'});

% Display updated tuning parameters for Full Conditions
disp('Adjusted Tuning Parameters for ExPConCwCCw Conditions:');
disp(tuning_parameters_table_ExpConCwCCw);

% Save the table to a CSV file
output_path_ExpConCwCCw = fullfile(base_dir, 'extracted_tuning_parameters_ExpConCwCCw.csv');
writetable(tuning_parameters_table_ExpConCwCCw, output_path_ExpConCwCCw);

disp('Tuning parameters for ExpCon and CwCCw conditions saved to:');
disp(output_path_ExpConCwCCw);





% Initialize storage for full and poor conditions for ExpCon and CwCCw
ExpCon_full_storage = [];
ExpCon_poor_storage = [];
CwCCw_full_storage = [];
CwCCw_poor_storage = [];

% Loop through all peak data files
for i = 1:length(peak_files)
    % Load the file
    file_name = peak_files(i).name;
    file_path = fullfile(peak_files(i).folder, file_name);
    
    % Read the peak data table
    peak_data_table = readtable(file_path);
    peak_values = peak_data_table.PeakValue;

    % Classify based on condition
    if contains(file_name, 'Expansion', 'IgnoreCase', true)
        if contains(file_name, 'full', 'IgnoreCase', true)
            ExpCon_full_storage = [ExpCon_full_storage, peak_values];
        elseif contains(file_name, 'poor', 'IgnoreCase', true)
            ExpCon_poor_storage = [ExpCon_poor_storage, peak_values];
        end
    elseif contains(file_name, 'CCW', 'IgnoreCase', true)
        if contains(file_name, 'full', 'IgnoreCase', true)
            CwCCw_full_storage = [CwCCw_full_storage, peak_values];
        elseif contains(file_name, 'poor', 'IgnoreCase', true)
            CwCCw_poor_storage = [CwCCw_poor_storage, peak_values];
        end
    else
        warning('File condition not recognized: %s', file_name);
    end
end

% Compute averages for full and poor conditions
ExpCon_full_values = mean(ExpCon_full_storage, 2, 'omitnan');
ExpCon_poor_values = mean(ExpCon_poor_storage, 2, 'omitnan');
CwCCw_full_values = mean(CwCCw_full_storage, 2, 'omitnan');
CwCCw_poor_values = mean(CwCCw_poor_storage, 2, 'omitnan');

% Function for Gaussian fitting
gaussian_model = @(params, x) ...
    params(1) * exp(-((x - params(2)).^2) / (2 * params(3)^2)) + ...
    params(4) * exp(-((x - params(5)).^2) / (2 * params(6)^2)) + params(7);

fit_gaussian = @(x, y) lsqcurvefit(gaussian_model, ...
    [0.1, 0, 15, 0.05, 180, 15, 0], x, y, [0, -15, 1, 0, 170, 1, 0], ...
    [Inf, 15, 15, Inf, 190, 30, 0.1], optimset('MaxFunEvals', 1000, 'MaxIter', 1000, 'Display', 'off'));

% Fit Gaussian models
ExpCon_full_fit = fit_gaussian(directions, ExpCon_full_values);
ExpCon_poor_fit = fit_gaussian(directions, ExpCon_poor_values);
CwCCw_full_fit = fit_gaussian(directions, CwCCw_full_values);
CwCCw_poor_fit = fit_gaussian(directions, CwCCw_poor_values);

% Generate fitted curves
ExpCon_full_curve = gaussian_model(ExpCon_full_fit, directions);
ExpCon_poor_curve = gaussian_model(ExpCon_poor_fit, directions);
CwCCw_full_curve = gaussian_model(CwCCw_full_fit, directions);
CwCCw_poor_curve = gaussian_model(CwCCw_poor_fit, directions);

% Plot tuning curves for full and poor conditions
% Plot tuning curves for full conditions
figure;
hold on;
plot(directions, ExpCon_full_values, 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'ExpCon Full');
plot(directions, ExpCon_full_curve, 'r-', 'LineWidth', 2, 'DisplayName', 'ExpCon Full Fit');
plot(directions, CwCCw_full_values, 'bo', 'MarkerFaceColor', 'b', 'DisplayName', 'CwCCw Full');
plot(directions, CwCCw_full_curve, 'c-', 'LineWidth', 2, 'DisplayName', 'CwCCw Full Fit');
title({'Averaged Tuning Curves (N = 14)', 'Exp vs Con at Full Attention'});
xlabel('Direction (°)');
ylabel('Response Probability');
ylim([0.01, 0.18]);
legend('show', 'Location', 'Best');
grid on;
hold off;
saveas(gcf, fullfile(base_dir, 'tuning_curves_full_conditions.png'));

% Plot tuning curves for poor conditions
figure;
hold on;
plot(directions, ExpCon_poor_values, 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'ExpCon Poor');
plot(directions, ExpCon_poor_curve, 'r-', 'LineWidth', 2, 'DisplayName', 'ExpCon Poor Fit');
plot(directions, CwCCw_poor_values, 'bo', 'MarkerFaceColor', 'b', 'DisplayName', 'CwCCw Poor');
plot(directions, CwCCw_poor_curve, 'c-', 'LineWidth', 2, 'DisplayName', 'CwCCw Poor Fit');
title({'Averaged Tuning Curves (N = 14)', 'Exp vs Con at Poor Attention'});
xlabel('Direction (°)');
ylabel('Response Probability');
ylim([0.01, 0.18]);
legend('show', 'Location', 'Best');
grid on;
hold off;
saveas(gcf, fullfile(base_dir, 'tuning_curves_poor_conditions.png'));

% Create and save CSV tables
averaged_peak_data_full = table(directions, ExpCon_full_values, CwCCw_full_values, ...
    'VariableNames', {'Direction', 'ExpCon_Full', 'CwCCw_Full'});
averaged_peak_data_poor = table(directions, ExpCon_poor_values, CwCCw_poor_values, ...
    'VariableNames', {'Direction', 'ExpCon_Poor', 'CwCCw_Poor'});

writetable(averaged_peak_data_full, fullfile(base_dir, 'averaged_peaks_full.csv'));
writetable(averaged_peak_data_poor, fullfile(base_dir, 'averaged_peaks_poor.csv'));

% Extract and adjust tuning parameters for full conditions
[fitted_peak_value_ExpCon_full, peak_index_ExpCon_full] = max(ExpCon_full_curve);
A1_ExpCon_full = fitted_peak_value_ExpCon_full; % Adjusted Amplitude1
second_peak_direction_ExpCon_full = ExpCon_full_fit(5); % Center of second Gaussian
[~, second_peak_index_ExpCon_full] = min(abs(directions - second_peak_direction_ExpCon_full));
A2_ExpCon_full = ExpCon_full_curve(second_peak_index_ExpCon_full); % Adjusted Amplitude2

[fitted_peak_value_CwCCw_full, peak_index_CwCCw_full] = max(CwCCw_full_curve);
A1_CwCCw_full = fitted_peak_value_CwCCw_full; % Adjusted Amplitude1
second_peak_direction_CwCCw_full = CwCCw_full_fit(5); % Center of second Gaussian
[~, second_peak_index_CwCCw_full] = min(abs(directions - second_peak_direction_CwCCw_full));
A2_CwCCw_full = CwCCw_full_curve(second_peak_index_CwCCw_full); % Adjusted Amplitude2

% Extract and adjust tuning parameters for poor conditions
[fitted_peak_value_ExpCon_poor, peak_index_ExpCon_poor] = max(ExpCon_poor_curve);
A1_ExpCon_poor = fitted_peak_value_ExpCon_poor; % Adjusted Amplitude1
second_peak_direction_ExpCon_poor = ExpCon_poor_fit(5); % Center of second Gaussian
[~, second_peak_index_ExpCon_poor] = min(abs(directions - second_peak_direction_ExpCon_poor));
A2_ExpCon_poor = ExpCon_poor_curve(second_peak_index_ExpCon_poor); % Adjusted Amplitude2

[fitted_peak_value_CwCCw_poor, peak_index_CwCCw_poor] = max(CwCCw_poor_curve);
A1_CwCCw_poor = fitted_peak_value_CwCCw_poor; % Adjusted Amplitude1
second_peak_direction_CwCCw_poor = CwCCw_poor_fit(5); % Center of second Gaussian
[~, second_peak_index_CwCCw_poor] = min(abs(directions - second_peak_direction_CwCCw_poor));
A2_CwCCw_poor = CwCCw_poor_curve(second_peak_index_CwCCw_poor); % Adjusted Amplitude2

% Save tuning parameters for Full Conditions with adjusted amplitudes
full_params_table = table({'ExpCon'; 'CwCCw'}, ...
    [A1_ExpCon_full; A1_CwCCw_full], ...
    [ExpCon_full_fit(2); CwCCw_full_fit(2)], ...
    [ExpCon_full_fit(3); CwCCw_full_fit(3)], ...
    [A2_ExpCon_full; A2_CwCCw_full], ...
    [ExpCon_full_fit(5); CwCCw_full_fit(5)], ...
    [ExpCon_full_fit(6); CwCCw_full_fit(6)], ...
    [ExpCon_full_fit(7); CwCCw_full_fit(7)], ...
    'VariableNames', {'Condition', 'Amplitude1', 'Mean1', 'StdDev1', 'Amplitude2', 'Mean2', 'StdDev2', 'Offset'});

% Save tuning parameters for Poor Conditions with adjusted amplitudes
poor_params_table = table({'ExpCon'; 'CwCCw'}, ...
    [A1_ExpCon_poor; A1_CwCCw_poor], ...
    [ExpCon_poor_fit(2); CwCCw_poor_fit(2)], ...
    [ExpCon_poor_fit(3); CwCCw_poor_fit(3)], ...
    [A2_ExpCon_poor; A2_CwCCw_poor], ...
    [ExpCon_poor_fit(5); CwCCw_poor_fit(5)], ...
    [ExpCon_poor_fit(6); CwCCw_poor_fit(6)], ...
    [ExpCon_poor_fit(7); CwCCw_poor_fit(7)], ...
    'VariableNames', {'Condition', 'Amplitude1', 'Mean1', 'StdDev1', 'Amplitude2', 'Mean2', 'StdDev2', 'Offset'});

% Display updated tuning parameters for Full Conditions
disp('Adjusted Tuning Parameters for Full Conditions:');
disp(full_params_table);

% Display updated tuning parameters for Poor Conditions
disp('Adjusted Tuning Parameters for Poor Conditions:');
disp(poor_params_table);

% Save updated tuning parameter tables
writetable(full_params_table, fullfile(base_dir, 'extracted_tuning_parameters_full_adjusted.csv'));
writetable(poor_params_table, fullfile(base_dir, 'extracted_tuning_parameters_poor_adjusted.csv'));