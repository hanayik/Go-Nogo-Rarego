function catcherror = GoNoGo

catcherror = 0; % default to no error code, if error, this variable will contain details, and a stack trace
%checkForUpdate(fileparts(mfilename('fullpath')));
[subj, runnum, presTime,  gapTime, respTime] = getSessionInfo; if isempty(subj); return; end
goPercent = 0.75;
rareGoPercent = 0.125;
noGoPercent = rareGoPercent;


% ------------------------- user defined vars -----------------------------
% -------------------------------------------------------------------------
veryPreciseTimingNeeded = false;
datadir = fullfile(fileparts(mfilename('fullpath')),'data'); % folder for saving data
if ~exist(datadir,'dir') % if data folder doesn't exist, make it
    mkdir(datadir);
end
if isnumeric(subj); subj = num2str(subj); end;
if isnumeric(runnum); runnum = num2str(runnum); end
datestring = getDateAndTime; % get date string down to the minute
instruct = sprintf(['\n\n',...
                    '[Press spacebar to start]']); % instruction string for participant/clinician
datafile = fullfile(datadir,sprintf('%s_%s_%s_%s.csv',subj, runnum,mfilename, datestring)); % make data file name for saving

% ------ don't edit below this line unless you know what you're doing -----
% -------------------------------------------------------------------------
nTrials = 100;
KbName('UnifyKeyNames'); % make all keyboards similar
oldLevel = Screen('Preference', 'VisualDebugLevel', 1);
if veryPreciseTimingNeeded
    Screen('Preference', 'SkipSyncTests', 0); %#ok
else
    Screen('Preference', 'SkipSyncTests',2);
end
PsychDefaultSetupPlus(3); % set up PTB with some standard values
params = PsychSetupParams(0,1); % set some standard parameters for this session
ShowInstructions(params, instruct, {'space', 'escape'}); % put instructions on screen
WaitSecs(0.5); % wait for 500 ms just to have a smooth transition from instruct to task
Screen('TextSize',params.win, 40);
try
    trials_go = ones(1,round((nTrials*goPercent)));
    trials_nogo = ones(1,round((nTrials*noGoPercent)))*2;
    trials_rarego = ones(1,round((nTrials*rareGoPercent)))*3;
    trialConditions = [trials_go trials_nogo trials_rarego];
    trialConditions = trialConditions(randperm(nTrials));
    jitStd = 500;
    jitMean = gapTime;
    jitAll = jitStd.*randn(nTrials,1) + jitMean;
    T = table;
    keys = {'escape', 'RightArrow', 'space'};
    for i = 1: nTrials
        trialCondition = trialConditions(i);
        [responseKey, rt, trialOnset] = showDot(params, trialCondition, presTime, respTime);
        if trialCondition == 1
            correctResp = '1!';
            trialType = 'go';
        elseif trialCondition == 2
            correctResp = '';
            trialType = 'nogo';
        elseif trialCondition == 3
            correctResp = '1!';
            trialType = 'rarego';
        end
        if strcmpi(responseKey, correctResp)
            acc = 1;
        else
            acc = 0;
        end
        T.subj{i,1} = subj;
        T.sess{i,1} = runnum;
        T.trial{i,1} = i;
        T.trialType{i,1} = trialType;
        T.accuracy{i,1} = acc;
        T.correctResp{i,1} = correctResp;
        T.subjResp{i,1} = responseKey;
        T.RT{i,1} = rt;
        writetable(T, datafile);
        WaitSecs('UntilTime', trialOnset + (presTime/1000) + (respTime/1000) + (jitAll(i)/1000));
    end
    Screen('Preference', 'VisualDebugLevel', oldLevel);
    CleanUp();
    save_to_base(1);
    WaitSecs(1);
    
catch catcherror
    save_to_base(1);
    CleanUp();
end
end
%sub functions below




















function [responseKey, rt, tOnset] = showDot(params, trialCondition, presTime, respTime)
% draw the number to screen
if trialCondition == 1
    circleColor = [0.5 0.5 0.5];
elseif trialCondition == 2
    circleColor = [1 1 0.4];
elseif trialCondition == 3
    circleColor = [0 0 0.8];
