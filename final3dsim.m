function [x_,y_,z_,j,L] = final3dsim(x0,L,N,sigma,V,e,se,ce)
    j = 1; n = size(L,1);
    x_(:,j) = x0(:,1);
    y_(:,j) = x0(:,2);
    z_(:,j) = x0(:,3);
    done = 0; % flag for when all nodes stop moving
    while j < N-1 && ~done
        x_(:,j+1) = 0; y_(:,j+1) = 0; z_(:,j+1) = 0;
        for i=1:n
            circle_pts = zeros(n,3);
            circle_pts(i,:) = [x_(i,j) y_(i,j) z_(i,j)];
            % update L with visibility constraints
            for w=1:n % cycle through possible neighbors of i in view
                obstructed = 0;
                if w ~= i 
                    distw = norm([x_(i,j)-x_(w,j), y_(i,j)-y_(w,j) z_(i,j)-z_(w,j)]);
                    if distw <= V
                        % check obstruction in xy plane
                        xyobstructed = 0;
                        thetaiw  = atan2(y_(w,j)-y_(i,j), x_(w,j)-x_(i,j));
                        thetaiwp = thetaiw + 0.5*pi;
                        thetaiwm = thetaiw - 0.5*pi;                    
                        A = [x_(i,j) y_(i,j)] + 0.5*[cos(thetaiwp),sin(thetaiwp)];
                        B = [x_(i,j) y_(i,j)] + 0.5*[cos(thetaiwm),sin(thetaiwm)];
                        C = [x_(w,j) y_(w,j)] + [cos(thetaiwm),sin(thetaiwm)];
                        D = [x_(w,j) y_(w,j)] + [cos(thetaiwp),sin(thetaiwp)];
                        thetabc = atan2(C(2)-B(2), C(1)-B(1));
                        thetaad = atan2(D(2)-A(2), D(1)-A(1));
                        for q=1:n % check all other nodes less than w dist from i
                            if q~=w && q~=i && ~xyobstructed
                                distq = norm([x_(i,j)-x_(q,j), y_(i,j)-y_(q,j)]);
                                if distq < distw
                                    thetabq = atan2(y_(q,j)-B(2), x_(q,j)-B(1));
                                    thetaaq = atan2(y_(q,j)-A(2), x_(q,j)-A(1));
                                    if thetabc > 0.5*pi && thetabq < -0.5*pi
                                        thetabq = thetabq + 2*pi;
                                    elseif thetabc < -0.5*pi && thetabq > 0.5*pi
                                        thetabc = thetabc + 2*pi;
                                    end
                                    if thetaad > 0.5*pi && thetaaq < -0.5*pi
                                        thetaaq = thetaaq + 2*pi;
                                    elseif thetaad < -0.5*pi && thetaaq > 0.5*pi
                                        thetaad = thetaad + 2*pi;
                                    end
                                    if thetabq > thetabc && thetaaq < thetaad
                                        xyobstructed = 1;
                                    end
                                end
                            end
                        end
                        % check obstruction in xz plane
                        if xyobstructed
                            thetaiw  = atan2(z_(w,j)-z_(i,j), x_(w,j)-x_(i,j));
                            thetaiwp = thetaiw + 0.5*pi;
                            thetaiwm = thetaiw - 0.5*pi;                    
                            A = [x_(i,j) z_(i,j)] + 0.5*[cos(thetaiwp),sin(thetaiwp)];
                            B = [x_(i,j) z_(i,j)] + 0.5*[cos(thetaiwm),sin(thetaiwm)];
                            C = [x_(w,j) z_(w,j)] + [cos(thetaiwm),sin(thetaiwm)];
                            D = [x_(w,j) z_(w,j)] + [cos(thetaiwp),sin(thetaiwp)];
                            thetabc = atan2(C(2)-B(2), C(1)-B(1));
                            thetaad = atan2(D(2)-A(2), D(1)-A(1));
                            for q=1:n % check all other nodes less than w dist from i
                                if q~=w && q~=i && ~obstructed
                                    distq = norm([x_(i,j)-x_(q,j), z_(i,j)-z_(q,j)]);
                                    if distq < distw
                                        thetabq = atan2(z_(q,j)-B(2), x_(q,j)-B(1));
                                        thetaaq = atan2(z_(q,j)-A(2), x_(q,j)-A(1));
                                        if thetabc > 0.5*pi && thetabq < -0.5*pi
                                            thetabq = thetabq + 2*pi;
                                        elseif thetabc < -0.5*pi && thetabq > 0.5*pi
                                            thetabc = thetabc + 2*pi;
                                        end
                                        if thetaad > 0.5*pi && thetaaq < -0.5*pi
                                            thetaaq = thetaaq + 2*pi;
                                        elseif thetaad < -0.5*pi && thetaaq > 0.5*pi
                                            thetaad = thetaad + 2*pi;
                                        end
                                        if thetabq > thetabc && thetaaq < thetaad
                                            obstructed = 1;
                                        end
                                    end
                                end
                            end
                        end
                        if ~obstructed
                            L(i,w) = -1;
                        else
                            L(i,w) = 0;
                        end    
                    end
                end
            end
            for p=1:n
                L(p,p) = abs(sum(L(p,:)<0,2));
            end
            %
            for k=1:n
                if L(i,k) < 0 % connected
                    ndist  = norm([x_(i,j)-x_(k,j), y_(i,j)-y_(k,j), z_(i,j)-z_(k,j)]);
                    ndir = [x_(k,j)-x_(i,j), y_(k,j)-y_(i,j), z_(k,j)-z_(i,j)];
                    if se % add sensing error
                        derr   = -e + 2*e*rand(1); 
                        terr   = [-e + 2*e*rand(1), -e + 2*e*rand(1), -e + 2*e*rand(1)]; % theta error
                        ndir = terr*ndist*0.01 + ndir;
                        ndist  = (1+0.01*derr)*ndist;
                    end
                    circle_pts(k,:) = ndist.*ndir + [x_(i,j) y_(i,j) z_(i,j)];
                end
            end
            circle_pts(~any(circle_pts,2),:) = []; % remove zero rows
            if size(circle_pts,1) > 3
                [radius,center,Xb] = ExactMinBoundSphere3D([circle_pts(:,1),circle_pts(:,2),circle_pts(:,3)]);
            else % cannot create convex hull with less than 3 points, approx center, radius
                center = [0 0 0];
                for d = 1:size(circle_pts,1)
                    center = center + circle_pts(d,:);
                end
                radius = 0;
                for d = 1:size(circle_pts,1)
                    temp = norm(center - circle_pts(d,:));
                    if temp > radius
                        radius = temp;
                    end
                end
                center = center./size(circle_pts,1);
            end
            goal_step = [(center(1,1)-x_(i,j)) (center(1,2)-y_(i,j)) (center(1,3)-z_(i,j))];
            if norm(goal_step) == 0 % divide by zero check
                norm_step = [0 0 0];
            else
                norm_step = goal_step/norm(goal_step);
            end
            min = V/2;
            if radius < 3*sqrt(n/2)
                min = 0;
            else
                line = [x_(i,j) y_(i,j) z_(i,j) norm_step(1) norm_step(2) norm_step(3)]; % x0 and direction of a line
                for s=1:size(circle_pts,1)
                    midpoint = 0.5*[(x_(i,j)+circle_pts(s,1)) (y_(i,j)+circle_pts(s,2)) (z_(i,j)+circle_pts(s,3))];
                    sphere = [midpoint(1) midpoint(2) midpoint(3) 0.5*V]; % sphere center and radius
                    points = intersectLineSphere(line, sphere); % intersection point of line between i and center and sphere surface
                    length = norm(points(1,:) - [x_(i,j) y_(i,j) z_(i,j)]);
                    if length < min
                        min = length;
                    end
                end
            end
            limit_step = min*norm_step; % = 0 if radius < 3*sqrt(n/2)
            sig_step = sigma*norm_step; % vector in direction of center with length sigma
            % choose min step
            if norm(goal_step) < sigma && norm(goal_step) < norm(limit_step)
                step = goal_step;
            elseif norm(limit_step) < sigma && norm(limit_step) < norm(goal_step)
                step = limit_step;
            else
                step = sig_step;
            end  
            % check for collision (no error added yet)
            x_(i,j+1) = x_(i,j) + step(1);
            y_(i,j+1) = y_(i,j) + step(2);
            z_(i,j+1) = z_(i,j) + step(3);
            swerve = 0; % flag to only swerve once
            for r=1:n
                if r ~= i && ~swerve 
                    if norm([x_(i,j+1)-x_(r,j), y_(i,j+1)-y_(r,j), z_(i,j+1)-z_(r,j)]) <= 1
                        swerve = 1; % swerve right, decrease speed by 0.5
                        theta = atan2(step(2),step(1)) - 0.5*pi;
                        dist  = norm(step)*0.5*sigma;
                        step  = dist.*[cos(theta) sin(theta) 0] + [0 0 step(3)]; % z unchanged
                    end
                end
            end
            cdist  = norm(step);
            if cdist == 0
                cdir = [0 0 0];
            else
                cdir = step./cdist;
            end
            if ce % add control error
                derr   = -e + 2*e*rand(1); 
                terr   = [-e + 2*e*rand(1), -e + 2*e*rand(1), -e + 2*e*rand(1)];
                cdir = terr*cdist*0.01 + cdir;
                cdist  = (1+0.01*derr)*cdist;
            end
            step = cdist.*cdir;

            x_(i,j+1) = x_(i,j) + step(1);
            y_(i,j+1) = y_(i,j) + step(2);
            z_(i,j+1) = z_(i,j) + step(3);
        end
        if prod(round(10*(x_(:,j+1)-x_(:,j))) == zeros(n,1)) && prod(round(10*(y_(:,j+1)-y_(:,j))) == zeros(n,1)) && prod(round(10*(z_(:,j+1)-z_(:,j))) == zeros(n,1))
            done = 1; j = j-1; % finished one iteration ago
        end
        j = j+1;
    end
end