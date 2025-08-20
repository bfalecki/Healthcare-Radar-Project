function [ridge,TF_distribution_cut, f_ax_cut] = find_tfridge(TF_distribution,f_ax,opts)
%FIND_TFRIDGE 
% find time frequency ridge of the distribution

arguments
    TF_distribution % matrix (first dimension is frequency, second is time)
    f_ax % frequency axis of the TF_distribution
    opts.PossibleLowFrequency = min(f_ax) % low limit of the searched tfridge
    opts.PossibleHighFrequency = max(f_ax) % high limit of the searched tfridge
    opts.JumpPenalty = 0.02 % penalty to tfridge function
    opts.NuberOfRidges = 1 % how many ridges to find
end

f_ax_idxes = f_ax <= opts.PossibleHighFrequency & f_ax >= opts.PossibleLowFrequency;
f_ax_cut = f_ax(f_ax_idxes);
TF_distribution_cut = TF_distribution(f_ax_idxes,:);
ridge = tfridge(TF_distribution_cut,f_ax_cut, opts.JumpPenalty, "NumRidges",opts.NuberOfRidges);

end

