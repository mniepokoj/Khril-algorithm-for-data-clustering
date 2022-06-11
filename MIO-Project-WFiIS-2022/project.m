warning off;
clear;
clc;
close all;

perc = 0.8;
bound_perc = 0.2;
it = 5;
Description = strings(it, 1);
SC_u = zeros(it, 1);
PSO_u = zeros(it, 1);
SC_t = zeros(it, 1);
PSO_t = zeros(it, 1);


% Iris initialize
[dataset, value] = iris_dataset;
dataset = dataset.';
value = vec2ind(value)';
dataset = [dataset, value];
n = size(dataset, 1);

% seeds initialize
% dataset = readmatrix('seeds.csv');
%n = size(dataset);

% wine initialize
% [dataset, value] = wine_dataset;
% dataset = dataset.';
% value = vec2ind(value)';
% dataset = [dataset(:,1:7), value];
% n = size(dataset);
dataset = dataset(randperm(size(dataset, 1)), :);


% main loop
for loop = 1:it

    x_train = dataset([1:n*((loop-1)/it) n*((loop)/it)+1:end], 1:4);
    y_train = dataset([1:n*((loop-1)/it) n*((loop)/it)+1:end], 5);

    x_testing = dataset([n*((loop-1)/it)+1:n*((loop)/it)], 1:4);
    y_testing = dataset([n*((loop-1)/it)+1:n*((loop)/it)], 5);

    fprintf('Iteracja: %d\n', loop);
    Description(loop) = convertCharsToStrings(sprintf('Iteracja: %d (%%)', loop));

    %%--%%--%% Inicjalizacja FIS
    fis = readfis('sug41.fis');

    y_out = evalfis(fis, x_train);
    y_test = evalfis(fis, x_testing);


    %testing fis before Herd alghoritm
    y_temp = y_out;
    for i = 1:size(y_temp, 1)
        y_temp(i) = round(y_temp(i));
    end
    temp = y_temp - y_train;
    q = sum(temp == 0);
    fprintf('Percentage of corectly qualified cases (Subtractive Clustering FIS) - teaching set: %.0f%%\n', round(q / size(y_out, 1), 5) * 100);
    SC_u(loop) = round(q / size(y_out, 1), 5) * 100;
    y_temp = y_test;
    for i = 1:size(y_temp, 1)
        y_temp(i) = round(y_temp(i));
    end
    temp = y_temp - y_testing;
    q = sum(temp == 0);
    fprintf('Percentage of corectly qualified cases (Subtractive Clustering FIS) - testing set: %.0f%%\n', round(q / size(y_test, 1), 5) * 100);
    SC_t(loop) = round(q / size(y_test, 1), 5) * 100;


    %%--%%--%% Wykresy wyników (SubtractiveClustering FIS)
    % figure;
    % subplot(2, 1, 1)
    % scatter(1:n*perc, y_out, 55, 'r', 'd')
    % hold on;
    % scatter(1:n*perc, y_u, 'b', 'filled')
    % legend('ymodel', 'yreal')
    % title('Zbior uczacy');
    % subplot(2, 1, 2)
    % scatter(1:(n - n * perc), y_test, 55, 'r', 'd')
    % hold on;
    % scatter(1:(n - n * perc), y_t, 'b', 'filled')
    % legend('ymodel', 'yreal')
    % title('Zbior testujacy');


    %getting parameters from fis
    [in, out] = getTunableSettings(fis);
    paramVals = getTunableValues(fis, [in; out]);

    % calculating boundary
    LB = [];
    UB = [];
    bound_in = [];

    for i = 1:size(dataset, 2) - 1
        temp = fis.Inputs(i).MembershipFunctions.Parameters;
        bound_in = [bound_in, size(fis.Inputs(i).MembershipFunctions, 2) * size(temp, 2)];
    end

    for r = 1:size(dataset, 2) - 1
        for i = 1:min(bound_in)
            LB(end+1) = fis.Inputs(r).Range(1) - fis.Inputs(r).Range(1) * bound_perc;
            UB(end+1) = fis.Inputs(r).Range(2) + fis.Inputs(r).Range(2) * bound_perc;
        end
    end
    

    x = KH(fis, LB, UB, @cost, x_train, y_train);
    fis = setTunableValues(fis, in, x.');
    y_out = evalfis(fis, x_train);
    y_test = evalfis(fis, x_testing);



    %testing fis after Kril Herd alghoritm
    y_temp = y_out;
    for i = 1:size(y_temp, 1)
        y_temp(i) = round(y_temp(i));
    end
    temp = y_temp - y_train;
    q = sum(temp == 0);
    fprintf('Percentage of corectly qualified cases (KH) - teaching set:  %.0f%%\n', round(q / size(y_out, 1), 5) * 100);
    PSO_u(loop) = round(q / size(y_out, 1), 5) * 100;

    y_temp = y_test;
    for i = 1:size(y_temp, 1)
        y_temp(i) = round(y_temp(i));
    end
    temp = y_temp - y_testing;
    q = sum(temp == 0);
    fprintf('Percentage of corectly qualified cases (KH) - testing set:  %.0f%%\n', round(q / size(y_test, 1), 5) * 100);
    PSO_t(loop) = round(q / size(y_test, 1), 5) * 100;

    fprintf('\n\n\n\n');
end

Glowna_srednia_wynosi = mean(PSO_t)


function fitness = cost(x, fis, x_u, y_u)
for i = 1:size(x, 2)
    if x(i) == 0
        x(i) = 0.001 + rand * (0.05 - 0.001);
    end
end

fis_test = fis;
in = getTunableSettings(fis_test);

paramVals = x;
fis_test = setTunableValues(fis_test, in, paramVals.');

y_kh = evalfis(fis_test, x_u);

for i = 1:size(y_kh, 1)
    y_kh(i) = round(y_kh(i));
end

temp = y_kh - y_u;
q = sum(temp == 0);

fitness = (size(y_kh, 1) - q) / size(y_kh, 1);

end