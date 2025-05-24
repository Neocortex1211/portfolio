clearvars;
base_dir = '/MATLAB Drive/Attention_Tuning/attention_data_mat/attention_data_mat';
% Define folder names corresponding to the parameters
parameter_folders = {'hit_rate_collection', 'false_rate_collection', 'dprime_collection', ...
                     'luminance_collection', 'accuracy_collection'};
% Define the parameters of interest
parameters = {'hit_rate', 'false_alarm_rate', 'd_prime', 'luminance', 'accuracy'};
% Initialize results structure
results = struct();
% Loop through each parameter
for p = 1:length(parameters)
    param_name = parameters{p};
    param_folder = fullfile(base_dir, parameter_folders{p});
    
    % Get list of all mat files in the parameter folder
    mat_files = dir(fullfile(param_folder, '*.mat'));
    
    % Initialize storage for full and poor condition values
    full_values = [];
    poor_values = [];
    
    % Loop through each file
    for f = 1:length(mat_files)
        file_name = mat_files(f).name;
        file_path = fullfile(param_folder, file_name);
        
        % Load the mat file (assuming it contains a single double value)
        data = load(file_path);
        field_names = fieldnames(data);
        value = data.(field_names{1}); % Extract the value
        
        % Classify the file as 'full' or 'poor' based on its name
        if contains(file_name, 'full')
            full_values(end + 1) = value; %#ok<*SAGROW>
        elseif contains(file_name, 'poor')
            poor_values(end + 1) = value;
        end
    end
    
    % Compute averages, standard deviations, and t-test
    full_avg = mean(full_values);
    full_std = std(full_values);
    poor_avg = mean(poor_values);
    poor_std = std(poor_values);
    
    % Perform paired t-test
    [h, p_value, ci, stats] = ttest(full_values, poor_values);

    % Store results in the structure
    results.(param_name).full_avg = full_avg;
    results.(param_name).poor_avg = poor_avg;
    results.(param_name).full_std = full_std;
    results.(param_name).poor_std = poor_std;
    results.(param_name).t_stat = stats.tstat;
    results.(param_name).p_value = p_value;
end

% Convert the results structure to a table for easier display
summary_table = table();

for p = 1:length(parameters)
    param_name = parameters{p};
    full_avg = results.(param_name).full_avg;
    full_std = results.(param_name).full_std;
    poor_avg = results.(param_name).poor_avg;
    poor_std = results.(param_name).poor_std;
    t_stat = results.(param_name).t_stat;
    p_value = results.(param_name).p_value;
    
    % Append to the summary table
    summary_table = [summary_table; ...
        table({param_name}, full_avg, full_std, poor_avg, poor_std, t_stat, p_value, ...
        'VariableNames', {'Parameter', 'Full_Average', 'Full_Std', ...
                          'Poor_Average', 'Poor_Std', 'T_Statistic', 'P_Value'})];
end

% Display the summary table
disp(summary_table);

% Save the summary table as a CSV file
output_file = fullfile(base_dir, 'summary_conditions_fullpoor.csv');
writetable(summary_table, output_file);





% CwCcw vs ExpCon
% Initialize results structure
results = struct();

% Loop through each parameter
for p = 1:length(parameters)
    param_name = parameters{p};
    param_folder = fullfile(base_dir, parameter_folders{p});
    
    % Get list of all mat files in the parameter folder
    mat_files = dir(fullfile(param_folder, '*.mat'));
    
    % Initialize storage for ExpCon and CwCCw condition values
    expcon_values = [];
    cwccw_values = [];
    
    % Loop through each file
    for f = 1:length(mat_files)
        file_name = mat_files(f).name;
        file_path = fullfile(param_folder, file_name);
        
        % Load the mat file (assuming it contains a single double value)
        data = load(file_path);
        field_names = fieldnames(data);
        value = data.(field_names{1}); % Extract the value
        
        % Classify the file as 'ExpCon' or 'CwCCw' based on its name
        if contains(file_name, 'ExpCon')
            expcon_values(end + 1) = value; %#ok<*SAGROW>
        elseif contains(file_name, 'CwCCw')
            cwccw_values(end + 1) = value;
        end
    end
    
    % Ensure both vectors are the same size by truncating the longer one
    min_length = min(length(expcon_values), length(cwccw_values));
    expcon_values = expcon_values(1:min_length);
    cwccw_values = cwccw_values(1:min_length);
    
    % Compute averages, standard deviations, and perform paired t-tests
    expcon_avg = mean(expcon_values);
    expcon_std = std(expcon_values);
    cwccw_avg = mean(cwccw_values);
    cwccw_std = std(cwccw_values);
    
    % Perform paired t-test
    [~, p_value, ~, stats] = ttest(expcon_values, cwccw_values);
    
    % Store results
    results.(param_name).expcon_avg = expcon_avg;
    results.(param_name).expcon_std = expcon_std;
    results.(param_name).cwccw_avg = cwccw_avg;
    results.(param_name).cwccw_std = cwccw_std;
    results.(param_name).t_stat = stats.tstat;
    results.(param_name).p_value = p_value;
