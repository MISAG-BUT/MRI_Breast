% Description: Function for binary sphere creation
% Input:    r - sphere radius
%           sph - binary image of sphere
% -------------------------------------------------------------------
% Authors:  Roman Jakubicek
%           Jiri Chmelik
%           Jiri Jan
% ===================================================================
function [sph] = create_sphere(r)
v1 = -r;
v2 = r;

[x,y,z] = meshgrid(v1:v2,v1:v2,v1:v2);

sph = zeros(size(x));

sph( x.^2 + y.^2 + z.^2 <= r^2)=1;
