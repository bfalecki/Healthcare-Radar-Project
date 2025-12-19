clear; close all;

sc = SignalCapturer("FrameLength",1.87,"TotalRecLength",220,"SeparateChannels",0,"MaxSpeed", 1,"SaveRaw",1);
% sc = SignalCapturer("DoSave",1,"FrameLength",0.1,"TotalRecLength",200,"SeparateChannels",0,"MaxSpeed", 10,"SaveRaw",1);
sc.configure();

SteerAngle = 0; % negative: to the right from the Phaser's perspective
                  % positive: to the left from the Phaser's perspective
sc.steerBeam(SteerAngle);
sc.record();

sc.saveData();