end

% Convert the results structure to a table for easier display
summary_table = table();
for p = 1:length(parameters)
    param_name = parameters{p};
    expcon_avg = results.(param_name).expcon_avg;
    expcon_std = results.(param_name).expcon_std;
    cwccw_avg = results.(param_name).cwccw_avg;
    cwccw_std = results.(param_name).cwccw_std;
    t_stat = results.(param_name).t_stat;
    p_value = results.(param_name).p_value;
    
    summary_table = [summary_table; ...
        table({param_name}, expcon_avg, expcon_std, cwccw_avg, cwccw_std, t_stat, p_value, ...
        'VariableNames', {'Parameter', 'ExpCon_Average', 'ExpCon_Std', 'CwCCw_Average', ...
                          'CwCCw_Std', 'T_Statistic', 'P_Value'})];
end

% Display the summary table
disp(summary_table);

% Save the summary table as a CSV file
output_file = fullfile(base_dir, 'summary_conditions_expcon_vs_cwccw.csv');
writetable(summary_table, output_file);





% subject parameters
subject_param_dir = fullfile(base_dir, 'subject_parameters');
% Initialize storage for FULL and POOR parameters
full_params = [];
poor_params = [];

% List all subject parameter files
param_files = dir(fullfile(subject_param_dir, '*.mat'));

% Loop through all parameter files
for i = 1:length(param_files)
    % Load the file
    file_name = param_files(i).name;
    file_path = fullfile(param_files(i).folder, file_name);
    load(file_path, 'subject_parameters'); % Load the structure
    
    % Check condition and classify
    if contains(file_name, 'full', 'IgnoreCase', true)
        full_params = [full_params; subject_parameters]; %#ok<AGROW>
    elseif contains(file_name, 'poor', 'IgnoreCase', true)
        poor_params = [poor_params; subject_parameters]; %#ok<AGROW>
    end
end

% Initialize result storage
results = struct();

% Calculate statistics for FULL condition
if ~isempty(full_params)
    full_A1 = [full_params.A1];
    full_A2 = [full_params.A2];
    full_sigma1 = [full_params.sigma1];
    full_baseline = [full_params.baseline];
    full_R2 = [full_params.R2];
    
    results.full.A1_avg = mean(full_A1);
    results.full.A1_std = std(full_A1);
    results.full.A2_avg = mean(full_A2);
    results.full.A2_std = std(full_A2);
    results.full.sigma1_avg = mean(full_sigma1);
    results.full.sigma1_std = std(full_sigma1);
    results.full.baseline_avg = mean(full_baseline);
    results.full.baseline_std = std(full_baseline);
    results.full.R2_avg = mean(full_R2);
    results.full.R2_std = std(full_R2);
else
    warning('No FULL condition data available.');
end

% Calculate statistics for POOR condition
if ~isempty(poor_params)
    poor_A1 = [poor_params.A1];
    poor_A2 = [poor_params.A2];
    poor_sigma1 = [poor_params.sigma1];
    poor_baseline = [poor_params.baseline];
    poor_R2 = [poor_params.R2];
    
    results.poor.A1_avg = mean(poor_A1);
    results.poor.A1_std = std(poor_A1);
    results.poor.A2_avg = mean(poor_A2);
    results.poor.A2_std = std(poor_A2);
    results.poor.sigma1_avg = mean(poor_sigma1);
    results.poor.sigma1_std = std(poor_sigma1);
    results.poor.baseline_avg = mean(poor_baseline);
    results.poor.baseline_std = std(poor_baseline);
    results.poor.R2_avg = mean(poor_R2);
    results.poor.R2_std = std(poor_R2);
else
    warning('No POOR condition data available.');
end

% Perform paired t-tests for FULL vs POOR conditions
if ~isempty(full_A1) && ~isempty(poor_A1)
    [~, results.A1_ttest_p, ~, A1_stats] = ttest(full_A1, poor_A1);
    results.A1_t_stat = A1_stats.tstat;
else
    results.A1_ttest_p = NaN;
    results.A1_t_stat = NaN;
end

if ~isempty(full_A2) && ~isempty(poor_A2)
    [~, results.A2_ttest_p, ~, A2_stats] = ttest(full_A2, poor_A2);
    results.A2_t_stat = A2_stats.tstat;
else
    results.A2_ttest_p = NaN;
    results.A2_t_stat = NaN;
end

if ~isempty(full_sigma1) && ~isempty(poor_sigma1)
    [~, results.sigma1_ttest_p, ~, sigma1_stats] = ttest(full_sigma1, poor_sigma1);
    results.sigma1_t_stat = sigma1_stats.tstat;
else
    results.sigma1_ttest_p = NaN;
    results.sigma1_t_stat = NaN;