end
dotRect = CenterRectOnPoint([0 0 300 300],params.Xc, params.Yc);
Screen('FillOval', params.win, circleColor, dotRect);
tOnset = Screen('Flip',params.win);

%wait for presentation duration then remove 
% WaitSecs(presTime/1000);
% tOffset = Screen('Flip',params.win);

keyIsPressed = 0;
keyPressedTime = 0; %#ok
responseKey = '';
rt = 999;
elapsedTime = 0;

while ~keyIsPressed && elapsedTime <= respTime
    if elapsedTime < presTime
        Screen('FillOval', params.win, circleColor, dotRect);
        Screen('Flip',params.win);
    else
        Screen('Flip',params.win);
    end
    [keyIsPressed, keyPressedTime, keyCode] = KbCheck(-1);
    if keyIsPressed
        responseKey = KbName(keyCode);
        rt = keyPressedTime - tOnset;
        Screen('Flip', params.win);
        if strcmpi(responseKey, 'escape') % if escape was pressed then exit the session
            CleanUp;
            error('escape pressed by user');
        end
    end
    elapsedTime = (GetSecs - tOnset)*1000; % put in ms scale
end

end




function datestring = getDateAndTime
d = fix(clock);
datestring=sprintf('Y%04d_M%02d_D%02d_H%02d_M%02d_S%02d',...
    d(1),...
    d(2),...
    d(3),...
    d(4),...
    d(5),...
    d(6));
end


function startTime = ShowInstructions(params, instruct,keysToWaitFor)
if nargin < 3; keysToWaitFor = {'space', 'escape'}; end;
DrawFormattedText(params.win, instruct, 'center', 'center',params.TextColor);
Screen('Flip',params.win);
RestrictKeysForKbCheck(cellfun(@KbName, keysToWaitFor));
deviceN = -1;
[startTime, keyCode] = KbWait(deviceN);
if strcmpi(KbName(keyCode), 'escape')
    CleanUp;
end
RestrictKeysForKbCheck([]);
Screen('Flip',params.win);
end


function CleanUp(files)
if nargin < 1
    files = [];
end
ListenChar(0);
sca;
RestrictKeysForKbCheck([]);
end %CleanUp


function responseKey = showStimulus(params,imgname, dur,keys)
RestrictKeysForKbCheck(cellfun(@KbName, keys)); % only looks for keys we care about
timerStart = GetSecs; % start a timer to keep track of elapsed time
img = imread(imgname); % read pic into memory
imgsize = size(img); % get pic size
params.picRect = [0 0 imgsize(2) imgsize(1)]; % get rect in order to center on screen
if params.picRect(3) > params.rect(3) & params.picRect(4) > params.rect(4) %#ok % if width and height of image are bigger than screen
   scaleFactor = params.rect(3)/params.picRect(3); % scale by the width factor
   img = imresize(img,scaleFactor);
end
imgsize = size(img); % get pic size
params.picRect = [0 0 imgsize(2) imgsize(1)]; % get rect in order to center on screen
params.picRect = CenterRectOnPoint(params.picRect,params.Xc,params.Yc); % center on screen
Screen('Flip',params.win); % clear the screen
trialElapsedTime = 0; % init elapsed time variable with zero value (will count up to dur)
keyIsPressed = 0; % init repsonse checker
% while a key hasn't been pressed, and the elapsed time is less than dur
while ~keyIsPressed & trialElapsedTime < dur %#ok
    [keyIsPressed, ~, keyCode] = KbCheck(-1); % check for keyboard press
    tex = Screen('MakeTexture', params.win, img); % make texture
    Screen('DrawTexture', params.win, tex, [], [], 0); % draw the texture in back buffer
    Screen('Flip', params.win);% flip image to screen 
    if keyIsPressed % check if a response happened
        responseKey = KbName(keyCode);
        if strcmpi(responseKey, 'escape') % if escape was pressed then exit the session
            CleanUp;
        end
    end
    trialElapsedTime = GetSecs - timerStart; % keep track of elapsed time
    Screen('Close',tex);
end
Screen('Flip', params.win); % clear the screen
end


