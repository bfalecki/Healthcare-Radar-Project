function plot_surf(sp,tp,fp,normalize, surround_by, cmap,clims, true_surf)

if(~exist("true_surf", "var") || isempty(true_surf))
    true_surf = 0; % zużywa więcej zasobów, ale da się zapisać obrazek w wysokiej jakości
                % print(gcf,plotsPath + "surf.png",'-dpng','-r300'); gdzie 300
                % to rozdzielczość w dpi
                % np dla spektrogramu o wysokości 30000 punktów przy 25 cm na
                % ekranie (10 cali), dpi powinno być przynajmniej 30000/10 =
                % 3000
                % zalecany rozmiar stft: 30000x300
                % wykres całego pasma można zwężyć komendami
                % ax  = gca; ax.FontSize = 4; setFigSize([0.5 0 0.07 1])
end


latex = 0;
 if (~exist('surround_by','var') || string(class(surround_by)) == "string")
      surround_by = NaN;
 end

if(~isnan(surround_by))
    sp = surround(sp, surround_by);
 end

 if (~exist('fp','var') || string(class(fp)) == "string")
      fp = 1:size(sp,1);
 else
    if(~isnan(surround_by))
        fp = [min(fp)-mean(diff(fp)), fp, max(fp)+mean(diff(fp))];
    end
 end

 if (~exist('tp','var') || string(class(tp)) == "string")
      tp = 1:size(sp,2);
 else
    if(~isnan(surround_by))
        tp = [min(tp)-mean(diff(tp)), tp, max(tp)+mean(diff(tp))];
    end
end
 if ~exist('normalize','var')
      normalize = 1;
 end

 if(~exist("cmap", "var") || (isempty(cmap) || isscalar(cmap) && string(class(cmap)) == "double" && any(isnan(cmap))))
    cmap = "parula";
 end
if(string(class(cmap)) == "string" && cmap == "inferno")
    colormap(flipud(inferno(256)))
elseif(string(class(cmap)) == "double")
    colormap(cmap);
else
    colormap(cmap)
    % colormap("hot")
    % colormap("parula") % default
    % colormap("autumn")
    % colormap("jet")
end

if(true_surf)
    [X,Y] = meshgrid(tp,fp);
end

if(normalize == 1)
    surf_to_plot = db(sp) - max(db(sp), [], "all");
else
    surf_to_plot = sp;
end

if(true_surf)
    s = surf(X,Y,surf_to_plot);
    s.EdgeColor = 'none';
else
    imagesc(tp,fp,surf_to_plot);
    ax = gca;
    ax.YDir = "normal";
end

c = colorbar;
if(latex == 1)
        fontsize = 20;
        set(gca,'FontSize',fontsize);
        set(gca,'TickLabelInterpreter','latex')
        c.Label.Interpreter = 'latex';
        c.TickLabelInterpreter = 'latex';
end

if (normalize == 1)
    c.Label.String = '[dB]';
else
    c.Label.String = 'Amplitude';
end
if(~exist('clims', "var") || string(class(clims)) == "string")
    clim_low = quantile(surf_to_plot, 0.05,"all");
    clim_high = max(surf_to_plot, [], "all");
else
    clim_low = clims(1);
    clim_high = clims(2);
end


clim([clim_low clim_high])

set(gca,'xlim', [min(tp) max(tp)])
set(gca,'ylim', [min(fp) max(fp)])
view(0,90)
end