end

if ~isempty(full_baseline) && ~isempty(poor_baseline)
    [~, results.baseline_ttest_p, ~, baseline_stats] = ttest(full_baseline, poor_baseline);
    results.baseline_t_stat = baseline_stats.tstat;
else
    results.baseline_ttest_p = NaN;
    results.baseline_t_stat = NaN;
end

if ~isempty(full_R2) && ~isempty(poor_R2)
    [~, results.R2_ttest_p, ~, R2_stats] = ttest(full_R2, poor_R2);
    results.R2_t_stat = R2_stats.tstat;
else
    results.R2_ttest_p = NaN;
    results.R2_t_stat = NaN;
end

% Display Results with higher precision
fprintf('Averaged Tuning Curve Parameters:\n');
fprintf('FULL Condition:\n');
fprintf('A1: %.10f (SD=%.10f), A2: %.10f (SD=%.10f), Sigma1: %.10f (SD=%.10f), Baseline: %.10f (SD=%.10f), R2: %.10f (SD=%.10f)\n', ...
    results.full.A1_avg, results.full.A1_std, results.full.A2_avg, results.full.A2_std, ...
    results.full.sigma1_avg, results.full.sigma1_std, ...
    results.full.baseline_avg, results.full.baseline_std, ...
    results.full.R2_avg, results.full.R2_std);

fprintf('\nPOOR Condition:\n');
fprintf('A1: %.10f (SD=%.10f), A2: %.10f (SD=%.10f), Sigma1: %.10f (SD=%.10f), Baseline: %.10f (SD=%.10f), R2: %.10f (SD=%.10f)\n', ...
    results.poor.A1_avg, results.poor.A1_std, results.poor.A2_avg, results.poor.A2_std, ...
    results.poor.sigma1_avg, results.poor.sigma1_std, ...
    results.poor.baseline_avg, results.poor.baseline_std, ...
    results.poor.R2_avg, results.poor.R2_std);

fprintf('\nPaired t-test Results:\n');
fprintf('A1: t(%.0f) = %.10f, p = %.10f\n', length(full_A1)-1, results.A1_t_stat, results.A1_ttest_p);
fprintf('A2: t(%.0f) = %.10f, p = %.10f\n', length(full_A2)-1, results.A2_t_stat, results.A2_ttest_p);
fprintf('Sigma1: t(%.0f) = %.10f, p = %.10f\n', length(full_sigma1)-1, results.sigma1_t_stat, results.sigma1_ttest_p);
fprintf('Baseline: t(%.0f) = %.10f, p = %.10f\n', length(full_baseline)-1, results.baseline_t_stat, results.baseline_ttest_p);
fprintf('R2: t(%.0f) = %.10f, p = %.10f\n', length(full_R2)-1, results.R2_t_stat, results.R2_ttest_p);

% Save results as a table and export to CSV
output_table = table( ...
    results.full.A1_avg, results.full.A1_std, results.poor.A1_avg, results.poor.A1_std, results.A1_t_stat, results.A1_ttest_p, ...
    results.full.A2_avg, results.full.A2_std, results.poor.A2_avg, results.poor.A2_std, results.A2_t_stat, results.A2_ttest_p, ...
    results.full.sigma1_avg, results.full.sigma1_std, results.poor.sigma1_avg, results.poor.sigma1_std, results.sigma1_t_stat, results.sigma1_ttest_p, ...
    results.full.baseline_avg, results.full.baseline_std, results.poor.baseline_avg, results.poor.baseline_std, results.baseline_t_stat, results.baseline_ttest_p, ...
    results.full.R2_avg, results.full.R2_std, results.poor.R2_avg, results.poor.R2_std, results.R2_t_stat, results.R2_ttest_p, ...
    'VariableNames', {'Full_A1_Avg', 'Full_A1_SD', 'Poor_A1_Avg', 'Poor_A1_SD', 'A1_t_stat', 'A1_p_value', ...
                      'Full_A2_Avg', 'Full_A2_SD', 'Poor_A2_Avg', 'Poor_A2_SD', 'A2_t_stat', 'A2_p_value', ...
                      'Full_Sigma1_Avg', 'Full_Sigma1_SD', 'Poor_Sigma1_Avg', 'Poor_Sigma1_SD', 'Sigma1_t_stat', 'Sigma1_p_value', ...
                      'Full_Baseline_Avg', 'Full_Baseline_SD', 'Poor_Baseline_Avg', 'Poor_Baseline_SD', 'Baseline_t_stat', 'Baseline_p_value', ...
                      'Full_R2_Avg', 'Full_R2_SD', 'Poor_R2_Avg', 'Poor_R2_SD', 'R2_t_stat', 'R2_p_value'});

output_filename = fullfile(base_dir, 'subject_parameters_stats_fullpoor.csv');
writetable(output_table, output_filename);






% Initialize storage for ExpCon and CwCCw parameters
expcon_params = [];
cwccw_params = [];

