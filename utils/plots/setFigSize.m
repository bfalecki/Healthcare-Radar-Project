function setFigSize(sizeType)
%SETFIGSIZE Summary of this function goes here
%   Detailed explanation goes here

if(string(class(sizeType)) == "double")
    if(length(sizeType) == 2)
        set(gcf,'units','normalized','outerposition',[1-sizeType(1) 1- sizeType(2) sizeType(1)  sizeType(2)])
    else
        set(gcf,'units','normalized','outerposition',sizeType)
    end
elseif(string(class(sizeType)) == "string")
    switch(sizeType)
        case "full" 
            set(gcf,'units','normalized','outerposition',[0 0 1 1])
        case "half"
            set(gcf,'units','normalized','outerposition',[0.2 0.2 0.5 0.5])
        case "half third"
            set(gcf,'units','normalized','outerposition',[0.2 0.2 0.333 0.5])
        case "half A4"
            width = 784/1.518*1.3;
            heigth = 536/1.239*1.3;
            set(gcf, "Units", "pixels",'outerposition',[100 100 width heigth])
        case "full A4"
            width = 25;
            heigth = 13;
            set(gcf,'units','centimeters','outerposition',[2 2 width heigth]*0.9)
        otherwise
          fprintf('Invalid sizeType\n' );
    end
end


end