function PsychDefaultSetupPlus(featureLevel)
% PsychDefaultSetup(featureLevel) - Perform standard setup for Psychtoolbox.

% Default colormode to use: 0 = clamped, 0-255 range. 1 = unclamped 0-1 range.
global psych_default_colormode;
psych_default_colormode = 0;

% Reset KbName mappings:
clear KbName;

% Define maximum supported featureLevel for this Psychtoolbox installation:
maxFeatureLevel = 3;

% Sanity check featureLevel argument:
if nargin < 1 || isempty(featureLevel) || ~isscalar(featureLevel) || ~isnumeric(featureLevel) || featureLevel < 0
    error('Mandatory featureLevel argument missing or invalid (not a scalar number or negative).');
end

% Always AssertOpenGL:
AssertOpenGL;

% Level 1+ requested?
if featureLevel >= 1
    % Unify keycode to keyname mapping across operating systems:
    KbName('UnifyKeyNames');
end

% Level 2+ requested?
if featureLevel >= 2
    % Initial call to timing functions
    % Set global environment variable to ask PsychImaging() to enable
    % normalized color range for all drawing commands and Screen('MakeTexture'):
    psych_default_colormode = 1;
    GetSecs; WaitSecs(0.001);
end

% Level 2+ requested?
if featureLevel >= 3
    %suppress keypress to command window,
    %and hide the mouse pointer (usefull is most visual experiments)
    ListenChar(2);
    HideCursor;
end


if featureLevel > maxFeatureLevel
    error('This installation of Psychtoolbox can not execute scripts at the requested featureLevel of %i, but only up to level %i ! UpdatePsychtoolbox!', featureLevel, maxFeatureLevel);
end
return;
end

function params = PsychSetupParams(doAlphaBlending,doMultiSample)
%sets up some normal values used in experiments such as a gray background
%and Arial font, and a large text size, etc...
%saves all relevant screen info to the 'params' structure so that the
%entire structure can be passed in and out of functions, rather than
%zillions of variables. Also makes it expandable.
%
% History:
% 29-May-2015   th     made initial version of the function

global psych_default_colormode;
%make params structure
params = struct;
%set some defualt, common colors
params.colors.white = [1 1 1];
params.colors.black = [0 0 0];
params.colors.gray = [0.5 0.5 0.5];
params.colors.red = [1 0 0];
params.colors.green = [0 1 0];
%check if using normalized color values or not
if psych_default_colormode == 0
    params.colors.white = [255 255 255];
    params.colors.gray = [128 128 128];
end
%choose max screen number (will be the external monitor if connected)
params.screen = max(Screen('Screens'));
params.font = 'Arial'; %set the global font for PTB to use
params.tsize = 18; %set text size
params.TextColor = [params.colors.black]; %set global text color
%set the background color of the screen (defaults to gray)
params.background = params.colors.white;
params.multiSample = [];
if doMultiSample
    params.multiSample = 4;%set to a value greater than 0 if you want super sampling