% List all subject parameter files
param_files = dir(fullfile(subject_param_dir, '*.mat'));

% Loop through all parameter files
for i = 1:length(param_files)
    % Load the 
    file_name = param_files(i).name;
    file_path = fullfile(param_files(i).folder, file_name);
    load(file_path, 'subject_parameters'); % Load the structure
    
    % Check condition and classify
    if contains(file_name, 'ExpCon', 'IgnoreCase', true)
        expcon_params = [expcon_params; subject_parameters]; %#ok<AGROW>
    elseif contains(file_name, 'CwCCw', 'IgnoreCase', true)
        cwccw_params = [cwccw_params; subject_parameters]; %#ok<AGROW>
    end
end

% Initialize result storage
results = struct();

% Calculate statistics for ExpCon condition
if ~isempty(expcon_params)
    expcon_A1 = [expcon_params.A1];
    expcon_A2 = [expcon_params.A2];
    expcon_sigma1 = [expcon_params.sigma1];
    expcon_baseline = [expcon_params.baseline];
    expcon_R2 = [expcon_params.R2];
    
    results.expcon.A1_avg = mean(expcon_A1);
    results.expcon.A1_std = std(expcon_A1);
    results.expcon.A2_avg = mean(expcon_A2);
    results.expcon.A2_std = std(expcon_A2);
    results.expcon.sigma1_avg = mean(expcon_sigma1);
    results.expcon.sigma1_std = std(expcon_sigma1);
    results.expcon.baseline_avg = mean(expcon_baseline);
    results.expcon.baseline_std = std(expcon_baseline);
    results.expcon.R2_avg = mean(expcon_R2);
    results.expcon.R2_std = std(expcon_R2);
end

% Calculate statistics for CwCCw condition
if ~isempty(cwccw_params)
    cwccw_A1 = [cwccw_params.A1];
    cwccw_A2 = [cwccw_params.A2];
    cwccw_sigma1 = [cwccw_params.sigma1];
    cwccw_baseline = [cwccw_params.baseline];
    cwccw_R2 = [cwccw_params.R2];
    
    results.cwccw.A1_avg = mean(cwccw_A1);
    results.cwccw.A1_std = std(cwccw_A1);
    results.cwccw.A2_avg = mean(cwccw_A2);
    results.cwccw.A2_std = std(cwccw_A2);
    results.cwccw.sigma1_avg = mean(cwccw_sigma1);
    results.cwccw.sigma1_std = std(cwccw_sigma1);
    results.cwccw.baseline_avg = mean(cwccw_baseline);
    results.cwccw.baseline_std = std(cwccw_baseline);
    results.cwccw.R2_avg = mean(cwccw_R2);
    results.cwccw.R2_std = std(cwccw_R2);
end

% Truncate to match sizes for paired t-tests
min_length_A1 = min(length(expcon_A1), length(cwccw_A1));
expcon_A1 = expcon_A1(1:min_length_A1);
cwccw_A1 = cwccw_A1(1:min_length_A1);

min_length_A2 = min(length(expcon_A2), length(cwccw_A2));
expcon_A2 = expcon_A2(1:min_length_A2);
cwccw_A2 = cwccw_A2(1:min_length_A2);

min_length_R2 = min(length(expcon_R2), length(cwccw_R2));
expcon_R2 = expcon_R2(1:min_length_R2);
cwccw_R2 = cwccw_R2(1:min_length_R2);

min_length_sigma1 = min(length(expcon_sigma1), length(cwccw_sigma1));
expcon_sigma1 = expcon_sigma1(1:min_length_sigma1);
cwccw_sigma1 = cwccw_sigma1(1:min_length_sigma1);

min_length_baseline = min(length(expcon_baseline), length(cwccw_baseline));
expcon_baseline = expcon_baseline(1:min_length_baseline);
cwccw_baseline = cwccw_baseline(1:min_length_baseline);

% Perform paired t-tests
if ~isempty(expcon_A1) && ~isempty(cwccw_A1)
    [~, results.A1_ttest_p, ~, A1_stats] = ttest(expcon_A1, cwccw_A1);
    results.A1_t_stat = A1_stats.tstat;
end

if ~isempty(expcon_A2) && ~isempty(cwccw_A2)
    [~, results.A2_ttest_p, ~, A2_stats] = ttest(expcon_A2, cwccw_A2);
    results.A2_t_stat = A2_stats.tstat;
end

if ~isempty(expcon_R2) && ~isempty(cwccw_R2)
    [~, results.R2_ttest_p, ~, R2_stats] = ttest(expcon_R2, cwccw_R2);
    results.R2_t_stat = R2_stats.tstat;
end

if ~isempty(expcon_sigma1) && ~isempty(cwccw_sigma1)
    [~, results.sigma1_ttest_p, ~, sigma1_stats] = ttest(expcon_sigma1, cwccw_sigma1);
    results.sigma1_t_stat = sigma1_stats.tstat;
