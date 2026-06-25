classdef gui < matlab.apps.AppBase

    properties (Access = public)
        UIFigure               matlab.ui.Figure
        GridLayout             matlab.ui.container.GridLayout
        KUKAYouBotGUILabel     matlab.ui.control.Label

        % Arm Joints panel
        ArmJointsPanel         matlab.ui.container.Panel
        GridLayout2            matlab.ui.container.GridLayout
        J1Label                matlab.ui.control.Label
        J1Label_2              matlab.ui.control.Label
        J1Label_3              matlab.ui.control.Label
        J1Label_4              matlab.ui.control.Label
        J1Label_5              matlab.ui.control.Label
        jointOneSlider         matlab.ui.control.Slider
        jointTwoSlider         matlab.ui.control.Slider
        jointThreeSlider       matlab.ui.control.Slider
        jointFourSlider        matlab.ui.control.Slider
        jointFiveSlider        matlab.ui.control.Slider

        % Gripper panel
        GripperPanel           matlab.ui.container.Panel
        GridLayout5            matlab.ui.container.GridLayout
        GripperSlider          matlab.ui.control.Slider
        GripperOpenButton      matlab.ui.control.Button
        GripperCloseButton     matlab.ui.control.Button

        % Movement & Rotation panel
        MovementRotationPanel  matlab.ui.container.Panel
        GridLayout4            matlab.ui.container.GridLayout
        SpeedKnob              matlab.ui.control.Knob
        SpeedKnobLabel         matlab.ui.control.Label
        RotationKnob           matlab.ui.control.Knob
        RotationKnobLabel      matlab.ui.control.Label

        % Emergency Stop
        EStopButton            matlab.ui.control.Button
    end

    properties (Access = public)
        sim
        clientID
        handles
        gripperOpenPos1   % реальная позиция joint1 в открытом состоянии
        gripperOpenPos2   % реальная позиция joint2 в открытом состоянии
    end

    methods (Access = private)

        function radians = deg2rad_(~, degrees)
            radians = degrees * (pi / 180);
        end

        function setJointTargetPosition(app, index, degrees)
            app.sim.simxSetJointTargetPosition( ...
                app.clientID, ...
                app.handles(index), ...
                deg2rad_(app, degrees), ...
                app.sim.simx_opmode_oneshot);
        end

        function setWheelJointVelocity(app, index, deg_s)
            app.sim.simxSetJointTargetVelocity( ...
                app.clientID, ...
                app.handles(index), ...
                deg2rad_(app, deg_s), ...
                app.sim.simx_opmode_oneshot);
        end

        function resetWheelVelocities(app)
            for i = 1:4
                setWheelJointVelocity(app, i, 0);
            end
        end

        % Gripper: value 0.0 = closed, 1.0 = open
        % Суставы DYNAMIC — только simxSetJointTargetPosition.
        % simxSetJointPosition в dynamic mode игнорируется и вызывает дёрганье.
        % Диапазоны из сцены (p при открытом положении):
        %   joint1: 0 (closed) .. +0.025 (open)
        %   joint2: 0 (closed) .. -0.050 (open)
        % Gripper управляется через модифицированный Lua-скрипт (Rectangle7).
        % Скрипт читает float сигнал 'gripperTarget' = целевая позиция j2.
        %   открыто  = -0.050
        %   закрыто  =  0.000
        % value: 0.0 = closed, 1.0 = open
        function setGripperPosition(app, value)
            value = max(0, min(1, value));
            targetJ2 = -value * 0.050;

            app.sim.simxSetFloatSignal(app.clientID, 'gripperTarget', targetJ2, ...
                app.sim.simx_opmode_oneshot);

            fprintf('[GRIPPER] val=%.2f  targetJ2=%.4f\n', value, targetJ2);
        end
    end

    methods (Access = public)

        function setDefaultValues(app)
            app.jointOneSlider.Value   = 0;
            app.jointTwoSlider.Value   = 0;
            app.jointThreeSlider.Value = 0;
            app.jointFourSlider.Value  = 0;
            app.jointFiveSlider.Value  = 0;
            % Схват стартует открытым — слайдер в 1, команду не шлём
            app.GripperSlider.Value = 1;
            app.sim.simxGetPingTime(app.clientID);
            fprintf('GUI ready.\n');
        end
    end

    methods (Access = private)

        function jointOneSliderValueChanging(app, event)
            setJointTargetPosition(app, 5, event.Value);
        end
        function jointTwoSliderValueChanging(app, event)
            setJointTargetPosition(app, 6, event.Value);
        end
        function jointThreeSliderValueChanging(app, event)
            setJointTargetPosition(app, 7, event.Value);
        end
        function jointFourSliderValueChanging(app, event)
            setJointTargetPosition(app, 8, event.Value);
        end
        function jointFiveSliderValueChanging(app, event)
            setJointTargetPosition(app, 9, event.Value);
        end

        function GripperSliderValueChanging(app, event)
            setGripperPosition(app, event.Value);
        end

        function GripperOpenButtonPushed(app, ~)
            app.GripperSlider.Value = 1;
            setGripperPosition(app, 1);
        end

        function GripperCloseButtonPushed(app, ~)
            app.GripperSlider.Value = 0;
            setGripperPosition(app, 0);
        end

        function EStopButtonPushed(app, ~)
            resetWheelVelocities(app);
            app.SpeedKnob.Value    = 0;
            app.RotationKnob.Value = 0;
        end

        function RotationKnobValueChanging(app, event)
            v = event.Value;
            if abs(v) < 10
                resetWheelVelocities(app);
                return;
            end
            s = sign(v) * abs(v);
            setWheelJointVelocity(app,1,-s); setWheelJointVelocity(app,2, s);
            setWheelJointVelocity(app,3,-s); setWheelJointVelocity(app,4, s);
        end
        function RotationKnobValueChanged(app, ~)
            app.RotationKnob.Value = 0;
            resetWheelVelocities(app);
        end

        function SpeedKnobValueChanging(app, event)
            v = event.Value;
            for i = 1:4; setWheelJointVelocity(app, i, v); end
        end
        function SpeedKnobValueChanged(app, ~)
            app.SpeedKnob.Value = 0;
            resetWheelVelocities(app);
        end
    end

    methods (Access = private)

        function createComponents(app)

            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 680 480];
            app.UIFigure.Name = 'KUKA YouBot';

            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth   = {'1x', '1x'};
            app.GridLayout.RowHeight     = {32, '1x', '1x'};
            app.GridLayout.Padding       = [8 8 8 8];
            app.GridLayout.RowSpacing    = 6;
            app.GridLayout.ColumnSpacing = 8;

            % Title
            app.KUKAYouBotGUILabel = uilabel(app.GridLayout);
            app.KUKAYouBotGUILabel.Text = 'KUKA YouBot — Проект ИМРС';
            app.KUKAYouBotGUILabel.FontSize   = 16;
            app.KUKAYouBotGUILabel.FontWeight = 'bold';
            app.KUKAYouBotGUILabel.HorizontalAlignment = 'left';
            app.KUKAYouBotGUILabel.Layout.Row    = 1;
            app.KUKAYouBotGUILabel.Layout.Column = 1;

            % E-Stop
            app.EStopButton = uibutton(app.GridLayout, 'push');
            app.EStopButton.Text = '⏹  STOP';
            app.EStopButton.FontWeight = 'bold';
            app.EStopButton.FontSize   = 13;
            app.EStopButton.BackgroundColor = [0.85 0.15 0.15];
            app.EStopButton.FontColor       = [1 1 1];
            app.EStopButton.ButtonPushedFcn = createCallbackFcn(app, @EStopButtonPushed, true);
            app.EStopButton.Layout.Row    = 1;
            app.EStopButton.Layout.Column = 2;

            % Arm Joints panel
            app.ArmJointsPanel = uipanel(app.GridLayout);
            app.ArmJointsPanel.Title = 'Arm Joints';
            app.ArmJointsPanel.Layout.Row    = 2;
            app.ArmJointsPanel.Layout.Column = 1;

            app.GridLayout2 = uigridlayout(app.ArmJointsPanel);
            app.GridLayout2.ColumnWidth   = {'1x','1x','1x','1x','1x'};
            app.GridLayout2.RowHeight     = {'1x', 18};
            app.GridLayout2.Padding       = [20 12 20 8];
            app.GridLayout2.ColumnSpacing = 10;

            limits    = [-169 169; -90 75; -131 131; -102 102; -90 90];
            sliderCBs = {@jointOneSliderValueChanging, @jointTwoSliderValueChanging, ...
                         @jointThreeSliderValueChanging, @jointFourSliderValueChanging, ...
                         @jointFiveSliderValueChanging};
            sProp = {'jointOneSlider','jointTwoSlider','jointThreeSlider', ...
                     'jointFourSlider','jointFiveSlider'};
            lProp = {'J1Label','J1Label_2','J1Label_3','J1Label_4','J1Label_5'};

            for k = 1:5
                s = uislider(app.GridLayout2);
                s.Limits      = limits(k,:);
                s.Value       = 0;
                s.MajorTicks  = [];
                s.MinorTicks  = [];
                s.Orientation = 'vertical';
                s.ValueChangingFcn = createCallbackFcn(app, sliderCBs{k}, true);
                s.Layout.Row    = 1;
                s.Layout.Column = k;
                app.(sProp{k}) = s;

                lbl = uilabel(app.GridLayout2);
                lbl.Text = sprintf('J%d', k);
                lbl.HorizontalAlignment = 'center';
                lbl.Layout.Row    = 2;
                lbl.Layout.Column = k;
                app.(lProp{k}) = lbl;
            end

            % Gripper panel
            app.GripperPanel = uipanel(app.GridLayout);
            app.GripperPanel.Title = 'Gripper';
            app.GripperPanel.Layout.Row    = 2;
            app.GripperPanel.Layout.Column = 2;

            app.GridLayout5 = uigridlayout(app.GripperPanel);
            app.GridLayout5.ColumnWidth = {'1x', '1x'};
            app.GridLayout5.RowHeight   = {'1x', 30};
            app.GridLayout5.Padding     = [14 12 14 10];
            app.GridLayout5.RowSpacing  = 8;

            app.GripperSlider = uislider(app.GridLayout5);
            app.GripperSlider.Limits    = [0 1];
            app.GripperSlider.Value     = 0;
            app.GripperSlider.MajorTicks = [0 0.5 1];
            app.GripperSlider.MajorTickLabels = {'Closed','Half','Open'};
            app.GripperSlider.MinorTicks = [];
            app.GripperSlider.ValueChangingFcn = createCallbackFcn(app, @GripperSliderValueChanging, true);
            app.GripperSlider.Layout.Row    = 1;
            app.GripperSlider.Layout.Column = [1 2];

            app.GripperCloseButton = uibutton(app.GridLayout5, 'push');
            app.GripperCloseButton.Text = 'Close';
            app.GripperCloseButton.ButtonPushedFcn = createCallbackFcn(app, @GripperCloseButtonPushed, true);
            app.GripperCloseButton.Layout.Row    = 2;
            app.GripperCloseButton.Layout.Column = 1;

            app.GripperOpenButton = uibutton(app.GridLayout5, 'push');
            app.GripperOpenButton.Text = 'Open';
            app.GripperOpenButton.ButtonPushedFcn = createCallbackFcn(app, @GripperOpenButtonPushed, true);
            app.GripperOpenButton.Layout.Row    = 2;
            app.GripperOpenButton.Layout.Column = 2;

            % Movement & Rotation panel
            app.MovementRotationPanel = uipanel(app.GridLayout);
            app.MovementRotationPanel.Title = 'Movement & Rotation';
            app.MovementRotationPanel.Layout.Row    = 3;
            app.MovementRotationPanel.Layout.Column = [1 2];

            app.GridLayout4 = uigridlayout(app.MovementRotationPanel);
            app.GridLayout4.ColumnWidth = {'1x','1x'};
            app.GridLayout4.RowHeight   = {'1x', 20};
            app.GridLayout4.Padding     = [20 10 20 10];

            app.RotationKnobLabel = uilabel(app.GridLayout4);
            app.RotationKnobLabel.Text = 'Rotation';
            app.RotationKnobLabel.HorizontalAlignment = 'center';
            app.RotationKnobLabel.FontSize = 13;
            app.RotationKnobLabel.Layout.Row    = 2;
            app.RotationKnobLabel.Layout.Column = 1;

            app.RotationKnob = uiknob(app.GridLayout4, 'continuous');
            app.RotationKnob.Limits = [-180 180];
            app.RotationKnob.MajorTicks = [-180 -90 0 90 180];
            app.RotationKnob.MinorTicks = [];
            app.RotationKnob.ValueChangedFcn  = createCallbackFcn(app, @RotationKnobValueChanged, true);
            app.RotationKnob.ValueChangingFcn = createCallbackFcn(app, @RotationKnobValueChanging, true);
            app.RotationKnob.Layout.Row    = 1;
            app.RotationKnob.Layout.Column = 1;
            app.RotationKnob.FontSize = 13;

            app.SpeedKnobLabel = uilabel(app.GridLayout4);
            app.SpeedKnobLabel.Text = 'Speed';
            app.SpeedKnobLabel.HorizontalAlignment = 'center';
            app.SpeedKnobLabel.FontSize = 13;
            app.SpeedKnobLabel.Layout.Row    = 2;
            app.SpeedKnobLabel.Layout.Column = 2;

            app.SpeedKnob = uiknob(app.GridLayout4, 'continuous');
            app.SpeedKnob.Limits = [-90 180];
            app.SpeedKnob.MajorTicks = [-90 0 90 180];
            app.SpeedKnob.MinorTicks = [];
            app.SpeedKnob.ValueChangedFcn  = createCallbackFcn(app, @SpeedKnobValueChanged, true);
            app.SpeedKnob.ValueChangingFcn = createCallbackFcn(app, @SpeedKnobValueChanging, true);
            app.SpeedKnob.Layout.Row    = 1;
            app.SpeedKnob.Layout.Column = 2;
            app.SpeedKnob.FontSize = 13;

            app.UIFigure.Visible = 'on';
        end
    end

    methods (Access = public)
        function app = gui
            % Дефолтные значения до calibration
            app.gripperOpenPos1 = 0.025;
            app.gripperOpenPos2 = -0.025;
            createComponents(app)
            registerApp(app, app.UIFigure)
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure)
        end
    end
end
