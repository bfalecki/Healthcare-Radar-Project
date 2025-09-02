function cdata = prep_cdata(matrix,opts)
%PREP_CDATA Prepare cdata to plot

arguments
    matrix % matrix to plot
    opts.QuantileVal = 0.5 % threshold qunatile
end

    cdata = matrix;
    cdata = abs(cdata);
    thresh = quantile(nonzeros(cdata),opts.QuantileVal,"all");
    cdata(cdata < thresh) = thresh;
    cdata = db(cdata);
end

