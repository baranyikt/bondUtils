classdef IBezier3 < handle
% Interactive cubic Bezier curve in 2D.
%
% Example:
%  figure, axis(axis*5);  ibz = IBezier3([1 1 4 4; 2 4 2 4])
%  figure, axis(axis*10); ibz = IBezier3([1;2]);
%
% See also: IBezierChain, IPoint.

    properties
        cpt     % control points.
        l       % line points.
    end
    
    properties(Hidden)
        t
        n = 2000
        hline
        hwhisker
        hfig
        hax
    end
    
    %% {Con, De}structor
    methods
        function ibz = IBezier3(varargin)
        % Create a cubic Bezier curve in 2D.
        %
        % Usage:    ibz = IBezier3
        %           ibz = IBezeir3(cpt)
        %
        % INPUT:
        %  none     - create Bezier curve interactively in the current figure.
        %  cpt      - up to 4 control points. Either a k-vector of IPoints or 
        %             a 2-by-k array of [x; y] coordintates of k control points.
        %             If k is less than 4, the remaining control points are
        %             specified interactively.
        %
        % Example:
        %  figure, axis(axis*5);  ibz = IBezier3([1 1 4 4; 2 4 2 4])
        %  figure, axis(axis*10); ibz = IBezier3([1;2]);
        %
        % See also: IBezierChain, IPoint.
        
            if nargin
                val = varargin{1};
                if isa(val, 'IPoint') && numel(val) <= 4
                    ibz.cpt = val;
                elseif ismatrix(val) && size(val,2) <= 4
                    for ii=1:size(val,2)
                        cpt(ii) = IPoint(val(:,ii)); %#ok<*AGROW>
                    end
                    ibz.cpt = cpt;
                end
            end
            
            if length(ibz.cpt) < 4
                for ii=length(ibz.cpt)+1:4
                    ibz.cpt(ii) = IPoint; %#ok<*AGROW>
                end
            end
            ibz.t = linspace(0,1, ibz.n);
            ibz.hfig = gcf;
            ibz.hax = gca;
            ibz.compute_line;
            ibz.plot;
            
            % Setup user-interaction:
            for ii=1:4
                % A control point can refer to two Bezier segments.
                if ~isempty(ibz.cpt(ii).user_bmcb) && isa(ibz.cpt(ii).user_bmcb{1}, 'function_handle')
                    ibz.cpt(ii).user_bmcb{2} = @(ipt) bmcb(ibz, ipt);
                else
                    ibz.cpt(ii).user_bmcb{1} = @(ipt) bmcb(ibz, ipt);
                end
            end
        end
        
        function delete(ibz)
            delete(ibz.cpt);
            delete(ibz.hline);
            delete(ibz.hwhisker);
        end
    end
    
    %% Computations
    methods
        function p = point(ibz, t)
            p = (1-t).^3.*ibz.cpt(1) + 3*(1-t).^2.*t.*ibz.cpt(2) + 3*(1-t).*t.^2.*ibz.cpt(3) + t.^3.*ibz.cpt(4);
        end
        
        function dpdt = derivative(ibz,t)
            dpdt = 3*(1-t).^2.*(ibz.cpt(2)-ibz.cpt(1)) + 6*(1-t).*t.*(ibz.cpt(3)-ibz.cpt(2)) + 3*t.^2.*(ibz.cpt(4)-ibz.cpt(3));
        end
        
        function len = curve_length(ibz, t1, t2)
        % Length of the curve segment.
            switch nargin
                case 1
                    tstart = 0;
                    tend   = 1;
                case 2
                    tstart = 0;
                    tend = t1;
                case 3
                    tstart = t1;
                    tend   = t2;
            end
            
            ds = @(t) sqrt(sum(ibz.derivative(t).^2));
            
            for ii=1:length(tstart)
                for jj=1:length(tend)
                    len(ii,jj) = integral(ds, tstart(ii), tend(jj));
                end
            end
        end
        
        function compute_line(ibz)
            t = ibz.t; %#ok<*PROP>
            ibz.l = ibz.point(t);
        end
    end
    %% Plotting & interaction
    methods
        function plot(ibz)
            figure(ibz.hfig); hold on
            ibz.hline = plot(ibz.l(1,:), ibz.l(2,:));
            ibz.hwhisker(1) = plot([ibz.cpt(1).p(1) ibz.cpt(2).p(1)], [ibz.cpt(1).p(2) ibz.cpt(2).p(2)], 'k--');
            ibz.hwhisker(2) = plot([ibz.cpt(3).p(1) ibz.cpt(4).p(1)], [ibz.cpt(3).p(2) ibz.cpt(4).p(2)], 'k--');
            set(ibz.hline, 'PickableParts', 'none');
            set(ibz.hwhisker, 'PickableParts', 'none');
        end
        
        function update_plot(ibz)
            set(ibz.hline, 'xdata', ibz.l(1,:), 'ydata', ibz.l(2,:));
            set(ibz.hwhisker(1), 'xdata', [ibz.cpt(1).p(1) ibz.cpt(2).p(1)], 'ydata', [ibz.cpt(1).p(2) ibz.cpt(2).p(2)]);
            set(ibz.hwhisker(2), 'xdata', [ibz.cpt(3).p(1) ibz.cpt(4).p(1)], 'ydata', [ibz.cpt(3).p(2) ibz.cpt(4).p(2)]);
        end
        
        function toggle_controls(ibz)
            onoff = get(ibz.cpt(2).hp, 'visible');
            if strcmpi(onoff, 'off') onoff = 'on'; else onoff = 'off'; end
            for ii=1:4
                set(ibz.cpt(ii).hp, 'visible', onoff);
            end
            set(ibz.hwhisker, 'visible', onoff);
        end
        
        function bmcb(ibz, ~)
            ibz.compute_line;
            ibz.update_plot;
        end
    end
end