end

if ~isempty(expcon_baseline) && ~isempty(cwccw_baseline)
    [~, results.baseline_ttest_p, ~, baseline_stats] = ttest(expcon_baseline, cwccw_baseline);
    results.baseline_t_stat = baseline_stats.tstat;
end

% Display results
fprintf('Averaged Tuning Curve Parameters:\n');
fprintf('ExpCon Condition:\n');
fprintf('A1: %.10f (SD=%.10f), A2: %.10f (SD=%.10f), Sigma1: %.10f (SD=%.10f), Baseline: %.10f (SD=%.10f), R2: %.10f (SD=%.10f)\n', ...
    results.expcon.A1_avg, results.expcon.A1_std, ...
    results.expcon.A2_avg, results.expcon.A2_std, ...
    results.expcon.sigma1_avg, results.expcon.sigma1_std, ...
    results.expcon.baseline_avg, results.expcon.baseline_std, ...
    results.expcon.R2_avg, results.expcon.R2_std);

fprintf('\nCwCCw Condition:\n');
fprintf('A1: %.10f (SD=%.10f), A2: %.10f (SD=%.10f), Sigma1: %.10f (SD=%.10f), Baseline: %.10f (SD=%.10f), R2: %.10f (SD=%.10f)\n', ...
    results.cwccw.A1_avg, results.cwccw.A1_std, ...
    results.cwccw.A2_avg, results.cwccw.A2_std, ...
    results.cwccw.sigma1_avg, results.cwccw.sigma1_std, ...
    results.cwccw.baseline_avg, results.cwccw.baseline_std, ...
    results.cwccw.R2_avg, results.cwccw.R2_std);

fprintf('\nPaired t-test Results:\n');
fprintf('A1: t(%.0f) = %.10f, p = %.10f\n', length(expcon_A1)-1, results.A1_t_stat, results.A1_ttest_p);
fprintf('A2: t(%.0f) = %.10f, p = %.10f\n', length(expcon_A2)-1, results.A2_t_stat, results.A2_ttest_p);
fprintf('Sigma1: t(%.0f) = %.10f, p = %.10f\n', length(expcon_sigma1)-1, results.sigma1_t_stat, results.sigma1_ttest_p);
fprintf('Baseline: t(%.0f) = %.10f, p = %.10f\n', length(expcon_baseline)-1, results.baseline_t_stat, results.baseline_ttest_p);
fprintf('R2: t(%.0f) = %.10f, p = %.10f\n', length(expcon_R2)-1, results.R2_t_stat, results.R2_ttest_p);

% Save results as a table and export to CSV
output_table = table( ...
    results.expcon.A1_avg, results.expcon.A1_std, results.cwccw.A1_avg, results.cwccw.A1_std, results.A1_t_stat, results.A1_ttest_p, ...
    results.expcon.A2_avg, results.expcon.A2_std, results.cwccw.A2_avg, results.cwccw.A2_std, results.A2_t_stat, results.A2_ttest_p, ...
    results.expcon.sigma1_avg, results.expcon.sigma1_std, results.cwccw.sigma1_avg, results.cwccw.sigma1_std, results.sigma1_t_stat, results.sigma1_ttest_p, ...
    results.expcon.baseline_avg, results.expcon.baseline_std, results.cwccw.baseline_avg, results.cwccw.baseline_std, results.baseline_t_stat, results.baseline_ttest_p, ...
    results.expcon.R2_avg, results.expcon.R2_std, results.cwccw.R2_avg, results.cwccw.R2_std, results.R2_t_stat, results.R2_ttest_p, ...
    'VariableNames', {'ExpCon_A1_Avg', 'ExpCon_A1_SD', 'CwCCw_A1_Avg', 'CwCCw_A1_SD', 'A1_t_stat', 'A1_p_value', ...
                      'ExpCon_A2_Avg', 'ExpCon_A2_SD', 'CwCCw_A2_Avg', 'CwCCw_A2_SD', 'A2_t_stat', 'A2_p_value', ...
                      'ExpCon_Sigma1_Avg', 'ExpCon_Sigma1_SD', 'CwCCw_Sigma1_Avg', 'CwCCw_Sigma1_SD', 'Sigma1_t_stat', 'Sigma1_p_value', ...
                      'ExpCon_Baseline_Avg', 'ExpCon_Baseline_SD', 'CwCCw_Baseline_Avg', 'CwCCw_Baseline_SD', 'Baseline_t_stat', 'Baseline_p_value', ...
                      'ExpCon_R2_Avg', 'ExpCon_R2_SD', 'CwCCw_R2_Avg', 'CwCCw_R2_SD', 'R2_t_stat', 'R2_p_value'});

output_filename = fullfile(base_dir, 'subject_parameters_stats_expconcwccw.csv');
writetable(output_table, output_filename);