end
%open the PTB window
[params.win, params.rect] = PsychImaging('OpenWindow', params.screen, params.background,[],[],[],[],params.multiSample);
%get screen width and height
[params.maxXpixels, params.maxYpixels] = Screen('WindowSize', params.win);
if doAlphaBlending
    %Set blend function for alpha blending
    Screen('BlendFunction', params.win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
end
%find center of screen
[params.Xc,params.Yc] = RectCenter([0 0 params.maxXpixels params.maxYpixels]);
%now that the window pointer exists, set some values from earlier
Screen('TextSize', params.win, params.tsize);
Screen('TextFont',params.win, params.font);
Screen('TextSize',params.win, params.tsize);
Screen('TextStyle', params.win, 1);

%Maximum priority level
params.topPriorityLevel = MaxPriority(params.win);
Priority(params.topPriorityLevel);
%Query the frame duration
params.ifi = Screen('GetFlipInterval', params.win);
end

function spoolUpTime = startRecording(movfile, frate)
%http://www.oodlestechnologies.com/blogs/PICTURE-IN-PICTURE-effect-using-FFMPEG
if nargin < 2
    frate = 30; % default value that works on my development computer (macbook 2015ish, osx 10.10.4)
end
spoolUpTime = 2;
if ismac % tested on macbook pro 2015+ i7 osx 10.10.4
    %in the future it would be nice to have a distributable binary, for now
    %we use homebrew
    %ffmpegpath = fullfile(fileparts(mfilename('fullpath')),'ffmpeg');
    ffmpegpath = 'ffmpeg';
    fmt = 'avfoundation';
    videoSize = '1280x720';
    screenInputDevice = '"1"';
    videoInputDevice = '"0"';
    audioInputDevice = '"0"';
    videoQuality = 30; % range from 0 to 60ish (lower numbers mean HUGE files, but better quality -- lossless) -- 40 seems ok 
    codec = 'libx264';
elseif IsWin % not tested yet
    warning('FFmpeg video recording is experimental on windows'); 
    ffmpegpath = 'ffmpeg';
    fmt = 'dshow';
    videoSize = '320x240'; %smaller because.... windows....
    %------- only tested on HP ProBook Win 7 ---------%
    screenInputDevice = 'video="screen-capture-recorder"';
    videoInputDevice = 'video="HP HD Camera"';
    audioInputDevice = 'audio="Internal Microphone (Conexant S"';
    %-------------------------------------------------%
    videoQuality = 40; % range from 0 to 60ish (lower numbers mean HUGE files, but better quality -- lossless) -- 40 seems ok 
end
cmd = sprintf(['%s -y -thread_queue_size 50 ','-f %s ',...
    '-framerate %2.2f -i %s -thread_queue_size 50 ',...
    '-f %s -framerate %2.2f -video_size %s ',...
    '-i %s:%s -c:v %s -crf %d -preset ultrafast ',...
    '-filter_complex ' '"[0]scale=iw/8:ih/8 [pip]; [1][pip] overlay=main_w-overlay_w-10:main_h-overlay_h-10" ',...
    '-r %2.2f "%s" &'],...
    ffmpegpath, fmt, frate, screenInputDevice, fmt, frate, videoSize, videoInputDevice, audioInputDevice,codec,videoQuality,frate,movfile);
% cmd = sprintf(['%s -y ',...
%     '-f %s -framerate %2.2f -video_size %s ',...
%     '-i %s:%s -c:v %s -crf %d -preset ultrafast ',...
%     '-r %2.2f %s &'],...
%     ffmpegpath, fmt, frate, videoSize, videoInputDevice, audioInputDevice,codec,videoQuality,frate,movfile);
disp(cmd);
system(cmd);
WaitSecs(spoolUpTime); % need to wait before checking if recording started -- give it time to actually start
if ~isRecording % if the recording did not start (usually due to an incompatible framerate for the hardware)
    if frate < 30
        frate = 30; % if lower framerate was tried (29.97) then try 30 now
    else
        frate = 29.97;
    end
    cmd = sprintf(['%s -y -thread_queue_size 50 ','-f %s ',...
        '-framerate %2.2f -i %s -thread_queue_size 50 ',...
        '-f %s -framerate %2.2f -video_size %s ',...
        '-i %s:%s -c:v %s -crf %d -preset ultrafast ',...
        '-filter_complex ' '"[0]scale=iw/8:ih/8 [pip]; [1][pip] overlay=main_w-overlay_w-10:main_h-overlay_h-10" ',...
        '-r %2.2f "%s" &'],...
        ffmpegpath, fmt, frate, screenInputDevice, fmt, frate, videoSize, videoInputDevice, audioInputDevice,codec,videoQuality,frate,movfile);
%     cmd = sprintf(['%s -y ',...
%         '-f %s -framerate %2.2f -video_size %s ',...
%         '-i %s:%s -c:v %s -crf %d -preset ultrafast ',...
%         '-r %2.2f %s &'],...
%     ffmpegpath, fmt, frate, videoSize, videoInputDevice, audioInputDevice,codec,videoQuality,frate,movfile);    
    disp(cmd); % display the command to matlab command window for debugging
    system(cmd);
    WaitSecs(spoolUpTime); % give the hardware time to actually get going
    if ~isRecording % if still not recording, throw an error
        CleanUp;
        error('ffmpeg recording was requested, but failed to start. This may be due to an incompatible setting')
    end
end
end %startRecording

function stopRecording
if ismac
    system('killall ffmpeg');
elseif IsWin
    system('Taskkill /IM ffmpeg.exe'); % request that ffmpeg stop
    system('Taskkill /IM cmd.exe /t'); % kill command window that pops up (and all child processes)
    pause(2);
    system('Taskkill /IM cmd.exe /t'); % do it again for good measure
end
end %stopRecording

function val = isRecording
if ismac
    [~, r] = system('pidof ffmpeg');
    if isempty(r);
        val = 0;
    else
        val = 1;
    end
elseif IsWin
    [~, r] = system('tasklist /FI "IMAGENAME eq ffmpeg.exe"');
    if strfind(r, 'ffmpeg')
        val = true;
    else
        val = false;
    end
end
end % isRecording

function PATH = setPathForFFMPEG
if IsWin
    PATH = getenv('PATH');
    setenv('PATH', [PATH ';' fullfile(fileparts(mfilename('fullpath')),'winffmpeg')]);
    PATH = getenv('PATH');
    disp(PATH);
else
    PATH = getenv('PATH');
    setenv('PATH', [PATH ':/usr/local/bin']);
    PATH = getenv('PATH');
    disp(PATH);
end
end % setPathForFFMPEG

function checkForUpdate(repoPath)
prevPath = pwd;
cd(repoPath);
if exist('.git','dir') %only check for updates if program was installed with "git clone"
    [~, r] = system('git fetch origin','-echo');
    if strfind(r,'fatal')
        warning('Unabe to check for updates. Internet issue?');
        return;
    end
    [~, r] = system('git status','-echo');
    if strfind(r,'behind')
        if askToUpdate
            system('git reset --hard HEAD');
            system('git pull');
            showRestartMsg
        end
    end
else %do nothing for now
    warning('To enable updates run "!git clone git@gitlab.com:Hanayik/%s.git"',mfilename);
end
cd(prevPath);
end % checkForUpdate

function showRestartMsg
uiwait(msgbox('The program must be restarted for changes to take effect. Click "OK" to quit the program. You will need to restart it just as you normally would','Restart Program'))
exit;
end % showRestartMsg

function a = askToUpdate
% Construct a questdlg
choice = questdlg(sprintf('An update for %s is available. Would you like to update?',mfilename), ...
	'Auto update', ...
	'Yes','No','Yes');
% Handle response
switch choice
    case 'Yes'
        a = true;
    case 'No'
        a = false;
end
end % askToUpdate


function [subj, runnum, presTime,  gapTime, respTime] = getSessionInfo
subj = [];
runnum = [];
doVideoRecord = [];
prompt={'Participant: ','Session: ', 'Presentation time ms: ', 'Gap time ms: ', 'Response time ms: '};
   name='OddOrEven';
   numlines=1;
   defaultanswer={'0','0','450', '1000', '1500'};
 
answer=inputdlg(prompt,name,numlines,defaultanswer);
if isempty(answer); return; end
subj = answer{1};
runnum = answer{2};
presTime = str2double(answer{3});
gapTime = str2double(answer{4});
respTime = str2double(answer{5});
end


function syncFilesToCloud(files, subj, runnum)
if isempty(files); return; end;
cloudDir = ('~/Box Sync/MUSC_POLAR'); % check for box (MUSC computers)
if ~isdir(cloudDir)
    cloudDir = ('~/Dropbox (C-STAR)'); % if that doesn't exist check this
    if ~isdir(cloudDir) 
        cloudDir = ('~/Dropbox'); % check this last
        if ~isdir(cloudDir)
            warning('Data syncing not available. No Drop(box) folder detected at %s', cloudDir);
            return;
        end
    end
end;
taskFolder = fullfile(cloudDir,'PolarData', mfilename, subj, runnum);
if ~isdir(taskFolder)
    mkdir(taskFolder);
end
n = size(files,1);
h = waitbar(0,'Copying files for data syncing...');
steps = n;
for i = 1:steps
    [~,nm,ext] = fileparts(files{i});
    copyfile(files{i},fullfile(taskFolder,[nm ext]));
    waitbar(i / steps)
end
close(h) 
end
