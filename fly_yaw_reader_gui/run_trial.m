function [ trial_data, trial_time ] = run_trial( trial_idx, task, run_obj, scanimage_client )

disp(['About to start trial task: ' task]);

% Setup data structures for read / write on the daq board
s = daq.createSession('ni');

ai_channels_used = [0:6];

aI = s.addAnalogInputChannel('Dev1', ai_channels_used, 'Voltage');
for i=1:length(ai_channels_used)
    aI(i).InputType = 'SingleEnded';
end

s.addAnalogOutputChannel('Dev1', 0:1, 'Voltage');

settings = sensor_settings;

SAMPLING_RATE = settings.sampRate;
s.Rate = SAMPLING_RATE;
total_duration = run_obj.pre_stim_t + run_obj.stim_t + run_obj.post_stim_t;
%s.DurationInSeconds = total_duration;

zero_stim = zeros(SAMPLING_RATE*total_duration,1);
stim = zeros(SAMPLING_RATE*total_duration,1);

begin_idx = run_obj.pre_stim_t * SAMPLING_RATE;
end_idx = (run_obj.pre_stim_t+run_obj.stim_t) * SAMPLING_RATE;

stim(begin_idx:end_idx) = 5.0;

output_data = [];
if( strcmp(task, 'LeftOdor') == 1 )
    output_data = [stim zero_stim];
elseif( strcmp(task, 'RightOdor') == 1 )
    output_data = [zero_stim stim];
elseif( strcmp(task, 'BothOdor') == 1 )
    output_data = [stim stim];
elseif( strcmp(task, 'NaturalOdor') == 1 )
    output_data = [stim zero_stim];
else
    disp(['ERROR: Task: ' task ' is not recognized.']);
end

queueOutputData(s, output_data);

% Trigger scanimage run if using 2p.
if(run_obj.using_2p == 1)
    scanimage_file_str = [task '_sid_' num2str(run_obj.session_id) '_tid_' num2str(trial_idx) '_'];
    fprintf(scanimage_client, [scanimage_file_str]);
    disp(['Wrote: ' scanimage_file_str ' to scanimage server' ]);
    acq = fscanf(scanimage_client, '%s');
    disp(['Read acq: ' acq ' from scanimage server' ]);    
end

[trial_data, trial_time] = s.startForeground();
end