% subject parameters combined
% Define folder names corresponding to the parameters
parameter_folders = {'hit_rate_collection', 'false_rate_collection', 'dprime_collection', ...
                     'luminance_collection', 'accuracy_collection'};
% Define the parameters of interest
parameters = {'hit_rate', 'false_alarm_rate', 'd_prime', 'luminance', 'accuracy'};

% Initialize results structure
results = struct();

% Loop through each parameter
for p = 1:length(parameters)
    param_name = parameters{p};
    param_folder = fullfile(base_dir, parameter_folders{p});
    
    % Get list of all mat files in the parameter folder
    mat_files = dir(fullfile(param_folder, '*.mat'));
    
    % Initialize storage for each condition
    ExpCon_Full = [];
    ExpCon_Poor = [];
    CwCCw_Full = [];
    CwCCw_Poor = [];
    
    % Loop through each file
    for f = 1:length(mat_files)
        file_name = mat_files(f).name;
        file_path = fullfile(param_folder, file_name);
        
        % Load the mat file (assuming it contains a single double value)
        data = load(file_path);
        field_names = fieldnames(data);
        value = data.(field_names{1}); % Extract the value
        
        % Classify the file based on its name
        if contains(file_name, 'ExpCon') && contains(file_name, 'full')
            ExpCon_Full(end + 1) = value; %#ok<*SAGROW>
        elseif contains(file_name, 'ExpCon') && contains(file_name, 'poor')
            ExpCon_Poor(end + 1) = value;
        elseif contains(file_name, 'CwCCw') && contains(file_name, 'full')
            CwCCw_Full(end + 1) = value;
        elseif contains(file_name, 'CwCCw') && contains(file_name, 'poor')
            CwCCw_Poor(end + 1) = value;
        end
    end
    
    % Adjust lengths to match the shorter dataset
    min_full = min(length(ExpCon_Full), length(CwCCw_Full));
    min_poor = min(length(ExpCon_Poor), length(CwCCw_Poor));
    
    ExpCon_Full = ExpCon_Full(1:min_full);
    CwCCw_Full = CwCCw_Full(1:min_full);
    ExpCon_Poor = ExpCon_Poor(1:min_poor);
    CwCCw_Poor = CwCCw_Poor(1:min_poor);
    
    % Compute statistics for each condition
    results.(param_name).ExpCon_Full_avg = mean(ExpCon_Full);
    results.(param_name).ExpCon_Full_std = std(ExpCon_Full);
    results.(param_name).ExpCon_Poor_avg = mean(ExpCon_Poor);
    results.(param_name).ExpCon_Poor_std = std(ExpCon_Poor);
    results.(param_name).CwCCw_Full_avg = mean(CwCCw_Full);
    results.(param_name).CwCCw_Full_std = std(CwCCw_Full);
    results.(param_name).CwCCw_Poor_avg = mean(CwCCw_Poor);
    results.(param_name).CwCCw_Poor_std = std(CwCCw_Poor);
    
    % Perform paired t-tests for specified comparisons
    [~, results.(param_name).ExpCon_vs_CwCCw_Full_p, ~, stats] = ...
        ttest(ExpCon_Full, CwCCw_Full);
    results.(param_name).ExpCon_vs_CwCCw_Full_t = stats.tstat;
    
    [~, results.(param_name).ExpCon_vs_CwCCw_Poor_p, ~, stats] = ...
        ttest(ExpCon_Poor, CwCCw_Poor);
    results.(param_name).ExpCon_vs_CwCCw_Poor_t = stats.tstat;
end

% Convert the results structure to a table for easier display
summary_table = table();

for p = 1:length(parameters)
    param_name = parameters{p};
    ExpCon_Full_avg = results.(param_name).ExpCon_Full_avg;
    ExpCon_Full_std = results.(param_name).ExpCon_Full_std;
    ExpCon_Poor_avg = results.(param_name).ExpCon_Poor_avg;
    ExpCon_Poor_std = results.(param_name).ExpCon_Poor_std;
    CwCCw_Full_avg = results.(param_name).CwCCw_Full_avg;
    CwCCw_Full_std = results.(param_name).CwCCw_Full_std;
    CwCCw_Poor_avg = results.(param_name).CwCCw_Poor_avg;
    CwCCw_Poor_std = results.(param_name).CwCCw_Poor_std;
    Full_t = results.(param_name).ExpCon_vs_CwCCw_Full_t;
    Full_p = results.(param_name).ExpCon_vs_CwCCw_Full_p;
    Poor_t = results.(param_name).ExpCon_vs_CwCCw_Poor_t;
    Poor_p = results.(param_name).ExpCon_vs_CwCCw_Poor_p;
    
    % Append to the summary table
    summary_table = [summary_table; ...
        table({param_name}, ExpCon_Full_avg, ExpCon_Full_std, ...
              ExpCon_Poor_avg, ExpCon_Poor_std, ...
              CwCCw_Full_avg, CwCCw_Full_std, ...
              CwCCw_Poor_avg, CwCCw_Poor_std, ...
              Full_t, Full_p, Poor_t, Poor_p, ...
              'VariableNames', {'Parameter', 'ExpCon_Full_Avg', 'ExpCon_Full_Std', ...
                                'ExpCon_Poor_Avg', 'ExpCon_Poor_Std', ...
                                'CwCCw_Full_Avg', 'CwCCw_Full_Std', ...
                                'CwCCw_Poor_Avg', 'CwCCw_Poor_Std', ...
                                'Full_T_Stat', 'Full_P_Value', ...
                                'Poor_T_Stat', 'Poor_P_Value'})];
