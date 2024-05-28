clear
clc
% Constantes
n = 10;     % Factor de resolución ADC
vcc = 3.3;  % Voltaje de alimentación
Gecg = 1000;% Ganancia del EMG
frecuencia_muestreo=1000;
fs=frecuencia_muestreo;
% Configuración de conexión con BITalino
samplingRate = frecuencia_muestreo;  % Tasa de muestreo en Hz
duration = 2;  % Duración de la adquisición en segundos
window_size=500;

last_Signal1_avg = zeros(1, window_size);

% Configuración de conexión serial con Arduino
serial_port = 'COM22';  % Puerto serial al que está conectado el Arduino (ajustar según corresponda)
baud_rate = 115200;  % Velocidad de comunicación serial (bps)

% Conexión al dispositivo BITalino
b = bitalino(201805286283);

% % Inicialización de la figura para la visualización en tiempo real
figure(1);
subplot(2,1,1);
title('Señal ECG(1)');
xlabel('Tiempo (s)');
ylabel('Amplitud (mV)');
ylim([-1.5 1.5]);
hold on;
A1_raw_plot = plot(0, 0, 'b');   % Para la señal cruda (sin media móvil)
A1_avg_plot = plot(0, 0, 'r');   % Para la señal promedio (con media móvil)
subplot(2,1,2);
title('Señal EMG(2)');
xlabel('Tiempo (s)');
ylabel('Amplitud (mV)');
ylim([-1.5 1.5]);
grid on;
hold on;
A2_raw_plot = plot(0, 0, 'b');   % Para la señal cruda (sin media móvil)
A2_avg_plot = plot(0, 0, 'r');   % Para la señal promedio (con media móvil)

% Inicialización de la conexión serial con Arduino
arduino = serialport('COM22', 115200);

% Eliminar datos viejos que puedan haber llegado al puerto
flush(arduino);

pause(2);  % Esperar a que se estabilice la conexión




try
    while true
        % Iniciar adquisición de datos
        bioSignal = read(b,"Duration",duration);
        fprintf('Leyendo datos durante %.2f segundos...\n', duration);
        ecgSignal1 = bioSignal.A1; % EMG
        ecgSignal2 = bioSignal.A2; % ECG
    
        % Convertir los datos a mV
        Signal1 = 1000 * (((ecgSignal1 / (2^n)) - (1/2)) * vcc) / Gecg;
        Signal2 = 1000 * (((ecgSignal2 / (2^n)) - (1/2)) * vcc) / Gecg;    
        %Tiempo
        tiempo_Signal1= (0:length(Signal1)-1) * (1/frecuencia_muestreo);
        tiempo_Signal2= (0:length(Signal2)-1) * (1/frecuencia_muestreo);
    
        % Calcular la media móvil de los cuadrados de v1 y v2
        Signal1_avg = sqrt(movmean(Signal1.^2, window_size));
        Signal2_avg = sqrt(movmean(Signal2.^2, window_size));
    
        % Obtener el máximo de la media móvil de los cuadrados
        Signal1_max = max(Signal1_avg);
        Signal2_max = max(Signal2_avg);
    
        % Mapear los valores máximos al rango [0, 127]
        amplitude_1 = round(interp1([0, 1], [0, 15], Signal1_max));
        amplitude_2 = round(interp1([0, 1], [0, 15], Signal2_max));
        
        % Convertir los valores mapeados en un arreglo de bytes de 8 bits
        nibble_1 = uint8(amplitude_1);
        nibble_2 = uint8(amplitude_2);
        byte_Ard = bitshift(nibble_1, 4) + nibble_2;

        % % Actualizar las gráficas en tiempo real
        set(A1_raw_plot, 'XData', tiempo_Signal1(1:length(Signal1)), 'YData', Signal1);
        set(A1_avg_plot, 'XData', tiempo_Signal1(1:length(Signal1)), 'YData', Signal1_avg);
        set(A2_raw_plot, 'XData', tiempo_Signal1(1:length(Signal2)), 'YData', Signal2);
        set(A2_avg_plot, 'XData', tiempo_Signal1(1:length(Signal2)), 'YData', Signal2_avg);
        drawnow;
        % Eliminar datos viejos que puedan haber llegado al puerto
        flush(arduino);
        % Enviar los datos al Arduino
        write(arduino, byte_Ard, "uint8");
        % Imprimir los valores de nibble_1 y nibble_2
        fprintf('nibble_1: %d, nibble_2: %d, total: %d\n', nibble_1, nibble_2,byte_Ard);

        clear ecgSignal1 ecgSignal2 Signal1 Signal2 tiempo_Signal1 tiempo_Signal2 Signal1_avg Signal2_avg amplitude_1 amplitude_2 nibble_1 nibble_2 byte_Ard;
        
        
    end 

catch e
    fprintf('Error: %s\n', e.message);
    clear;
    


% Cerrar la conexión serial con el Arduino
clear arduino;
end
