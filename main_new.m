clear; clc; close all;
addpath(genpath('meanShift'));
datapath = 'flo';                               %flo文件目录 
filenms = dir(fullfile(datapath,'*.flo'));      %读取目录下所有flo文件的文件名
% for i = 1:length(filenms)                       %对所有文件进行处理
for i = 1:6                                     %对前2个文件进行处理
    close all;
    file = fullfile(datapath,filenms(i).name);  %flo文件全路径
    flow = readFlowFile(file);                  %读取flo文件
    u = flow(2:2:end,2:2:end,1);                %u方向光流
    v = flow(2:2:end,2:2:end,2);                %v方向光流
    r = sqrt(u.^2+v.^2);                        %光流大小
    maxr = max(abs(r(:)));
    r = r/maxr;                                 %光流相对大小
    o = atan2(u,v); o = o/pi;                   %光流方向
    ind = find(r>.15 & r*maxr>.6);              %找到所有光流相对大小大于0.15且绝对大小大于.6的光流点
    r_ = r(ind);
    o_ = o(ind);
    L_ = meanShift([r_(:), o_(:)],.4);          %meanShift聚类获得目标物体         
    L = zeros(size(u));
    L(ind) = L_;
    L = reshape(L,size(u));
    L1 = zeros(size(L));
    max_id = 0;
    for li = 1:max(L(:))                        %对目标物体进行重新编号
        Ib = (L==li);
        L_ = bwlabeln(Ib,8);
        L_(Ib) = L_(Ib)+max_id;
        max_id = max_id+max(L_(:));
        L1 = L1+L_;
    end
    if ~exist('output','dir'), mkdir('output'); end
    rects = []; f = ['output\' filenms(i).name(1:end-4)];
    img = flowToColor(flow);                    %将光流转化为彩色图
    h1 = figure(1); imshow(img); hold on
    for li = 1:max(L1(:))
        Ib = (L1==li);
        meanr = mean(r(Ib(:)));                 %目标平均光流相对大小
        numPts = sum(double(Ib(:)));            %目标像素大小
        % 仅显示光流相对大小大于0.3 且 目标大小适宜的物体
        if meanr>.3 && numPts>100 && numPts<numel(u)/10
            B = bwboundaries(Ib,'noholes');
            boundary = 2*B{1};
            plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 2);    %轮廓
        end
    end
    filename = [f '_boundary'];
    savefig(filename,h1,'png');
    h2 = figure(2); imshow(img); hold on
    for li = 1:max(L1(:))
        Ib = (L1==li);
        meanr = mean(r(Ib(:)));                 %目标平均光流相对大小
        numPts = sum(double(Ib(:)));            %目标像素大小
        % 仅显示光流相对大小大于0.3 且 目标大小适宜的物体
        if meanr>.3 && numPts>100 && numPts<numel(u)/10
            B = bwboundaries(Ib,'noholes');
            boundary = 2*B{1};
            plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 2);    %轮廓
            minx = min(boundary(:,2));
            maxx = max(boundary(:,2));
            miny = min(boundary(:,1));
            maxy = max(boundary(:,1));
            rect = [minx,miny;minx maxy;maxx maxy;maxx miny;minx miny]; %box
            rects = [rects; rect(1:4,:)];
            plot(rect(:,1), rect(:,2), 'r', 'LineWidth', 2);
        end
    end
    filename = [f '_box'];
    savefig(filename,h2,'png');
    csvwrite([f '_gt.txt'],rects);
end