end

% Display the summary table
disp(summary_table);
% Save the summary table as a CSV file
output_file = fullfile(base_dir, 'summary_ExpCon_vs_CwCCw.csv');
writetable(summary_table, output_file);





% Subject parameters
subject_param_dir = fullfile(base_dir, 'subject_parameters');
% Initialize storage for each condition
ExpCon_Full_params = [];
CwCCw_Full_params = [];
ExpCon_Poor_params = [];
CwCCw_Poor_params = [];

% List all subject parameter files
param_files = dir(fullfile(subject_param_dir, '*.mat'));

% Loop through all parameter files
for i = 1:length(param_files)
    % Load the file
    file_name = param_files(i).name;
    file_path = fullfile(param_files(i).folder, file_name);
    load(file_path, 'subject_parameters'); % Load the structure

    % Check condition and classify
    if contains(file_name, 'ExpCon', 'IgnoreCase', true) && contains(file_name, 'full', 'IgnoreCase', true)
        ExpCon_Full_params = [ExpCon_Full_params; subject_parameters]; %#ok<AGROW>
    elseif contains(file_name, 'ExpCon', 'IgnoreCase', true) && contains(file_name, 'poor', 'IgnoreCase', true)
        ExpCon_Poor_params = [ExpCon_Poor_params; subject_parameters]; %#ok<AGROW>
    elseif contains(file_name, 'CwCCw', 'IgnoreCase', true) && contains(file_name, 'full', 'IgnoreCase', true)
        CwCCw_Full_params = [CwCCw_Full_params; subject_parameters]; %#ok<AGROW>
    elseif contains(file_name, 'CwCCw', 'IgnoreCase', true) && contains(file_name, 'poor', 'IgnoreCase', true)
        CwCCw_Poor_params = [CwCCw_Poor_params; subject_parameters]; %#ok<AGROW>
    else
        warning('File condition not recognized: %s', file_name);
    end
end

% Equalize vector lengths for comparison
min_full_len = min(length(ExpCon_Full_params), length(CwCCw_Full_params));
min_poor_len = min(length(ExpCon_Poor_params), length(CwCCw_Poor_params));

ExpCon_Full_params = ExpCon_Full_params(1:min_full_len);
CwCCw_Full_params = CwCCw_Full_params(1:min_full_len);
ExpCon_Poor_params = ExpCon_Poor_params(1:min_poor_len);
CwCCw_Poor_params = CwCCw_Poor_params(1:min_poor_len);

% Helper function to analyze parameters
analyze_subject_parameters = @(params) struct( ...
    'A1', [params.A1], ...
    'sigma1', [params.sigma1], ...
    'baseline', [params.baseline], ...
    'R2', [params.R2] ...
);

% Analyze each condition
ExpCon_Full_data = analyze_subject_parameters(ExpCon_Full_params);
CwCCw_Full_data = analyze_subject_parameters(CwCCw_Full_params);
ExpCon_Poor_data = analyze_subject_parameters(ExpCon_Poor_params);
CwCCw_Poor_data = analyze_subject_parameters(CwCCw_Poor_params);

% Initialize result storage
results = struct();

% Helper function for paired t-tests
compare_conditions = @(cond1, cond2) struct( ...
    'A1_ttest', perform_ttest(cond1.A1, cond2.A1), ...
    'sigma1_ttest', perform_ttest(cond1.sigma1, cond2.sigma1), ...
    'baseline_ttest', perform_ttest(cond1.baseline, cond2.baseline), ...
    'R2_ttest', perform_ttest(cond1.R2, cond2.R2) ...
);

% Perform paired t-tests
results.full = compare_conditions(ExpCon_Full_data, CwCCw_Full_data);
results.poor = compare_conditions(ExpCon_Poor_data, CwCCw_Poor_data);

% Display results
fprintf('Averaged Tuning Curve Parameters (ExpCon vs. CwCCw):\n');
fprintf('FULL Condition:\n');
fprintf('A1 t-test: %.3f | Sigma1 t-test: %.3f | Baseline t-test: %.3f | R2 t-test: %.3f\n', ...
    results.full.A1_ttest.p, results.full.sigma1_ttest.p, results.full.baseline_ttest.p, results.full.R2_ttest.p);

