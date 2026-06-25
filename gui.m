classdef gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        GridLayout             matlab.ui.container.GridLayout
        KUKAYouBotGUILabel     matlab.ui.control.Label
        MovementRotationPanel  matlab.ui.container.Panel
        GridLayout4            matlab.ui.container.GridLayout
        SpeedKnob              matlab.ui.control.Knob
        SpeedKnobLabel         matlab.ui.control.Label
        RotationKnob           matlab.ui.control.Knob
        RotationKnobLabel      matlab.ui.control.Label
        CameraModulePanel      matlab.ui.container.Panel
        GridLayout3            matlab.ui.container.GridLayout
        Image                  matlab.ui.control.Image
        TakePhotoButton        matlab.ui.control.Button
        ArmJointsPanel         matlab.ui.container.Panel
        GridLayout2            matlab.ui.container.GridLayout
        J1Label_5              matlab.ui.control.Label
        jointFiveSlider        matlab.ui.control.Slider
        J1Label_4              matlab.ui.control.Label
        jointFourSlider        matlab.ui.control.Slider
        J1Label_3              matlab.ui.control.Label
        jointThreeSlider       matlab.ui.control.Slider
        J1Label_2              matlab.ui.control.Label
        jointTwoSlider         matlab.ui.control.Slider
        J1Label                matlab.ui.control.Label
        jointOneSlider         matlab.ui.control.Slider
        % ДОБАВЛЕНО ДЛЯ ЗАХВАТА
        GripperPanel           matlab.ui.container.Panel
        GridLayout5            matlab.ui.container.GridLayout
        GripperLabel           matlab.ui.control.Label
        GripperSlider          matlab.ui.control.Slider
    end

    properties (Access = public)
        sim % The Coppelia Sim
        clientID % The ClientID for the CoppeliaSim server
        handles % The handles for the CoppeliaSim Kuka Robot
    end

    methods (Access = private)

        function radians = getRadiansForDegrees(~,degrees)
            radians = degrees * (pi / 180);
        end

        function resetWheelVelocities(app)
            setWheelJointVelocity(app,1,0);
            setWheelJointVelocity(app,2,0);
            setWheelJointVelocity(app,3,0);
            setWheelJointVelocity(app,4,0);
        end
        
        function setJointTargetPosition(app, index, newValue)
            app.sim.simxSetJointTargetPosition( ...
                app.clientID, ...
                app.handles(index), ...
                getRadiansForDegrees(app,newValue), ...
                app.sim.simx_opmode_streaming ...
            );
        end

        function setWheelJointVelocity(app, index, newValue) 
            app.sim.simxSetJointTargetVelocity( ...
                app.clientID, ...
                app.handles(index), ...
                getRadiansForDegrees(app,newValue), ...
                app.sim.simx_opmode_oneshot ...
            );
        end

        function image = getVisionSensorImage(app)
            [~,~,imageData] = app.sim.simxGetVisionSensorImage2( ...
                app.clientID, ...
                app.handles(12), ...  % ИЗМЕНЕНО С 11 НА 12
                0, ...
                app.sim.simx_opmode_oneshot_wait ...
            );

            image = imageData;
        end
        
        % РАБОЧИЙ МЕТОД ДЛЯ ЛИНЕЙНОГО ЗАХВАТА
        function setGripperPosition(app, value)
          
            if length(app.handles) < 11 || app.handles(10) == -1 || app.handles(11) == -1
                fprintf('ERROR: Gripper handles not found!\n');
                return;
            end
  
            
            maxMovement = 0.025; 
            position1 = value * maxMovement; % 0 -> 0.025 м            
       
            position2 = -value * maxMovement; % 0 -> -0.025 м           
  
            app.sim.simxSetJointPosition( ...
                app.clientID, ...
                app.handles(10), ...
                position1, ...
                app.sim.simx_opmode_streaming ...
            );
            
            app.sim.simxSetJointPosition( ...
                app.clientID, ...
                app.handles(11), ...
                position2, ...
                app.sim.simx_opmode_streaming ...
            );
        end
    end
    
    methods (Access = public)
        
        function setDefaultValues(app)
            % Инициализация значений по умолчанию
            
            fprintf('Initializing KUKA YouBot GUI...\n');
            
            app.jointOneSlider.Value = 0;
            app.jointTwoSlider.Value = 0;
            app.jointThreeSlider.Value = 0;
            app.jointFourSlider.Value = 0;
            app.jointFiveSlider.Value = 0;
            
            if isprop(app, 'GripperSlider')
                app.GripperSlider.Value = 0.5;
                fprintf('Gripper initialized to middle position\n');
            end
            
            % Инициализация камеры
            try
                app.Image.ImageSource = getVisionSensorImage(app);
                fprintf('Camera initialized\n');
            catch ME
                fprintf('Camera initialization warning: %s\n', ME.message);
            end

            % Инициализация суставов руки
            fprintf('Initializing arm joints to zero position...\n');
            setJointTargetPosition(app,5,0);
            setJointTargetPosition(app,6,0);
            setJointTargetPosition(app,7,0);
            setJointTargetPosition(app,8,0);
            setJointTargetPosition(app,9,0);
            
            % Инициализация захвата
            if isprop(app, 'GripperSlider') && length(app.handles) >= 11 && app.handles(10) ~= -1 && app.handles(11) ~= -1
                fprintf('Initializing gripper to middle position...\n');
                setGripperPosition(app, 0.5);
            else
                fprintf('Gripper handles not available\n');
            end
            
            fprintf('GUI Initialization Complete\n\n');
        end

    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Value changing function: jointOneSlider
        function jointOneSliderValueChanging(app, event)
            changingValue = event.Value;
            setJointTargetPosition(app, 5, changingValue);
        end

        % Value changing function: jointTwoSlider
        function jointTwoSliderValueChanging(app, event)
            changingValue = event.Value;
            setJointTargetPosition(app, 6, changingValue);
        end

        % Value changing function: jointThreeSlider
        function jointThreeSliderValueChanging(app, event)
            changingValue = event.Value;
            setJointTargetPosition(app, 7, changingValue);
        end

        % Value changing function: jointFourSlider
        function jointFourSliderValueChanging(app, event)
            changingValue = event.Value;
            setJointTargetPosition(app, 8, changingValue);
        end

        % Value changing function: jointFiveSlider
        function jointFiveSliderValueChanging(app, event)
            changingValue = event.Value;
            setJointTargetPosition(app, 9, changingValue);
        end

        % Callback для захвата
        function GripperSliderValueChanging(app, event)
            changingValue = event.Value;
            setGripperPosition(app, changingValue);
        end

        % Value changing function: RotationKnob
        function RotationKnobValueChanging(app, event)
            newValue = event.Value;
            absNewValue = abs(newValue);
            
            % Prevents low value close to 0 not fully stoppgin the wheels.
            if newValue < 10 && newValue > -10
                resetWheelVelocities(app)
                return
            end

            if newValue < 0
                setWheelJointVelocity(app,1,absNewValue);
                setWheelJointVelocity(app,2,-absNewValue);
                setWheelJointVelocity(app,3,absNewValue);
                setWheelJointVelocity(app,4,-absNewValue);

            elseif newValue > 0
                setWheelJointVelocity(app,1,-absNewValue);
                setWheelJointVelocity(app,2,absNewValue);
                setWheelJointVelocity(app,3,-absNewValue);
                setWheelJointVelocity(app,4,absNewValue);
            end
        end

        % Value changed function: RotationKnob
        function RotationKnobValueChanged(app, event)
            app.RotationKnob.Value = 0;
            resetWheelVelocities(app);
        end

        % Value changing function: SpeedKnob
        function SpeedKnobValueChanging(app, event)
            newValue = event.Value;
            setWheelJointVelocity(app,1,newValue);
            setWheelJointVelocity(app,2,newValue);
            setWheelJointVelocity(app,3,newValue);
            setWheelJointVelocity(app,4,newValue);
        end

        % Value changed function: SpeedKnob
        function SpeedKnobValueChanged(app, event)
            app.SpeedKnob.Value = 0;
            resetWheelVelocities(app);
        end

        % Button pushed function: TakePhotoButton
        function TakePhotoButtonPushed(app, event)
            app.Image.ImageSource = getVisionSensorImage(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'0.6x', '1x'};
            app.GridLayout.RowHeight = {'0.8x', '0.8x', '1.28x'};

            % Create CameraModulePanel
            % app.CameraModulePanel = uipanel(app.GridLayout);
            % app.CameraModulePanel.Title = 'Camera Module';
            % app.CameraModulePanel.Layout.Row = 1;
            % app.CameraModulePanel.Layout.Column = 1;

            % Create GridLayout3
           % app.GridLayout3 = uigridlayout(app.CameraModulePanel);
            %app.GridLayout3.ColumnWidth = {'1x'};
            %app.GridLayout3.RowHeight = {'1x', '0.24x'};

            % Create Image
           % app.Image = uiimage(app.GridLayout3);
           % app.Image.ScaleMethod = 'fill';
           % app.Image.Layout.Row = 1;
           % app.Image.Layout.Column = 1;

            % Create TakePhotoButton
           % app.TakePhotoButton = uibutton(app.GridLayout3, 'push');
           % app.TakePhotoButton.ButtonPushedFcn = createCallbackFcn(app, @TakePhotoButtonPushed, true);
           % app.TakePhotoButton.Layout.Row = 2;
           % app.TakePhotoButton.Layout.Column = 1;
           % app.TakePhotoButton.Text = 'Take Photo';

            % ДОБАВЛЕНО: Создание панели захвата
            % Create GripperPanel
            app.GripperPanel = uipanel(app.GridLayout);
            app.GripperPanel.Title = 'Gripper Control';
            app.GripperPanel.Layout.Row = 1;
            app.GripperPanel.Layout.Column = 2;

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.GripperPanel);
            app.GridLayout5.ColumnWidth = {'1x'};
            app.GridLayout5.RowHeight = {'1x', 22};

            % Create GripperLabel
            app.GripperLabel = uilabel(app.GridLayout5);
            app.GripperLabel.HorizontalAlignment = 'center';
            app.GripperLabel.Layout.Row = 2;
            app.GripperLabel.Layout.Column = 1;
            app.GripperLabel.Text = 'Gripper Open/Close';

            % Create GripperSlider
            app.GripperSlider = uislider(app.GridLayout5);
            app.GripperSlider.Limits = [0 1];
            app.GripperSlider.MajorTicks = [0 0.25 0.5 0.75 1];
            app.GripperSlider.MajorTickLabels = {'Closed', '', 'Half', '', 'Open'};
            app.GripperSlider.ValueChangingFcn = createCallbackFcn(app, @GripperSliderValueChanging, true);
            app.GripperSlider.Layout.Row = 1;
            app.GripperSlider.Layout.Column = 1;
            app.GripperSlider.Value = 0.5;

            % Create KUKAYouBotGUILabel
            app.KUKAYouBotGUILabel = uilabel(app.GridLayout);
            app.KUKAYouBotGUILabel.HorizontalAlignment = 'center';
            app.KUKAYouBotGUILabel.FontSize = 24;
            app.KUKAYouBotGUILabel.FontWeight = 'bold';
            app.KUKAYouBotGUILabel.Layout.Row = 2;
            app.KUKAYouBotGUILabel.Layout.Column = [1 2];
            app.KUKAYouBotGUILabel.Text = 'KUKA YouBot Проект ИМРС';

            % Create ArmJointsPanel
            app.ArmJointsPanel = uipanel(app.GridLayout);
            app.ArmJointsPanel.Title = 'Arm Joints';
            app.ArmJointsPanel.Layout.Row = 3;
            app.ArmJointsPanel.Layout.Column = 1;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.ArmJointsPanel);
            app.GridLayout2.ColumnWidth = {16, 16, 16, 16, 16};
            app.GridLayout2.RowHeight = {'1x', 22};
            app.GridLayout2.Padding = [50 20 20 20];

            % Create jointOneSlider
            app.jointOneSlider = uislider(app.GridLayout2);
            app.jointOneSlider.Limits = [-169 169];
            app.jointOneSlider.MajorTicks = [];
            app.jointOneSlider.Orientation = 'vertical';
            app.jointOneSlider.ValueChangingFcn = createCallbackFcn(app, @jointOneSliderValueChanging, true);
            app.jointOneSlider.MinorTicks = [];
            app.jointOneSlider.Layout.Row = 1;
            app.jointOneSlider.Layout.Column = 1;

            % Create J1Label
            app.J1Label = uilabel(app.GridLayout2);
            app.J1Label.Layout.Row = 2;
            app.J1Label.Layout.Column = 1;
            app.J1Label.Text = 'J1';

            % Create jointTwoSlider
            app.jointTwoSlider = uislider(app.GridLayout2);
            app.jointTwoSlider.Limits = [-90 75];
            app.jointTwoSlider.MajorTicks = [];
            app.jointTwoSlider.Orientation = 'vertical';
            app.jointTwoSlider.ValueChangingFcn = createCallbackFcn(app, @jointTwoSliderValueChanging, true);
            app.jointTwoSlider.MinorTicks = [];
            app.jointTwoSlider.Layout.Row = 1;
            app.jointTwoSlider.Layout.Column = 2;

            % Create J1Label_2
            app.J1Label_2 = uilabel(app.GridLayout2);
            app.J1Label_2.Layout.Row = 2;
            app.J1Label_2.Layout.Column = 2;
            app.J1Label_2.Text = 'J2';

            % Create jointThreeSlider
            app.jointThreeSlider = uislider(app.GridLayout2);
            app.jointThreeSlider.Limits = [-131 131];
            app.jointThreeSlider.MajorTicks = [];
            app.jointThreeSlider.Orientation = 'vertical';
            app.jointThreeSlider.ValueChangingFcn = createCallbackFcn(app, @jointThreeSliderValueChanging, true);
            app.jointThreeSlider.MinorTicks = [];
            app.jointThreeSlider.Layout.Row = 1;
            app.jointThreeSlider.Layout.Column = 3;

            % Create J1Label_3
            app.J1Label_3 = uilabel(app.GridLayout2);
            app.J1Label_3.Layout.Row = 2;
            app.J1Label_3.Layout.Column = 3;
            app.J1Label_3.Text = 'J3';

            % Create jointFourSlider
            app.jointFourSlider = uislider(app.GridLayout2);
            app.jointFourSlider.Limits = [-102 102];
            app.jointFourSlider.MajorTicks = [];
            app.jointFourSlider.Orientation = 'vertical';
            app.jointFourSlider.ValueChangingFcn = createCallbackFcn(app, @jointFourSliderValueChanging, true);
            app.jointFourSlider.MinorTicks = [];
            app.jointFourSlider.Layout.Row = 1;
            app.jointFourSlider.Layout.Column = 4;

            % Create J1Label_4
            app.J1Label_4 = uilabel(app.GridLayout2);
            app.J1Label_4.Layout.Row = 2;
            app.J1Label_4.Layout.Column = 4;
            app.J1Label_4.Text = 'J4';

            % Create jointFiveSlider
            app.jointFiveSlider = uislider(app.GridLayout2);
            app.jointFiveSlider.Limits = [-90 90];
            app.jointFiveSlider.MajorTicks = [];
            app.jointFiveSlider.Orientation = 'vertical';
            app.jointFiveSlider.ValueChangingFcn = createCallbackFcn(app, @jointFiveSliderValueChanging, true);
            app.jointFiveSlider.MinorTicks = [];
            app.jointFiveSlider.Layout.Row = 1;
            app.jointFiveSlider.Layout.Column = 5;

            % Create J1Label_5
            app.J1Label_5 = uilabel(app.GridLayout2);
            app.J1Label_5.Layout.Row = 2;
            app.J1Label_5.Layout.Column = 5;
            app.J1Label_5.Text = 'J5';

            % Create MovementRotationPanel
            app.MovementRotationPanel = uipanel(app.GridLayout);
            app.MovementRotationPanel.Title = 'Movement & Rotation';
            app.MovementRotationPanel.Layout.Row = 3;
            app.MovementRotationPanel.Layout.Column = 2;

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.MovementRotationPanel);
            app.GridLayout4.RowHeight = {'1x', 20};

            % Create RotationKnobLabel
            app.RotationKnobLabel = uilabel(app.GridLayout4);
            app.RotationKnobLabel.HorizontalAlignment = 'center';
            app.RotationKnobLabel.FontSize = 14;
            app.RotationKnobLabel.Layout.Row = 2;
            app.RotationKnobLabel.Layout.Column = 1;
            app.RotationKnobLabel.Text = 'Rotation';

            % Create RotationKnob
            app.RotationKnob = uiknob(app.GridLayout4, 'continuous');
            app.RotationKnob.Limits = [-180 180];
            app.RotationKnob.MajorTicks = [-180 -140 -100 -60 -20 20 60 100 140 180];
            app.RotationKnob.MajorTickLabels = {'-180', '-140', '-100', '-60', '-20', '20', '60', '100', '140', '180'};
            app.RotationKnob.ValueChangedFcn = createCallbackFcn(app, @RotationKnobValueChanged, true);
            app.RotationKnob.ValueChangingFcn = createCallbackFcn(app, @RotationKnobValueChanging, true);
            app.RotationKnob.MinorTicks = [-180 -172 -164 -156 -148 -140 -132 -124 -116 -108 -100 -92 -84 -76 -68 -60 -52 -44 -36 -28 -20 -12 -4 4 12 20 28 36 44 52 60 68 76 84 92 100 108 116 124 132 140 148 156 164 172 180];
            app.RotationKnob.Layout.Row = 1;
            app.RotationKnob.Layout.Column = 1;
            app.RotationKnob.FontSize = 14;

            % Create SpeedKnobLabel
            app.SpeedKnobLabel = uilabel(app.GridLayout4);
            app.SpeedKnobLabel.HorizontalAlignment = 'center';
            app.SpeedKnobLabel.FontSize = 14;
            app.SpeedKnobLabel.Layout.Row = 2;
            app.SpeedKnobLabel.Layout.Column = 2;
            app.SpeedKnobLabel.Text = 'Speed';

            % Create SpeedKnob
            app.SpeedKnob = uiknob(app.GridLayout4, 'continuous');
            app.SpeedKnob.Limits = [-90 180];
            app.SpeedKnob.MajorTicks = [-90 -60 -30 0 30 60 90 120 150 180];
            app.SpeedKnob.ValueChangedFcn = createCallbackFcn(app, @SpeedKnobValueChanged, true);
            app.SpeedKnob.ValueChangingFcn = createCallbackFcn(app, @SpeedKnobValueChanging, true);
            app.SpeedKnob.Layout.Row = 1;
            app.SpeedKnob.Layout.Column = 2;
            app.SpeedKnob.FontSize = 14;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = gui

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end