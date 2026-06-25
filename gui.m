classdef gui < matlab.apps.AppBase

    properties (Access = public)
        UIFigure               matlab.ui.Figure
        GridLayout             matlab.ui.container.GridLayout
        TitleLabel             matlab.ui.control.Label

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

        GripperPanel           matlab.ui.container.Panel
        GridLayout5            matlab.ui.container.GridLayout
        GripperSlider          matlab.ui.control.Slider
        GripperOpenButton      matlab.ui.control.Button
        GripperCloseButton     matlab.ui.control.Button
        GripperStatusLabel     matlab.ui.control.Label

        MovementRotationPanel  matlab.ui.container.Panel
        GridLayout4            matlab.ui.container.GridLayout
        SpeedKnob              matlab.ui.control.Knob
        SpeedKnobLabel         matlab.ui.control.Label
        RotationKnob           matlab.ui.control.Knob
        RotationKnobLabel      matlab.ui.control.Label

        EStopButton            matlab.ui.control.Button
    end

    properties (Access = public)
        sim
        clientID
        handles
    end

    methods (Access = private)

        function radians = deg2rad_(~, degrees)
            radians = degrees * (pi / 180);
        end

        function setJointTargetPosition(app, index, degrees)
            app.sim.simxSetJointTargetPosition( ...
                app.clientID, app.handles(index), ...
                deg2rad_(app, degrees), ...
                app.sim.simx_opmode_oneshot);
        end

        function setWheelJointVelocity(app, index, deg_s)
            app.sim.simxSetJointTargetVelocity( ...
                app.clientID, app.handles(index), ...
                deg2rad_(app, deg_s), ...
                app.sim.simx_opmode_oneshot);
        end

        function resetWheelVelocities(app)
            for i = 1:4
                setWheelJointVelocity(app, i, 0);
            end
        end

        function sendGripperCommand(app, value)
            value = max(0, min(1, value));
            targetJ2 = -value * 0.050;
            app.sim.simxSetFloatSignal(app.clientID, 'gripperTarget', targetJ2, ...
                app.sim.simx_opmode_oneshot);

            if value < 0.05
                app.GripperStatusLabel.Text = '● Закрыт';
                app.GripperStatusLabel.FontColor = [0.8 0.2 0.2];
            elseif value > 0.95
                app.GripperStatusLabel.Text = '● Открыт';
                app.GripperStatusLabel.FontColor = [0.15 0.6 0.15];
            else
                app.GripperStatusLabel.Text = sprintf('● %.0f%%', value*100);
                app.GripperStatusLabel.FontColor = [0.1 0.4 0.8];
            end
        end

    end

    methods (Access = public)

        function setDefaultValues(app)
            app.jointOneSlider.Value   = 0;
            app.jointTwoSlider.Value   = 0;
            app.jointThreeSlider.Value = 0;
            app.jointFourSlider.Value  = 0;
            app.jointFiveSlider.Value  = 0;
            app.GripperSlider.Value    = 1;
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
            sendGripperCommand(app, event.Value);
        end

        function GripperSliderValueChanged(app, event)
            sendGripperCommand(app, event.Value);
        end

        function GripperOpenButtonPushed(app, ~)
            app.GripperSlider.Value = 1;
            sendGripperCommand(app, 1);
        end

        function GripperCloseButtonPushed(app, ~)
            app.GripperSlider.Value = 0;
            sendGripperCommand(app, 0);
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

            bgColor      = [0.12 0.14 0.18];   
            panelBg      = [0.17 0.20 0.26];   
            accentBlue   = [0.18 0.52 0.90];  
            textWhite    = [0.95 0.95 0.95];
            textGray     = [0.60 0.65 0.72];
            stopRed      = [0.85 0.15 0.15];

            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position    = [100 80 760 540];
            app.UIFigure.Name        = 'ТИКЕТ — Программирование роботов';
            app.UIFigure.Color       = bgColor;
            app.UIFigure.Resize      = 'off';

            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth   = {'1.1x', '0.9x'};
            app.GridLayout.RowHeight     = {44, '1x', '1x'};
            app.GridLayout.Padding       = [12 10 12 10];
            app.GridLayout.RowSpacing    = 8;
            app.GridLayout.ColumnSpacing = 10;
            app.GridLayout.BackgroundColor = bgColor;

            app.TitleLabel = uilabel(app.GridLayout);
            app.TitleLabel.Text = 'ТИКЕТ  |  ПРОГРАММИРОВАНИЕ РОБОТОВ';
            app.TitleLabel.FontSize   = 15;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.FontColor  = accentBlue;
            app.TitleLabel.HorizontalAlignment = 'left';
            app.TitleLabel.Layout.Row    = 1;
            app.TitleLabel.Layout.Column = 1;

            app.EStopButton = uibutton(app.GridLayout, 'push');
            app.EStopButton.Text            = '⏹  СТОП';
            app.EStopButton.FontWeight      = 'bold';
            app.EStopButton.FontSize        = 13;
            app.EStopButton.BackgroundColor = stopRed;
            app.EStopButton.FontColor       = [1 1 1];
            app.EStopButton.ButtonPushedFcn = createCallbackFcn(app, @EStopButtonPushed, true);
            app.EStopButton.Layout.Row    = 1;
            app.EStopButton.Layout.Column = 2;

            app.ArmJointsPanel = uipanel(app.GridLayout);
            app.ArmJointsPanel.Title           = 'Суставы манипулятора';
            app.ArmJointsPanel.FontSize        = 12;
            app.ArmJointsPanel.FontWeight      = 'bold';
            app.ArmJointsPanel.ForegroundColor = textGray;
            app.ArmJointsPanel.BackgroundColor = panelBg;
            app.ArmJointsPanel.Layout.Row    = 2;
            app.ArmJointsPanel.Layout.Column = 1;

            app.GridLayout2 = uigridlayout(app.ArmJointsPanel);
            app.GridLayout2.ColumnWidth   = {'1x','1x','1x','1x','1x'};
            app.GridLayout2.RowHeight     = {'1x', 20};
            app.GridLayout2.Padding       = [22 14 22 8];
            app.GridLayout2.ColumnSpacing = 12;
            app.GridLayout2.BackgroundColor = panelBg;

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
                s.MajorTicks  = [limits(k,1) 0 limits(k,2)];
                s.MinorTicks  = [];
                s.Orientation = 'vertical';
                s.FontColor   = textGray;
                s.ValueChangingFcn = createCallbackFcn(app, sliderCBs{k}, true);
                s.Layout.Row    = 1;
                s.Layout.Column = k;
                app.(sProp{k}) = s;

                lbl = uilabel(app.GridLayout2);
                lbl.Text = sprintf('J%d', k);
                lbl.HorizontalAlignment = 'center';
                lbl.FontWeight = 'bold';
                lbl.FontColor  = accentBlue;
                lbl.FontSize   = 12;
                lbl.Layout.Row    = 2;
                lbl.Layout.Column = k;
                app.(lProp{k}) = lbl;
            end

            app.GripperPanel = uipanel(app.GridLayout);
            app.GripperPanel.Title           = 'Схват (Gripper)';
            app.GripperPanel.FontSize        = 12;
            app.GripperPanel.FontWeight      = 'bold';
            app.GripperPanel.ForegroundColor = textGray;
            app.GripperPanel.BackgroundColor = panelBg;
            app.GripperPanel.Layout.Row    = 2;
            app.GripperPanel.Layout.Column = 2;

            app.GridLayout5 = uigridlayout(app.GripperPanel);
            app.GridLayout5.ColumnWidth = {'1x', '1x'};
            app.GridLayout5.RowHeight   = {'1x', 22, 32};
            app.GridLayout5.Padding     = [16 14 16 10];
            app.GridLayout5.RowSpacing  = 8;
            app.GridLayout5.BackgroundColor = panelBg;

            app.GripperSlider = uislider(app.GridLayout5);
            app.GripperSlider.Limits    = [0 1];
            app.GripperSlider.Value     = 1;
            app.GripperSlider.MajorTicks = [0 0.5 1];
            app.GripperSlider.MajorTickLabels = {'Закрыт', '50%', 'Открыт'};
            app.GripperSlider.MinorTicks = [];
            app.GripperSlider.FontColor  = textGray;
            app.GripperSlider.ValueChangingFcn = createCallbackFcn(app, @GripperSliderValueChanging, true);
            app.GripperSlider.ValueChangedFcn  = createCallbackFcn(app, @GripperSliderValueChanged, true);
            app.GripperSlider.Layout.Row    = 1;
            app.GripperSlider.Layout.Column = [1 2];

            % Метка состояния
            app.GripperStatusLabel = uilabel(app.GridLayout5);
            app.GripperStatusLabel.Text = '● Открыт';
            app.GripperStatusLabel.FontSize   = 12;
            app.GripperStatusLabel.FontWeight = 'bold';
            app.GripperStatusLabel.FontColor  = [0.15 0.6 0.15];
            app.GripperStatusLabel.HorizontalAlignment = 'center';
            app.GripperStatusLabel.Layout.Row    = 2;
            app.GripperStatusLabel.Layout.Column = [1 2];

            app.GripperCloseButton = uibutton(app.GridLayout5, 'push');
            app.GripperCloseButton.Text            = 'Закрыть';
            app.GripperCloseButton.FontWeight      = 'bold';
            app.GripperCloseButton.FontColor       = [1 1 1];
            app.GripperCloseButton.BackgroundColor = [0.50 0.18 0.18];
            app.GripperCloseButton.ButtonPushedFcn = createCallbackFcn(app, @GripperCloseButtonPushed, true);
            app.GripperCloseButton.Layout.Row    = 3;
            app.GripperCloseButton.Layout.Column = 1;

            app.GripperOpenButton = uibutton(app.GridLayout5, 'push');
            app.GripperOpenButton.Text            = 'Открыть';
            app.GripperOpenButton.FontWeight      = 'bold';
            app.GripperOpenButton.FontColor       = [1 1 1];
            app.GripperOpenButton.BackgroundColor = [0.12 0.42 0.22];
            app.GripperOpenButton.ButtonPushedFcn = createCallbackFcn(app, @GripperOpenButtonPushed, true);
            app.GripperOpenButton.Layout.Row    = 3;
            app.GripperOpenButton.Layout.Column = 2;

            app.MovementRotationPanel = uipanel(app.GridLayout);
            app.MovementRotationPanel.Title           = 'Движение базы';
            app.MovementRotationPanel.FontSize        = 12;
            app.MovementRotationPanel.FontWeight      = 'bold';
            app.MovementRotationPanel.ForegroundColor = textGray;
            app.MovementRotationPanel.BackgroundColor = panelBg;
            app.MovementRotationPanel.Layout.Row    = 3;
            app.MovementRotationPanel.Layout.Column = [1 2];

            app.GridLayout4 = uigridlayout(app.MovementRotationPanel);
            app.GridLayout4.ColumnWidth = {'1x','1x'};
            app.GridLayout4.RowHeight   = {'1x', 22};
            app.GridLayout4.Padding     = [30 12 30 10];
            app.GridLayout4.BackgroundColor = panelBg;

            app.RotationKnobLabel = uilabel(app.GridLayout4);
            app.RotationKnobLabel.Text = 'Поворот';
            app.RotationKnobLabel.HorizontalAlignment = 'center';
            app.RotationKnobLabel.FontSize   = 12;
            app.RotationKnobLabel.FontWeight = 'bold';
            app.RotationKnobLabel.FontColor  = textGray;
            app.RotationKnobLabel.Layout.Row    = 2;
            app.RotationKnobLabel.Layout.Column = 1;

            app.RotationKnob = uiknob(app.GridLayout4, 'continuous');
            app.RotationKnob.Limits = [-180 180];
            app.RotationKnob.MajorTicks = [-180 -90 0 90 180];
            app.RotationKnob.MinorTicks = [];
            app.RotationKnob.FontColor  = textGray;
            app.RotationKnob.FontSize   = 11;
            app.RotationKnob.ValueChangedFcn  = createCallbackFcn(app, @RotationKnobValueChanged, true);
            app.RotationKnob.ValueChangingFcn = createCallbackFcn(app, @RotationKnobValueChanging, true);
            app.RotationKnob.Layout.Row    = 1;
            app.RotationKnob.Layout.Column = 1;

            app.SpeedKnobLabel = uilabel(app.GridLayout4);
            app.SpeedKnobLabel.Text = 'Скорость';
            app.SpeedKnobLabel.HorizontalAlignment = 'center';
            app.SpeedKnobLabel.FontSize   = 12;
            app.SpeedKnobLabel.FontWeight = 'bold';
            app.SpeedKnobLabel.FontColor  = textGray;
            app.SpeedKnobLabel.Layout.Row    = 2;
            app.SpeedKnobLabel.Layout.Column = 2;

            app.SpeedKnob = uiknob(app.GridLayout4, 'continuous');
            app.SpeedKnob.Limits = [-90 180];
            app.SpeedKnob.MajorTicks = [-90 0 90 180];
            app.SpeedKnob.MinorTicks = [];
            app.SpeedKnob.FontColor  = textGray;
            app.SpeedKnob.FontSize   = 11;
            app.SpeedKnob.ValueChangedFcn  = createCallbackFcn(app, @SpeedKnobValueChanged, true);
            app.SpeedKnob.ValueChangingFcn = createCallbackFcn(app, @SpeedKnobValueChanging, true);
            app.SpeedKnob.Layout.Row    = 1;
            app.SpeedKnob.Layout.Column = 2;

            app.UIFigure.Visible = 'on';
        end
    end

    methods (Access = public)
        function app = gui
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