fprintf('\nPOOR Condition:\n');
fprintf('A1 t-test: %.3f | Sigma1 t-test: %.3f | Baseline t-test: %.3f | R2 t-test: %.3f\n', ...
    results.poor.A1_ttest.p, results.poor.sigma1_ttest.p, results.poor.baseline_ttest.p, results.poor.R2_ttest.p);

% Save results to CSV
output_table = table( ...
    results.full.A1_ttest.p, results.full.sigma1_ttest.p, results.full.baseline_ttest.p, results.full.R2_ttest.p, ...
    results.poor.A1_ttest.p, results.poor.sigma1_ttest.p, results.poor.baseline_ttest.p, results.poor.R2_ttest.p, ...
    'VariableNames', {'Full_A1_ttest_p', 'Full_sigma1_ttest_p', 'Full_baseline_ttest_p', 'Full_R2_ttest_p', ...
                      'Poor_A1_ttest_p', 'Poor_sigma1_ttest_p', 'Poor_baseline_ttest_p', 'Poor_R2_ttest_p'});

output_filename = fullfile(base_dir, 'subject_parameters_stats_ExpCon_vs_CwCCw.csv');
writetable(output_table, output_filename);

% Helper function for t-tests
function result = perform_ttest(data1, data2)
    if isempty(data1) || isempty(data2)
        result.p = NaN;
        result.tstat = NaN;
    else
        [~, result.p, ~, stats] = ttest(data1, data2);
        result.tstat = stats.tstat;
    end
end

% Display results
fprintf('Averaged Tuning Curve Parameters (ExpCon vs. CwCCw):\n');

fprintf('\nFULL Condition:\n');
fprintf('ExpCon - A1: Mean = %.3f, SD = %.3f | Sigma1: Mean = %.3f, SD = %.3f | Baseline: Mean = %.3f, SD = %.3f | R2: Mean = %.3f, SD = %.3f\n', ...
    mean(ExpCon_Full_data.A1), std(ExpCon_Full_data.A1), ...
    mean(ExpCon_Full_data.sigma1), std(ExpCon_Full_data.sigma1), ...
    mean(ExpCon_Full_data.baseline), std(ExpCon_Full_data.baseline), ...
    mean(ExpCon_Full_data.R2), std(ExpCon_Full_data.R2));
fprintf('CwCCw - A1: Mean = %.3f, SD = %.3f | Sigma1: Mean = %.3f, SD = %.3f | Baseline: Mean = %.3f, SD = %.3f | R2: Mean = %.3f, SD = %.3f\n', ...
    mean(CwCCw_Full_data.A1), std(CwCCw_Full_data.A1), ...
    mean(CwCCw_Full_data.sigma1), std(CwCCw_Full_data.sigma1), ...
    mean(CwCCw_Full_data.baseline), std(CwCCw_Full_data.baseline), ...
    mean(CwCCw_Full_data.R2), std(CwCCw_Full_data.R2));
fprintf('t-tests - A1: p = %.3f | Sigma1: p = %.3f | Baseline: p = %.3f | R2: p = %.3f\n', ...
    results.full.A1_ttest.p, results.full.sigma1_ttest.p, results.full.baseline_ttest.p, results.full.R2_ttest.p);

fprintf('\nPOOR Condition:\n');
fprintf('ExpCon - A1: Mean = %.3f, SD = %.3f | Sigma1: Mean = %.3f, SD = %.3f | Baseline: Mean = %.3f, SD = %.3f | R2: Mean = %.3f, SD = %.3f\n', ...
    mean(ExpCon_Poor_data.A1), std(ExpCon_Poor_data.A1), ...
    mean(ExpCon_Poor_data.sigma1), std(ExpCon_Poor_data.sigma1), ...
    mean(ExpCon_Poor_data.baseline), std(ExpCon_Poor_data.baseline), ...
    mean(ExpCon_Poor_data.R2), std(ExpCon_Poor_data.R2));
fprintf('CwCCw - A1: Mean = %.3f, SD = %.3f | Sigma1: Mean = %.3f, SD = %.3f | Baseline: Mean = %.3f, SD = %.3f | R2: Mean = %.3f, SD = %.3f\n', ...
    mean(CwCCw_Poor_data.A1), std(CwCCw_Poor_data.A1), ...
    mean(CwCCw_Poor_data.sigma1), std(CwCCw_Poor_data.sigma1), ...
    mean(CwCCw_Poor_data.baseline), std(CwCCw_Poor_data.baseline), ...
    mean(CwCCw_Poor_data.R2), std(CwCCw_Poor_data.R2));
fprintf('t-tests - A1: p = %.3f | Sigma1: p = %.3f | Baseline: p = %.3f | R2: p = %.3f\n', ...
    results.poor.A1_ttest.p, results.poor.sigma1_ttest.p, results.poor.baseline_ttest.p, results.poor.R2_ttest.p);














