function plotxZ(Z)
    %METHOD1 Summary of this method goes here
    %   Detailed explanation goes here
    plot(real(Z))
    hold on;
    plot(imag(Z))
    hold off;
end