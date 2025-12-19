function [signalIQ_comp, middles] = compensateDcParts(signalIQ, start_samples, end_samples)
%COMPENSATEDCPARTS perform dc compensation on each part

    middles = zeros(1, length(start_samples));
    signalIQ_comp = zeros(size(signalIQ));
    for k = 1:length(start_samples)
        idxes = start_samples(k):end_samples(k);
        middle = mean(signalIQ(idxes));
        middles(k) = middle;
        signalIQ_comp(idxes) = signalIQ(idxes) - middle;
    end

end

