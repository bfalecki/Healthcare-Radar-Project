clear, close all


sc = SignalCapturer("DoSave",1,"FrameLength",1.87,"TotalRecLength",3*60,"SeparateChannels",0,"MaxSpeed", 1);
sc.configure();
sc.record();